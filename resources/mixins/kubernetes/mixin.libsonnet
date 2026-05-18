local utils = import 'kubernetes-mixin/lib/utils.libsonnet';
local kubernetes = import 'kubernetes-mixin/mixin.libsonnet';

kubernetes {
  _config+:: {
    cadvisorSelector: 'job="kubelet",metrics_path="/metrics/cadvisor"',
    containerfsSelector: 'id!=""',
    cpuThrottlingSelector: 'namespace!~"openshift-.*"',
    grafanaIntervalVar: '5m',
    kubeApiserverSelector: 'job="api"',
    kubeProxySelector: 'job="machine-config-daemon"',
    kubeSchedulerSelector: 'job="scheduler"',
    namespaceSelector: 'namespace!~"openshift-kube.*|openshift-logging|openshift-marketplace|openshift-aws-vpce-operator|openshift-deployment.*|kube.*"',
  },
} + {
  // Customize alert labels.
  prometheusAlerts+::
    local critical = 'critical';
    local info = 'info';
    local severityOverride = {
      KubeCPUOvercommit: { severity: critical },
      KubeMemoryOvercommit: { severity: critical },
      // Our current HPA strategy schedules max replica for scanner without it indicating an issue.
      KubeHpaMaxedOut: { severity: info },
      // Flapping alert since the upgrade to OCP 4.17. The incident has already been reported to SRE-P.
      // see ROX-30184, OHSS-48182
      KubeAPIErrorBudgetBurn: { severity: info },
    };

    local addExtraLabels(rule) = rule {
      [if 'alert' in rule then 'labels']+: {
        source: 'mixin/kubernetes',
        [if rule.alert in severityOverride then 'severity']: severityOverride[rule.alert].severity,
      },
    };
    utils.mapRuleGroups(addExtraLabels),
} + {
  // Remove unwanted alerts.
  prometheusAlerts+:: {
    groups:
      std.map(
        function(group)
          if group.name == 'kubernetes-system-apiserver' then
            group {
              rules: std.filter(
                function(rule)
                  // The certificates are managed by OSD. A fresh cluster triggers alerts.
                  rule.alert != 'KubeClientCertificateExpiration',
                group.rules
              ),
            }
          else if group.name == 'kubernetes-resources' then
            group {
              rules: std.map(
                function(rule)
                  if rule.alert == 'CPUThrottlingHigh' then
                    rule {
                      // Exclude config-reloader in rhacs-observability namespace from false positive CPU throttling alerts.
                      expr: std.rstripChars(rule.expr, '\n') + '\nunless on(%(clusterLabel)s, container, pod, namespace) container_cpu_cfs_throttled_periods_total{namespace="rhacs-observability", container="config-reloader"}\n' % $._config,
                    }
                  else
                    rule,
                group.rules
              ),
            }
          else if group.name == 'kubernetes-storage' then
            group {
              rules: std.map(
                function(rule)
                  if rule.alert == 'KubePersistentVolumeFillingUp' && rule.labels.severity == 'warning' then
                    rule {
                      // Exclude scanner-db PVCs from warning alerts because scanner-db dynamically grows/shrinks.
                      expr: std.rstripChars(rule.expr, '\n') + '\nunless on(%(clusterLabel)s, namespace, persistentvolumeclaim) kubelet_volume_stats_available_bytes{persistentvolumeclaim=~"scanner-db.*"}\n' % $._config,
                    }
                  else
                    rule,
                group.rules
              ),
            }
          else if group.name == 'kubernetes-system-kubelet' then
            group {
              rules: std.filter(
                function(rule)
                  // The certificates are managed by OSD. A fresh cluster triggers alerts.
                  rule.alert != 'KubeletClientCertificateExpiration'
                  && rule.alert != 'KubeletServerCertificateExpiration',
                group.rules
              ),
            }
          else
            group,
        super.groups
      ),
  },
}
