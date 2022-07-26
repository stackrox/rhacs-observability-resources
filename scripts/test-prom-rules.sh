#!/bin/bash

set -eu

! [ -x "$(command -v yq)" ] && echo 'yq not installed, the hook requires it.' && exit 1

! [ -x "$(command -v promtool)" ] && echo 'promtool not installed, the hook requires it.' && exit 1

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" &>/dev/null && pwd 2>/dev/null)"

if [[ ! -f "${SCRIPT_DIR}"/../resources/prometheus/__prometheus-rules-test.yaml ]]; then
	yq eval '.spec' "${SCRIPT_DIR}"/../resources/prometheus/prometheus-rules.yaml >"${SCRIPT_DIR}"/../resources/prometheus/__prometheus-rules-test.yaml
fi
for var in "$@"; do
	echo "$var"
	promtool test rules "${var}"
done

# rm -f "${SCRIPT_DIR}"/../resources/prometheus/__prometheus-rules-test.yaml || true
