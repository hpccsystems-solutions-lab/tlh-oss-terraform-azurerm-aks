output "node_pool_defaults" {
  description = "The node pool defaults."
  value       = local.worker_group_defaults
}

output "node_pools" {
  description = "The node_pool definitions."
  value       = merge(local.system_worker_group, local.worker_groups)
}