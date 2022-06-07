#!/bin/bash

set -eu

if ! [ -x "$(command -v dashboard-lint)" ]; then
  go install github.com/grafana/dashboard-linter@latest
fi

! [ -x "$(command -v yq)" ] && echo 'yq not installed, the hook requires it.' && exit 1;

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";

TEMP_DIR="$(mktemp -d)"

yq eval '.spec.json' "${SCRIPT_DIR}"/../resources/grafana/rhacs-central-overview-dashboard.yaml > "${TEMP_DIR}"/dashboard.json

cp "${SCRIPT_DIR}"/.lint "${TEMP_DIR}"/.lint

dashboard-linter lint "${TEMP_DIR}"/dashboard.json --strict --verbose

rm -rf "${TEMP_DIR}"
