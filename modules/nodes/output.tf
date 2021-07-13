output "node_pools" {
  description = "The node_pool definitions."
  value       = local.node_pools
}

output "default_node_pool" {
  description = "Default node pool (from definition list)"
  value       = "${local.system_node_pool.name}1"
}

output "windows_config" {
  value = {
    enabled        = local.windows_nodes
    admin_username = (local.windows_nodes ? random_password.windows_admin_username.0.result : null)
    admin_password = (local.windows_nodes ? random_password.windows_admin_password.0.result : null)
  }
}