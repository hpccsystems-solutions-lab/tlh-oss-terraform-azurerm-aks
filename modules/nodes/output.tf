output "node_pool_defaults" {
  description = "The node pool defaults."
  value       = local.node_pool_defaults
}

output "node_pools" {
  description = "The node_pool definitions."
  value       = local.node_pools
}

output "default_node_pool" {
  description = "Default node pool (from definition list)"
  value       = local.default_node_pool.name
}