#!/usr/bin/env bash

set -eu

! [ -x "$(command -v yq)" ] && echo 'yq not installed, the hook requires it.' && exit 1

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" &>/dev/null && pwd 2>/dev/null)"

for file in "${SCRIPT_DIR}"/*.json; do
    name=$(basename "$file" .json)
    if [ "$name" == "rhacs-central" ]
    then
      # in-cluster
      cat templates/dashboards/"$name"-dashboard.yaml > generated/dashboards/"$name"-dashboard.yaml
      sed "s/^/    /" "$name".json >> generated/dashboards/"$name"-dashboard.yaml

      # cluster-wide
      cat templates/dashboards/"$name"-configmap.yaml > generated/dashboards/"$name"-configmap.yaml
      sed "s/^/    /" "$name".json >> generated/dashboards/"$name"-configmap.yaml
    fi
done
