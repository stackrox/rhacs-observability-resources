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
    namespaceSelector: 'namespace!~"openshift-kube.*|openshift-logging|openshift-marketplace|openshift-deployment.*|kube.*"',
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
