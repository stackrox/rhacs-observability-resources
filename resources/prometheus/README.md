## Alerts Policy

### Summary

This policy is originally based on the [Alerting Consistency][3] proposal for OpenShift alerts.

Clear and actionable alerts are a key component of a smooth operational
experience. Ensuring we have clear and concise guidelines for engineers and
SRE creating new alerts for RHACS will result in a better
experience for end users. This policy aims to outline the collective wisdom
of the RHACS engineer, CSSRE and wider monitoring communities, and how it
relates to RHACS alerting.

> **_Important:_** Every alert regardless of severity is required to have a corresponding SOP.

### Recommended Reading

A list of references on good alerting practices:

- [Google SRE Book - Monitoring Distributed Systems][4]
- [Prometheus Alerting Documentation][5]
- [Alerting for Distributed Systems][1]

### Alert Ownership

RHACS engineering teams are responsible for writing and maintaining alerting
rules and SOPs for their components, i.e. their operators and operands.
CSSRE are available for the consulting and review of alerts & SOPS.
CSSRE may also contribute alerting changes, though this should be done in
collaboration with RHACS engineering. Both warning and critical alerts are required to have a corresponding SOP.

### Style Guide

- Alert names MUST be CamelCase, e.g.: `StrimziKafkaStuck`
- Alert names SHOULD be prefixed with a component, e.g.: `ZookeeperPersistentVolumeFillingUp`
  - There may be exceptions for some broadly scoped alerts, e.g.: `TargetDown`
- Alerts MUST include a `severity` label indicating the alert's urgency.
  - Valid severities are: `critical` or `warning` — see below for
    guidelines on writing alerts of each severity.
- Alerts MUST include `summary` and `description` annotations.
  - Think of `summary` as the first line of a commit message, or an email
    subject line. It should be brief but informative. The `description` is the
    longer, more detailed explanation of the alert.
- Alerts SHOULD include a `namespace` label indicating the source of the alert.
  - Many alerts will include this by virtue of the fact that their PromQL
    expressions result in a namespace label. Others may require a static
    namespace label.
- All alerts MUST include a `sop_url` annotation.
  - SOP style documentation for resolving alerts is required.
    These runbooks are reviewed by CSSRE and currently live in the
    [TODO: add link once rhacs repo exists] repository.

### Critical Alerts

TL/DR: For alerting current and impending disaster situations. These alerts
page an SRE. The situation should warrant waking someone in the middle of the
night.

Timeline: ~5 minutes.

Reserve critical level alerts only for reporting conditions that may lead to
service unavailability for one or more Central instances.
Failures of most individual components should not trigger critical level alerts,
unless they would result in that condition. Configure critical level
alerts, so they fire before the situation becomes irrecoverable.

Example critical alert:

```yaml
- alert: StrimziKafkaStuck
  expr: strimzi_resource_state != 1
  for: 10m
  labels:
    severity: critical
  annotations:
    summary: "Strimzi Kafka is stuck in a non-ready state"
    description: "The Strimzi Kafka {{ $labels.name }} in the {{ $labels.resource_namespace }} namespace, managed by Strimzi pod {{ $labels.pod }} has been in a non-ready state for 10 minutes"
    sop_url: "https://github.com/bf2fc6cc711aee1a0c2a/kas-sre-sops/blob/main/sops/alerts/strimzi_kafka_stuck.asciidoc"
```

This alert fires if a Kafka instance has _not_ been ready for
the last 10 minutes. This is a clear example of a critical
data-plane issue that represents a threat to the operability of a kafka instance,
and likely warrants paging someone. The alert has a clear summary and
description annotations, and it links to a SOP with information on
investigating and resolving the issue.

The group of critical alerts should be small, very well-defined, highly
documented, polished and with a high bar set for entry. This includes a
mandatory review of a proposed critical alert by the CSSRE team.

### Warning Alerts

TL/DR: The vast majority of alerts should use this severity. Issues at the
warning level should be addressed in a timely manner, but don't pose an
immediate threat to the operation of the service as a whole.

Timeline: ~60 minutes

If your alert does not meet the criteria in "Critical Alerts" above, it belongs
to the warning level or lower.

Use warning level alerts for reporting conditions that may lead to inability to
deliver individual features of the service, but not the service as a
whole. Most alerts are likely to be warnings. Configure warning level alerts so
that they do not fire until components have sufficient time to try to recover
from the interruption automatically. Expect CSSRE to periodically check for warnings,
but for them _not_ to respond with corrective action immediately.

Example warning alert:

