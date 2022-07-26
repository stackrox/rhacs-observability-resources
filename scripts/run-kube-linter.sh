#!/usr/bin/env bash

set -eu

if ! [ -x "$(command -v kube-linter)" ]; then
	go install golang.stackrox.io/kube-linter/cmd/kube-linter@latest
fi

for var in "$@"; do
	kube-linter lint "${var}"
done
