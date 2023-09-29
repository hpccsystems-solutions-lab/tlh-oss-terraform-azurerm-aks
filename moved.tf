moved {
  from = module.core_config.kubectl_manifest.kube_prometheus_stack_crds
  to   = module.core_config.module.crds.module.crds["kube-prometheus-stack"].kubectl_manifest.crds
}

moved {
  from = module.core_config.module.aad_pod_identity.kubectl_manifest.crds
  to   = module.core_config.module.crds.module.crds["aad-pod-identity"].kubectl_manifest.crds
}

moved {
  from = module.core_config.module.cert_manager.kubectl_manifest.crds
  to   = module.core_config.module.crds.module.crds["cert-manager"].kubectl_manifest.crds
}

moved {
  from = module.core_config.module.external_dns.kubectl_manifest.crds
  to   = module.core_config.module.crds.module.crds["external-dns"].kubectl_manifest.crds
}

moved {
  from = module.core_config.module.fluentd
  to   = module.core_config.module.fluentd[0]
}

moved {
  from = module.core_config.module.fluent_bit
  to   = module.core_config.module.fluent_bit[0]
}

moved {
  from = module.core_config.module.kube_prometheus_stack
  to   = module.core_config.module.kube_prometheus_stack[0]
}

moved {
  from = module.cluster.azurerm_role_assignment.network_contributor_route_table
  to   = module.cluster.azurerm_role_assignment.network_contributor_route_table[0]
}
