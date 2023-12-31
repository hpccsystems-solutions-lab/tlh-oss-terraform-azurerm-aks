output "host" {
  description = "Host the service is addressable at."
  value       = "${local.name}.${var.namespace}.svc.cluster.local"
}

output "forward_port" {
  description = "Port the forward input is listening on."
  value       = local.chart_values.configuration.port
}

output "identity" {
  description = "Identity that Fluentd uses."
  value       = module.identity
}
