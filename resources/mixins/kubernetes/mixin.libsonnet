local kubernetes = import 'kubernetes-mixin/mixin.libsonnet';
local utils = import 'kubernetes-mixin/lib/utils.libsonnet';

kubernetes {
  _config+:: {
    kubeApiserverSelector: 'job="api"',
    kubeProxySelector: 'job="machine-config-daemon"',
    kubeSchedulerSelector: 'job="scheduler"',
  },
  prometheusAlerts+::
    local addExtraLabels(rule) = rule {
      [if 'alert' in rule then 'labels']+: {
        source: 'mixin/kubernetes',
      },
    };
    utils.mapRuleGroups(addExtraLabels),
}
