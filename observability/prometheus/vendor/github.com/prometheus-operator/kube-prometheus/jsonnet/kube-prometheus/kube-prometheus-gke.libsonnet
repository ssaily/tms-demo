(import './kube-prometheus-managed-cluster.libsonnet') + {
  _config+:: {
    prometheusAdapter+:: {
      config+: {
        resourceRules:: null,
      },
    },
  },

  prometheusAdapter+:: {
    apiService:: null,
  },
}
