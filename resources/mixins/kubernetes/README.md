# Update Kubernetes mixin

## Prerequisites

The Kubernetes mixin requires jsonnet to render its output resources:

- `jb`
- `jsonnet`

## Installation & update

From `resources/mixins/kubernetes` execute:

```sh
jb init
jb install github.com/kubernetes-monitoring/kubernetes-mixin
mkdir -p files/dashboards
```

for the initial install and

```sh
jb update
```

to update the mixin. The resources are rendered via

```sh
jsonnet -J vendor -S -e 'std.manifestYamlDoc((import "mixin.libsonnet").prometheusAlerts)' > alerts.yml
jsonnet -J vendor -S -e 'std.manifestYamlDoc((import "mixin.libsonnet").prometheusRules)' > rules.yml
jsonnet -J vendor -m files/dashboards -e '(import "mixin.libsonnet").grafanaDashboards'
```

Copy the resulting alerts, rules, and dashboards to `resources/prometheus/kubernetes-mixin-alerts.yaml`, `resources/prometheus/kubernetes-mixin-rules.yaml`, and `resources/grafana/mixins/kubernetes/`, respectively.

Contributions to automate this process are welcome!
