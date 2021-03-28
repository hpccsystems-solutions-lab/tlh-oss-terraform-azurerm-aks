output "node_pools" {
  description = "The node_pool definitions."
  value       = local.node_pools
}

output "default_node_pool" {
  description = "Default node pool (from definition list)"
  value       = local.default_node_pool.name
}