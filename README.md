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

The ACS cloud service data plane `stage` environment tracks the `master` branch. Conversely, the production environment tracks the `production` branch.
Changes are merged from the `master` to the `production` branch after sufficient soak time on the stage environment.

## Contributing

This repository makes use of [pre-commit](https://pre-commit.com/) framework. Refer to the [installation instructions](https://pre-commit.com/#installation) for further information.
To enable pre-commits, run the following in the root of the repository:
```bash
$ pre-commit install
```

The repository specifies a few local hooks. The hooks themselves have dependencies, which are required. Make sure you have the following installed:
- yq
- promtool
