output "alertmanager_dashboard_url" {
  description = "URL to the Alertmanager dashboard"
  value       = "https://${local.alertmanager_host}/"
}

output "grafana_dashboard_url" {
  description = "URL to the Grafana dashboard"
  value       = "https://${local.grafana_host}/"
}

output "grafana_identity" {
  description = "Identity that Grafana uses."
  value       = module.identity_grafana
}

output "prometheus_dashboard_url" {
  description = "URL to the Prometheus dashboard"
  value       = "https://${local.prometheus_host}/"
}

output "thanos_query_frontend_dashboard_url" {
  description = "URL to the Thanos Query Frontend dashboard"
  value       = "https://${local.thanos_query_frontend_host}/"
}

output "thanos_rule_dashboard_url" {
  description = "URL to the Thanos Rule dashboard"
  value       = "https://${local.thanos_rule_host}/"
}
