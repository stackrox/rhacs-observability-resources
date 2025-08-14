# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository contains observability configuration for Red Hat Advanced Cluster Security (RHACS) managed service. It includes Prometheus alerts, recording rules, Grafana dashboards, and federation configuration for monitoring RHACS components across OpenShift clusters.

## Common Commands

### Main Build Commands
- `make generate` - Regenerate all resources (dashboards, alerts, federation config)
- `make generate-resources` - Generate Kubernetes mixin and Grafana dashboards only
- `make generate-federate` - Update federation configuration based on current alerts/dashboards
- `make update` - Update Kubernetes mixin dependencies

### Testing and Validation
- `./scripts/test-prom-rules.sh` - Run Prometheus rule unit tests
- `./scripts/lint-grafana.sh` - Lint Grafana dashboards
- `./scripts/run-kube-linter.sh` - Run kube-linter on Kubernetes resources
- `pre-commit run --all-files` - Run all pre-commit hooks

### Component-Specific Commands
- `make -C resources/mixins/kubernetes generate` - Generate Kubernetes mixin resources
- `make -C resources/grafana generate` - Generate Grafana dashboards from JSON sources

## Architecture

### Key Components

**Prometheus Rules (`resources/prometheus/`)**
- `prometheus-rules.yaml` - Main alerting rules for RHACS components (Central, Scanner, Fleetshard)
- `rhacs-recording-rules.yaml` - Recording rules for metrics aggregation
- `billing-rules.yaml` - Billing and quota tracking rules
- `unit_tests/` - Unit tests for all alert rules using promtool

**Grafana Dashboards (`resources/grafana/`)**
- `sources/` - Source JSON dashboards exported from Grafana
- `generated/dashboards/` - YAML manifests generated from sources for Grafana Operator
- `templates/` - Template files for dashboard generation

**Kubernetes Mixin (`resources/mixins/kubernetes/`)**
- `mixin.libsonnet` - Jsonnet configuration customizing kubernetes-mixin for RHACS
- Uses kubernetes-mixin from github.com/kubernetes-monitoring/kubernetes-mixin
- Customizes selectors and alert severities for OpenShift environment

**Federation & Remote Write (`resources/prometheus/`)**
- `federation-config.yaml` - Metrics federated from OpenShift monitoring
- `remote-write.yaml` - Configuration for pushing metrics to Observatorium
- Auto-generated based on metrics used in alerts/dashboards via `make generate-federate`

### Alert Policy

Alerts follow strict guidelines:
- **Critical alerts**: Page SREs, indicate service unavailability (timeline: ~5 minutes)
- **Warning alerts**: Addressed within ~60 minutes, don't pose immediate threat
- All alerts require SOP URLs and follow CamelCase naming (e.g., `RHACSCentralScrapeFailed`)
- Alert names should be prefixed with component name

### Dependencies

Required tools for development:
- `jq` - JSON processing for federation config generation
- `yq` - YAML processing for dashboard generation
- `mimirtool` - Grafana dashboard validation
- `jsonnet` and `jb` (jsonnet-bundler) - For Kubernetes mixin
- `promtool` - Prometheus rule testing
- `pre-commit` - Git hooks for validation

## Development Workflow

1. **Modifying Dashboards**: Edit JSON files in `resources/grafana/sources/`, then run `make generate`
2. **Modifying Alerts**: Edit `resources/prometheus/prometheus-rules.yaml`, add unit tests, run `make generate-federate`
3. **Kubernetes Mixin Changes**: Edit `resources/mixins/kubernetes/mixin.libsonnet`, run `make generate`
4. **Testing**: Always run `./scripts/test-prom-rules.sh` before committing changes

The repository uses Kustomize for resource organization with the main `resources/kustomization.yaml` defining all managed resources.
