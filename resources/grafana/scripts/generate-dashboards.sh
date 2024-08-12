#!/usr/bin/env bash

set -eu

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" &>/dev/null && pwd 2>/dev/null)"

mkdir -p "${SCRIPT_DIR}"/../generated/dashboards
for file in "${SCRIPT_DIR}"/../sources/*.json; do
    name=$(basename "$file" .json)
    echo "generating dashboard for source $name"
    cat templates/dashboards/"$name".yaml > generated/dashboards/"$name".yaml
    sed "s/^/    /" "$file" >> generated/dashboards/"$name".yaml
done
