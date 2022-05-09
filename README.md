# Managed Red Hat Advanced Cluster Security Service Observability Config

## What is it?

This repository contains resources & other information required by the [Observability Operator](https://github.com/redhat-developer/observability-operator)
to configure the Observability stack for Managed Red Hat Advanced Cluster Security.

Resources are maintained in the `/resources` folder. Sub folders contain the following:

* `/template` - required resources to setup Observability Operator and Red Hat Advanced Cluster Security.
* `/grafana` - Grafana Dashboards
* `/prometheus` - Recording/Alert rules, openshift-monitoring federation scrape config, Observatorium remote write config & PodMonitors

## Install

You can do the following steps.

### Prerequirements

1. OSD cluster is up and running
2. `oc` command context is set to use running cluster
3. RHACS is deployed on the cluster

### Steps

1. **optional** if RHACS is not installed into `stackrox` namespace, you should export `RHACS_NAMESPACE` variable. i.e. `export RHACS_NAMESPACE=rhacs-operator`

2. set GitHub information in environment variables
```
# GitHub repo API URL where the configuration for RHACS observability is stored
# i.e. https://api.github.com/repos/stackrox/rhacs-observability-resources/contents
export GITHUB_REPO=https://api.github.com/repos/stackrox/rhacs-observability-resources/contents

# branch or release which should be deployed
# NOTE: if a branch is used, configs will be pulled and updated every 1h
export GITHUB_TAG=master

# access token to GitHub in plain text.
# NOTE: GitHub Token requires only the "repo" scope
export GITHUB_TOKEN="<github-token>"
```

3. set Observatorium information in environment variables
```
# Gateway URL
export OBSERVATORIUM_GATEWAY="https://observatorium-mst.api.stage.openshift.com"

# Metrics client and secret for Red Hat Advanced Cluster Security
export OBSERVATORIUM_RHSSO_METRICS_CLIENT_ID="observatorium-rhacs-metrics-staging"
export OBSERVATORIUM_RHSSO_METRICS_SECRET="<rhacs-metrics-secret>"

# Logs client and secret for Red Hat Advanced Cluster Security
export OBSERVATORIUM_RHSSO_LOGS_CLIENT_ID="observatorium-rhacs-logs-staging"
export OBSERVATORIUM_RHSSO_LOGS_SECRET="<rhacs-logs-secret>"
```

4. Execute the install script
```
./scripts/install-rhacs.sh
```

After that, open `<Cluster_URL>/k8s/ns/rhacs-observability/routes` in your browser. Wait for Prometheus and Grafana routes to be up and ready for use. Enjoy!
