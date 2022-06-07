#!/bin/bash

if ! [ -x "$(command -v kube-linter)" ]; then
  go install golang.stackrox.io/kube-linter/cmd/kube-linter@latest
fi

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";

kube-linter lint "${SCRIPT_DIR}"/../resources/