#!/usr/bin/env bash

set -eu

! [ -x "$(command -v yq)" ] && echo 'yq not installed, the hook requires it.' && exit 1

for file in *.json; do
    name=$(basename "$file" .json)
    # in-cluster
    cat templates/dashboards/"$name"-dashboard.yaml > generated/dashboards/"$name"-dashboard.yaml
    sed "s/^/    /" "$name".json >> generated/dashboards/"$name"-dashboard.yaml

    # cluster-wide
    cat templates/dashboards/"$name"-configmap.yaml > generated/dashboards/"$name"-configmap.yaml
    sed "s/^/    /" "$name".json >> generated/dashboards/"$name"-configmap.yaml
done
