.PHONY: update
update: install update-jb generate

.PHONY: install
install:
	@jb install github.com/kubernetes-monitoring/kubernetes-mixin

.PHONY: update-jb
update-jb:
	@jb update

.PHONY: alerts
alerts:
	@jsonnet -J vendor -S -e 'std.manifestYamlDoc((import "mixin.libsonnet").prometheusAlerts)' > generated/alerts.yml
	@yq '.spec += load("generated/alerts.yml")' templates/alerts.yaml > ../../prometheus/generated/kubernetes-mixin-alerts.yaml

.PHONY:
dashboards: templates/dashboards/*
	@jsonnet -J vendor -m generated/dashboards -e '(import "mixin.libsonnet").grafanaDashboards'
	@scripts/generate-dashboards.sh

.PHONY: generate
generate: install alerts dashboards
