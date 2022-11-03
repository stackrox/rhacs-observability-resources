local utils = import 'kubernetes-mixin/lib/utils.libsonnet';
local kubernetes = import 'kubernetes-mixin/mixin.libsonnet';

kubernetes {
  _config+:: {
    cadvisorSelector: 'job="kubelet",metrics_path="/metrics/cadvisor"',
    kubeApiserverSelector: 'job="api"',
    kubeProxySelector: 'job="machine-config-daemon"',
    kubeSchedulerSelector: 'job="scheduler"',
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
                  // The client certificate is managed by OSD. A fresh cluster triggers this alert.
                  rule.alert != 'KubeClientCertificateExpiration',
                group.rules
              ),
            }
          else
            group,
        super.groups
      ),
  },
}
