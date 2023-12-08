#!/usr/bin/env bash

# TODO:
# - add entry in Makefile
# - get metrics needed for combined dashboards
# - create CI step that will fail if federated yaml in repo is different from generated one
#   (to cover case where someone forgets to re-generate it locally)

set -eou pipefail
shopt -s inherit_errexit

function log() {
    echo "${1:-}" >&2
}

function log_exit() {
    log "${1:-}"

    exit 1
}


function check_command() {
    local cmd="${1:-}"

    echo "- Looking for '${cmd}'"
    command -v "${cmd}" || log_exit "-- Command '${cmd}' required."
    echo "- Found '${cmd}'!"
}

function check_dependencies() {
    echo "--- Checking command dependencies"

    check_command mimirtool
    check_command realpath
    check_command jq
    check_command yq
    check_command sort
    check_command uniq

    echo "--- Done!"
}

function get_rules_metrics() {
    local os_prom_rule_file="${1:-}"
    [[ "${os_prom_rule_file}" = "" ]] && log_exit "Variable 'os_prom_rule_file' is empty."

    local metrics_list_file="${2:-}"
    [[ "${metrics_list_file}" = "" ]] && log_exit "Variable 'metrics_list_file' is empty."

    local rules_file
    rules_file=$(mktemp)

    local json_file
    json_file=$(mktemp)

    yq '.spec' "${os_prom_rule_file}" > "${rules_file}"
    mimirtool analyze rule-file "${rules_file}" --output="${json_file}"
    jq '.ruleGroups[].metrics | select( . != null ) | .[]' "${json_file}" --raw-output >> "${metrics_list_file}"

    rm -rf "${rules_file}"
    rm -rf "${json_file}"
}

function main() {
    check_dependencies

    local script_dir
    script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" &>/dev/null && pwd 2>/dev/null)"

    local repo_dir
    repo_dir=$(realpath "${script_dir}/../")

    local working_tmp_dir
    working_tmp_dir=$(mktemp -d)
    log "Created temp dir for storing temp file: '${working_tmp_dir}'"

    local metrics_list_file="${working_tmp_dir}/metrics_list"

    # Get metrics used in Dashboards
    mimirtool analyze dashboard "${repo_dir}"/resources/grafana/sources/* --output="${working_tmp_dir}/acs.json"
    jq '.dashboards[].metrics[]' "${working_tmp_dir}/acs.json" --raw-output >> "${metrics_list_file}"

    mimirtool analyze dashboard "${repo_dir}"/resources/mixins/kubernetes/generated/dashboards/* --output="${working_tmp_dir}/mixins.json"
    jq '.dashboards[].metrics[]' "${working_tmp_dir}/mixins.json" --raw-output >> "${metrics_list_file}"

    # Get metrics used in recording rules and alerts
    get_rules_metrics "${repo_dir}/resources/prometheus/billing-rules.yaml" "${metrics_list_file}"
    get_rules_metrics "${repo_dir}/resources/prometheus/kubernetes-mixin-alerts.yaml" "${metrics_list_file}"
    get_rules_metrics "${repo_dir}/resources/prometheus/prometheus-rules.yaml" "${metrics_list_file}"
    get_rules_metrics "${repo_dir}/resources/prometheus/rhacs-recording-rules.yaml" "${metrics_list_file}"

    # Filter metrics (exclude metrics that are collected by observability Prometheus or created by recording rules)
    sort "${metrics_list_file}" | uniq | grep -v -E "^acs|^rox|^aws|^central:|acscs_worker_nodes" > "${metrics_list_file}.filter"

    # Create federation-config.yaml
    sed -e 's/^/- /'  "${metrics_list_file}.filter" | yq '{ "match[]": . }' > "${repo_dir}/resources/prometheus/federation-config.yaml"

    # Clean up the temp directory with all transient files
    rm -rf "${working_tmp_dir}"
}

main "$@"
