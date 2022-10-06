local kubernetes = import 'kubernetes-mixin/mixin.libsonnet';

kubernetes {
  _config+:: {
    kubeApiserverSelector: 'job="api"',
    kubeProxySelector: 'job="machine-config-daemon"',
    kubeSchedulerSelector: 'job="scheduler"',
  },
}
