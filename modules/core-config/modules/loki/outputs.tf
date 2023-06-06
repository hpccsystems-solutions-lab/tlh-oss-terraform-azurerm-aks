output "host" {
  description = "Host for the Loki service."
  value       = "loki-gateway.${var.namespace}.svc.cluster.local"
}

output "port" {
  description = "Port for the Loki service."
  value       = 80
}
