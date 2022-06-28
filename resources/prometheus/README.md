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

* Non filtering
* Filtering

For both types a temporary label is added to the metrics called `__tmp_keep`.  For filtering metrics an extra rule is needed specifying what time series you want to drop. From there a rule at the end specifies to keep all the time series with the `__tmp_keep` label and then drop the temp label. What's left is sent to observatorium.

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

*NOTE:* If using multiple regex a `;` is needed to separate them. Also wildcards can be used in drop rules if multiple time series from the same types of metric are being removed. For example:

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
