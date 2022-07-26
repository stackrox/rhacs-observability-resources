#!/usr/bin/env bash

set -eu

if ! [ -x "$(command -v dashboard-lint)" ]; then
	go install github.com/grafana/dashboard-linter@latest
fi

! [ -x "$(command -v yq)" ] && echo 'yq not installed, the hook requires it.' && exit 1

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" &>/dev/null && pwd 2>/dev/null)"

TMPDIR="${TMPDIR:-/tmp}"
cp "${SCRIPT_DIR}"/.lint "${TMPDIR}"/.lint
for var in "$@"; do
	yq eval '.spec.json' "$var" >"${TMPDIR}"/dashboard.json
	dashboard-linter lint "${TMPDIR}"/dashboard.json --strict --verbose
done
