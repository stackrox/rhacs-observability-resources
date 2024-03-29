#!/usr/bin/env bash

set -eu

! [ -x "$(command -v yq)" ] && echo 'yq not installed, the hook requires it.' && exit 1

! [ -x "$(command -v promtool)" ] && echo 'promtool not installed, the hook requires it.' && exit 1

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" &>/dev/null && pwd 2>/dev/null)"

yq eval '.spec' "${SCRIPT_DIR}"/../resources/prometheus/prometheus-rules.yaml >/tmp/prometheus-rules-test.yaml
yq eval '.spec' "${SCRIPT_DIR}"/../resources/prometheus/rhacs-recording-rules.yaml >/tmp/recording-rules-test.yaml
for f in "${SCRIPT_DIR}"/../resources/prometheus/unit_tests/*; do
	echo "$f"
	promtool test rules "${f}"
done
