#!/usr/bin/env bash

set -eu

if ! [ -x "$(command -v jb)" ]; then
	go install -a github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@latest
fi

if ! [ -x "$(command -v jsonnet)" ]; then
	go install github.com/google/go-jsonnet/cmd/jsonnet@latest
fi

if ! [ -x "$(command -v yq)" ]; then
	go install github.com/mikefarah/yq/v4@latest
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" &>/dev/null && pwd 2>/dev/null)"

make -C "$SCRIPT_DIR"/.. generate
