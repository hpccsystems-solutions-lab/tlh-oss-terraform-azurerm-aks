output "identity" {
  description = "Identity that Cert Manager uses."
  value       = module.identity
}

output "default_issuer_kind" {
  description = "The default issuer kind."
  value       = var.default_issuer_kind
}

output "default_issuer_name" {
  description = "The default issuer."
  value       = var.default_issuer_name
}