```yaml
- alert: ZookeeperPersistentVolumeFillingUp
  expr: (kubelet_volume_stats_available_bytes{persistentvolumeclaim=~"data-(.+)-zookeeper-[0-9]+"} / kubelet_volume_stats_capacity_bytes{persistentvolumeclaim=~"data-(.+)-zookeeper-[0-9]+"} < 0.15) and predict_linear(kubelet_volume_stats_available_bytes{persistentvolumeclaim=~"data-(.+)-zookeeper-[0-9]+"}[6h], 4 * 24 * 3600) < 0
  for: 1h
  labels:
    severity: warning
  annotations:
    summary: "Zookeeper PersistentVolume is filling up."
    description: "Based on recent sampling, the Zookeeper PersistentVolume claimed by {{ $labels.persistentvolumeclaim }} in Namespace {{ $labels.namespace }} is expected to fill up within four days. Currently {{ $value | humanizePercentage }} is available."
    sop_url: "https://github.com/bf2fc6cc711aee1a0c2a/kas-sre-sops/blob/main/sops/alerts/persistent_volume_filling.asciidoc"
```

This alert fires if one or more Zookeeper volumes are getting close to filling up.
The alert has a clear name and informative summary and description annotations,
and it links to a SOP with information on investigating and resolving the issue.
The timeline is appropriate for allowing the service to resolve the issue itself, avoiding the need to alert SRE.

## Federation Configuration

OpenShift runs cAdvisor to scrape cpu, memory, network, and kube-state metrics for any namespace.
These metrics may be federated from the OpenShift platform monitoring Prometheus instance to the ACS Prometheus instance.

The configuration for the federation scrape job is defined in `./federation-config.yaml`.
When updating this configuraiton, please only add the bare minimum required for your use case.
There are plenty of examples in the yaml file already of how to filter to specific metrics or subsets of metrics.

### Size & cardinality considerations

- Use full metric names where possible instead of wildcards, which could bring in a lot of unnecessary metrics or even future defined metrics without realising.
- Filter by labels as much as possible. The most common filter is the namespace.
- Consider the impact on the scrape size and duration when adding metrics. Check out the `scrape_duration_seconds{job="openshift-monitoring-federation"}` metric to observe the scrape duration.
- Consider linear growth in size and scrape duration.

## Prometheus Remote Write to Observatorium

A subset of metrics from the kafka prometheus instance in each OSD cluster are remote written to Observatorium for fleet management purposes.
Observatorium is also used for exposing user metrics via the kafka control plane APIs and UI.

The configuration for remote write is defined in ./remote-write.yaml.
The below sections give more detail on how to make sense of this file and update it.

### Relabel config overview:

There are two ways of specifying metrics:

- Non filtering
- Filtering

For both types a temporary label is added to the metrics called `__tmp_keep`. For filtering metrics an extra rule is needed specifying what time series you want to drop. From there a rule at the end specifies to keep all the time series with the `__tmp_keep` label and then drop the temp label. What's left is sent to observatorium.

### Adding metrics without filtering:

If a metric is being sent to observatorium and the metrics time series don't need to be filtered the following example is sufficient:

```
  - action: replace
    regex: cluster_version$
    replacement: 'true'
    sourceLabels:
      - __name__
    targetLabel: __tmp_keep
```

The rule is creating a temporary label called `__tmp_keep` with the value of true for the metric names that match `cluster_version`

### Adding metrics with filtering:

If a metric is being sent to observatorium and the time series in the metric need to be filtered as there are time series that we don't need, the following example shows that:

```
  - action: replace
    regex: >-
      node_namespace_pod_container:container_cpu_usage_seconds_total:sum_rate$
    replacement: 'true'
    sourceLabels:
      - __name__
    targetLabel: __tmp_keep
  - action: drop
    regex: >-
      node_namespace_pod_container:container_cpu_usage_seconds_total:sum_rate;openshift.*$
    sourceLabels:
      - __name__
      - namespace
```

Filtering the metrics time series is a very similar process to non filtering metrics. The only difference is the extra drop rule. The drop rule works by looking at the specified source labels and seeing if any metrics satisfy the specified regex. For example above the drop label is looking for the metric name `node_namespace_pod_container:container_cpu_usage_seconds_total:sum_rate` with a `namespace` matching regex `openshift.*` and dropping the time series if these both match.

_NOTE:_ When using multiple regex a `;` is needed to separate them. Also wildcards can be used in drop rules if multiple time series from the same types of metric are being removed. For example:

```
  - action: drop
    regex: ^;container_network.*$
    sourceLabels:
      - namespace
      - __name__
```

### Size & cardinality considerations

Like when federating metrics, there are size & cardinality considerations when pushing metrics from each OSD cluster to Observatorium.
Most of the same points are relevant:

- use full metric names where possible instead of wildcards that could included a lot of unnecessary metrics or even future defined metrics without realising
- filter by labels as much as possible. Label combinations are the main cause of cardinality explosion as each new combination results in a new metrics series on disk. See the article [Cardinality is key](https://www.robustperception.io/cardinality-is-key#:~:text=Cardinality%20is%20how%20many%20unique,the%20cardinality%20would%20be%203.) for a good explanation of this
- consider linear growth in size & scrape duration. For example, when there are a lot of kafka instances in an OSD cluster.
- consider undeterministic user impacted growth in metrics. For example, number of kafka topics created.
