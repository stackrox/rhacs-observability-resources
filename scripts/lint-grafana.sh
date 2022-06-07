#!/bin/bash

set -eu

if ! [ -x "$(command -v dashboard-lint)" ]; then
  go install github.com/grafana/dashboard-linter@latest
fi

! [ -x "$(command -v yq)" ] && echo 'yq not installed, the hook requires it.' && exit 1;

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";

yq eval '.spec.json' "${SCRIPT_DIR}"/../resources/grafana/rhacs-central-overview-dashboard.yaml > "${SCRIPT_DIR}"/dashboard.json

dashboard-linter lint "${SCRIPT_DIR}"/dashboard.json --strict --verbose

rm "${SCRIPT_DIR}"/dashboard.json
