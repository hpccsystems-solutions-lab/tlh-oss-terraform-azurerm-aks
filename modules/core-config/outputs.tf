output "cert_manager_identity" {
  description = "Identity that Cert Manager uses."
  value       = module.cert_manager.identity
}

output "coredns_custom_config_map_name" {
  description = "Name of the CoreDNS custom ConfigMap."
  value       = module.coredns.custom_config_map_name
}

output "coredns_custom_config_map_namespace" {
  description = "Namespace of the CoreDNS custom ConfigMap."
  value       = module.coredns.custom_config_map_namespace
}

output "external_dns_private_identity" {
  description = "Identity that private ExternalDNS uses."
  value       = module.external_dns.private_identity
}

output "external_dns_public_identity" {
  description = "Identity that public ExternalDNS uses."
  value       = module.external_dns.public_identity
}

output "fluent_bit_aggregator_identity" {
  description = "Identity that Fluent Bit Aggregator uses."
  value       = var.core_services_config.fluent_bit_aggregator.enabled ? module.fluent_bit_aggregator[0].identity : null
}

output "fluentd_identity" {
  description = "Identity that Fluentd uses."
  value       = var.core_services_config.fluent_bit_aggregator.enabled ? null : module.fluentd[0].identity
}

output "grafana_identity" {
  description = "Identity that Grafana uses."
  value       = module.kube_prometheus_stack.grafana_identity
}
