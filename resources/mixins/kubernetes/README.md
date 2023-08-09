# Update Kubernetes mixin

## Prerequisites

The Kubernetes mixin requires jsonnet to render its output resources:

- `jb`
- `jsonnet`

## Update

Execute `make update` to update the mixin and re-generate all resources.

## OpenShift platform metrics federation

OpenShift already provides Kubernetes mixin rules by default. To avoid duplication of metrics via recording rules,
no recording rules are generated.
