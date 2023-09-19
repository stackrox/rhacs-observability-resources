#!/usr/bin/env bash

set -eu

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" &>/dev/null && pwd 2>/dev/null)"

for file in "${SCRIPT_DIR}"/../sources/*.json; do
    name=$(basename "$file" .json)
    echo "generating dashboard for source $name"
    # in-cluster
    cat templates/dashboards/"$name"-dashboard.yaml > generated/dashboards/"$name"-dashboard.yaml
    sed "s/^/    /" "$file" >> generated/dashboards/"$name"-dashboard.yaml

    # cluster-wide
    cat templates/dashboards/"$name"-configmap.yaml > generated/dashboards/"$name"-configmap.yaml
    sed "s/^/    /" "$file" >> generated/dashboards/"$name"-configmap.yaml
done
