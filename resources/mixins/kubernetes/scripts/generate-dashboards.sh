#!/usr/bin/env bash

set -eu

! [ -x "$(command -v yq)" ] && echo 'yq not installed, the hook requires it.' && exit 1

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" &>/dev/null && pwd 2>/dev/null)"

for file in "${SCRIPT_DIR}"/../templates/dashboards/*; do
	name=$(basename "$file" .yaml)
	yq ".spec.json = ($(cat generated/dashboards/"$name".json) | to_json)" templates/dashboards/"$name".yaml > ../../grafana/mixins/kubernetes/"$name".yaml
done
