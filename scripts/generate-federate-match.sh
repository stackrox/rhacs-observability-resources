#!/usr/bin/env bash

set -eou pipefail

# only if not OSX
if [[ $(uname) != "Darwin" ]]; then
    shopt -s inherit_errexit
fi

function log() {
    echo "$@" >&2
}

function log_exit() {
    log "$@"

    exit 1
}

function log_requirements_and_exit() {
    log_exit "ERROR: One of the required commands is not available. Please ensure that the following commands are installed: jq, yq, mimirtool, realpath, sort, and uniq"
}

! [ -x "$(command -v jq)" ] && log_requirements_and_exit
! [ -x "$(command -v mimirtool)" ] && log_requirements_and_exit
! [ -x "$(command -v realpath)" ] && log_requirements_and_exit
! [ -x "$(command -v sort)" ] && log_requirements_and_exit
! [ -x "$(command -v uniq)" ] && log_requirements_and_exit
! [ -x "$(command -v yq)" ] && log_requirements_and_exit

function get_rules_metrics() {
    local os_prom_rule_file="${1:-}"
    [[ "${os_prom_rule_file}" = "" ]] && log_exit "Variable 'os_prom_rule_file' is empty."

    local metrics_list_file="${2:-}"
    [[ "${metrics_list_file}" = "" ]] && log_exit "Variable 'metrics_list_file' is empty."

    local rules_file
    rules_file=$(mktemp)

    local json_file
    json_file=$(mktemp)

    log "exporting federated metrics for Prometheus rules file: '${os_prom_rule_file}'"

    yq '.spec' "${os_prom_rule_file}" > "${rules_file}"
    mimirtool analyze rule-file "${rules_file}" --output="${json_file}"
    jq '.ruleGroups[].metrics | select( . != null ) | .[]' "${json_file}" --raw-output >> "${metrics_list_file}"

    rm -f "${rules_file}"
    rm -f "${json_file}"
}

function main() {
    local script_dir
    script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" &>/dev/null && pwd 2>/dev/null)"

    local repo_dir
    repo_dir=$(realpath "${script_dir}/../")

    local working_tmp_dir
    working_tmp_dir=$(mktemp -d)
    log "Created temp dir for storing temp file: '${working_tmp_dir}'"

    local metrics_list_file="${working_tmp_dir}/metrics_list"

    # Get metrics used in Dashboards
    log "exporting federated metrics for Prometheus dashboards in 'grafana/sources'"
    mimirtool analyze dashboard "${repo_dir}"/resources/grafana/sources/* --output="${working_tmp_dir}/acs.json"
    jq '.dashboards[].metrics[]' "${working_tmp_dir}/acs.json" --raw-output >> "${metrics_list_file}"

    log "exporting federated metrics for Prometheus dashboards in 'mixins/kubernetes/generated/dashboards'"
    mimirtool analyze dashboard "${repo_dir}"/resources/mixins/kubernetes/generated/dashboards/* --output="${working_tmp_dir}/mixins.json"
    jq '.dashboards[].metrics[]' "${working_tmp_dir}/mixins.json" --raw-output >> "${metrics_list_file}"

    # Get metrics used in recording rules and alerts
    local rules_files
    rules_files=$(jq '.config.prometheus.rules[]' "${repo_dir}/resources/index.json" --raw-output)
    while IFS= read -r rules_file; do
        get_rules_metrics "${repo_dir}/resources/${rules_file}" "${metrics_list_file}"
    done <<< "${rules_files}"

    # Filter metrics (exclude metrics that are collected by observability Prometheus or created by recording rules)
    sort "${metrics_list_file}" | uniq | grep -v -E "^acs|^rox|^aws|^central:|acscs_worker_nodes" | awk '{ print $1 "{job!~\"central|scanner\"}" }' > "${metrics_list_file}.filter"

    # Create federation-config.yaml
    local yq_expression='. *+ load("'"${repo_dir}/resources/prometheus/federation-config-base.yaml"'")."match[]" | unique | sort | { "match[]": . }'
    sed -e 's/^/- /'  "${metrics_list_file}.filter" | yq "${yq_expression}" > "${repo_dir}/resources/prometheus/federation-config.yaml"

    # Clean up the temp directory with all transient files
    rm -rf "${working_tmp_dir}"
    log "Deleted temp dir: '${working_tmp_dir}'"
}

main "$@"
