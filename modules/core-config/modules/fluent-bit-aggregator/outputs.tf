output "host" {
  description = "Host the service is addressable at."
  value       = "${local.name}.${var.namespace}.svc.cluster.local"
}

output "forward_port" {
  description = "Port the forward input is listening on."
  value       = local.chart_values.service.additionalPorts[0].port
}

output "identity" {
  description = "Identity that Fluent Bit Aggregator uses."
  value       = module.identity
}
