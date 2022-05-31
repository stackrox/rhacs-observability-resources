#!/usr/bin/env bash

set -eu

function wait_for_default_crd() {
    # Since we have to poll and errors are expected, we have to allow errors on this specific command.
    set +e

    local crd_success=0
    for i in {1..240}; do
        status=$(oc get -n rhacs-observability observabilities.observability.redhat.com observability-stack --ignore-not-found=true -o jsonpath="{.status.stage}{.status.stageStatus}")
        [[ ${status} == "configurationsuccess" ]] && crd_success=1 && break
        sleep 5
    done

    [[ ${crd_success} == 0 ]] && echo 'CRD observability-stack did not reach stage configuration with status success' && exit 1

    set -e

    return 0
}

function validate() {
    # Ensure required commands are available on system.
    command -v envsubst || { echo 'Missing required command "envsubst"' && exit 1; }
    command -v oc || { echo 'Missing required command "oc"' && exit 1; }

    # We need export for "envsubst".
    export GITHUB_REPO=${GITHUB_REPO:-""}
    export GITHUB_TAG=${GITHUB_TAG:-""}
    export GITHUB_TOKEN=${GITHUB_TOKEN:-""}

    [[ ${GITHUB_REPO} == "" ]] && echo 'Please set "GITHUB_REPO" environment variable' && exit 1
    [[ ${GITHUB_TAG} == "" ]] && echo 'Please set "GITHUB_TAG" environment variable' && exit 1
    [[ ${GITHUB_TOKEN} == "" ]] && echo 'Please set "GITHUB_TOKEN" environment variable' && exit 1

    # We need export for "envsubst".
    export OBSERVATORIUM_GATEWAY=${OBSERVATORIUM_GATEWAY:-""}
    export OBSERVATORIUM_RHSSO_METRICS_CLIENT_ID=${OBSERVATORIUM_RHSSO_METRICS_CLIENT_ID:-""}
    export OBSERVATORIUM_RHSSO_METRICS_SECRET=${OBSERVATORIUM_RHSSO_METRICS_SECRET:-""}

    [[ ${OBSERVATORIUM_GATEWAY} == "" ]] && echo 'Please set "OBSERVATORIUM_GATEWAY" environment variable' && exit 1
    [[ ${OBSERVATORIUM_RHSSO_METRICS_CLIENT_ID} == "" ]] && echo 'Please set "OBSERVATORIUM_RHSSO_METRICS_CLIENT_ID" environment variable' && exit 1
    [[ ${OBSERVATORIUM_RHSSO_METRICS_SECRET} == "" ]] && echo 'Please set "OBSERVATORIUM_RHSSO_METRICS_SECRET" environment variable' && exit 1

    return 0
}

function install_rhacs_observability() {
    local -r root_dir=$(cd "$(dirname "$0")" && cd .. && pwd) || true

    # We need to export namespace for "envsubst".
    export RHACS_NAMESPACE=${RHACS_NAMESPACE:-stackrox}

    # Setup RHACS.
    oc --namespace "${RHACS_NAMESPACE}" patch deployment central --patch='{"spec":{"template":{"spec":{"containers":[{"name":"central","ports":[{"containerPort":9090,"name":"monitoring"}]}]}}}}'
    local -r network_policy=$(envsubst < "${root_dir}/resources/template/00-central-01-network-policy.yaml") || true
    echo "${network_policy}" | oc apply --filename -

    # Add namespace and catalog for observability operator.
    oc apply --filename "${root_dir}/resources/template/01-operator-01-namespace.yaml"
    oc apply --filename "${root_dir}/resources/template/01-operator-02-catalog-source.yaml"

    # Deploy secret to read GitHub repo and deploy Prometheus and Grafana resources.
    local -r secret_yaml=$(envsubst < "${root_dir}/resources/template/01-operator-03-secret-github.yaml") || true
    echo "${secret_yaml}" | oc apply --filename -

    # Deploy secret to access Observatorium.
    export OBSERVATORIUM_TENANT="rhacs"
    export OBSERVATORIUM_AUTH_TYPE="redhat"
    export OBSERVATORIUM_RHSSO_URL="https://sso.redhat.com/auth/"
    export OBSERVATORIUM_RHSSO_REALM="redhat-external"

    local -r observatorium_secret=$(envsubst < "${root_dir}/resources/template/01-operator-03-secret-observatorium.yaml") || true
    echo "${observatorium_secret}" | oc apply --filename -

    # Install observability operator.
    oc apply --filename "${root_dir}/resources/template/01-operator-04-operator-group.yaml"
    oc apply --filename "${root_dir}/resources/template/01-operator-05-subscription.yaml"

    # Wait until the default CRD is available and the CRD has reached stage "configuration" with status "success". If we were to delete
    # it beforehand, the operator would not be able to recover.
    wait_for_default_crd

    # Delete the default CRD. We do not need to specifically wait here since the finalizer of the CRD will handle the cleanup and only return
    # once it is completed.
    oc delete observabilities.observability.redhat.com observability-stack

    # Install our CRD, which contains different default names and label selectors.
    oc apply --filename "${root_dir}/resources/template/01-operator-06-custom-resource.yaml"

    return 0
}

validate
install_rhacs_observability
