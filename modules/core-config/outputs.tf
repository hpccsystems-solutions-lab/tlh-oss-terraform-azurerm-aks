output "grafana_identity" {
  description = "Grafana identity."
  value       = module.kube_prometheus_stack.grafana_identity
}
