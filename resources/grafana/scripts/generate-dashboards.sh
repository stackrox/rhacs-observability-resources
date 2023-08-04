#!/usr/bin/env bash

set -eu

! [ -x "$(command -v yq)" ] && echo 'yq not installed, the hook requires it.' && exit 1

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" &>/dev/null && pwd 2>/dev/null)"

for file in "${SCRIPT_DIR}"/../generated/dashboards/*; do
    name=$(basename "$file" .json)
    if [ "$name" == "rhacs-central" ]
    then
      # in-cluster
      cat templates/dashboards/"$name"-dashboard.yaml > "$name"-dashboard.yaml
      sed "s/^/    /" generated/dashboards/"$name".json >> "$name"-dashboard.yaml

      # cluster-wide
      cat templates/dashboards/"$name"-configmap.yaml > "$name"-configmap.yaml
      sed "s/^/    /" generated/dashboards/"$name".json >> "$name"-configmap.yaml
    fi
done
