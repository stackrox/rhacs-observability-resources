# Managed Red Hat Advanced Cluster Security Service Observability Config

## What is it?

This repository contains resources & other information required by the [Observability Operator](https://github.com/redhat-developer/observability-operator)
to configure the Observability stack for Managed Red Hat Advanced Cluster Security.

Resources are maintained in the `/resources` folder. Sub folders contain the following:

* `/template` - required resources to setup Observability Operator and Red Hat Advanced Cluster Security.
* `/grafana` - Grafana Dashboards
* `/prometheus` - Recording/Alert rules, openshift-monitoring federation scrape config, Observatorium remote write config & PodMonitors

## Install

The observability stack is installed by the [data plane terraforming Helm chart](https://github.com/stackrox/acs-fleet-manager/tree/main/dp-terraform/helm/rhacs-terraform).
Please follow the instructions in the fleet manager repository to install the Helm chart.

## Branches

The ACS cloud service data plane environments track the following branches:

| Environment | Branch     |
| ----------- | ---------- |
| integration | master     |
| stage       | stage      |
| production  | production |

New changes should propagate through the branches with sufficient soak time. Use the
[Sync master -> stage action](https://github.com/stackrox/rhacs-observability-resources/actions/workflows/sync-stage-from-master.yaml)
and [Sync stage -> production action](https://github.com/stackrox/rhacs-observability-resources/actions/workflows/sync-prod-from-stage.yaml)
GitHub actions to trigger branch synchronization.

## Contributing

### Prerequisites

The following tools are required for development:
- `jq` - please follow [the installation instructions](https://jqlang.github.io/jq/download).
- `mimirtool` - please follow [the installation instructions](https://grafana.com/docs/mimir/latest/manage/tools/mimirtool/#installation).
- `yq` - please follow [the installation instructions](https://github.com/mikefarah/yq/#install).

### Dashboards

To make changes to the rhacs dashboards:

* Update the dashboard .json in `resources/grafana/sources`.
* Run `make generate` to generate the corresponding resources for the Grafana operator.

To make changes to Kubernetes mixin resources:

First, make sure you have `go-jsonnet` and `jsonnet-bundler` installed.

Then:
* Update `resources/mixins/kubernetes/mixin.libsonnet`.
* Run `make generate` to generate the corresponding mixin resources.

### Federated metrics

If you make changes to Alerts, Recording rules, or Grafana dashboards, and if they include metrics collected by OSD Prometheus, ensure that the federation config includes new metrics.

* Run `make generate-federate` to update federation config.
* And commit changes in `resources/prometheus/federation-config.yaml` file to the repo.

You can add additional federated metrics that are not used in any Alert, Recording rule, or Grafana dashboard to `resources/prometheus/federation-config-base.yaml,` and they will be merged with other metrics. Always add a comment with the reason why metrics are added to the base list.

### Pre-commit hook

This repository makes use of [pre-commit](https://pre-commit.com/) framework. Refer to the [installation instructions](https://pre-commit.com/#installation) for further information.
To enable pre-commits, run the following in the root of the repository:
```bash
$ pre-commit install
```

The repository specifies a few local hooks. The hooks themselves have dependencies, which are required. Make sure you have the following installed:
- yq
- promtool
