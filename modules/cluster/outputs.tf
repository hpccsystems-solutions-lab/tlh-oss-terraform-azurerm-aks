output "id" {
  description = "Kubernetes managed cluster ID."
  value       = azurerm_kubernetes_cluster.default.id
  depends_on  = [time_sleep.modify]
}

output "cluster_name" {
  description = "Name of the cluster."
  value       = azurerm_kubernetes_cluster.default.name
}

output "cluster_version" {
  description = "Kubernetes version of the cluster as <major>.<minor>."
  value       = azurerm_kubernetes_cluster.default.kubernetes_version
}

output "cluster_version_full" {
  description = "Full Kubernetes version of the cluster."
  value       = module.cluster_version.values != null && startswith(lookup(coalesce(module.cluster_version.values, {}), "current_kubernetes_version", ""), var.cluster_version) ? module.cluster_version.values.current_kubernetes_version : data.azurerm_kubernetes_service_versions.default.latest_version
}

output "latest_version_full" {
  description = "Latest full Kubernetes version the cluster could be on."
  value       = data.azurerm_kubernetes_service_versions.default.latest_version
}

output "fqdn" {
  description = "FQDN of the Azure Kubernetes managed cluster."
  value       = azurerm_kubernetes_cluster.default.fqdn
}

output "endpoint" {
  description = "Endpoint for the Azure Kubernetes managed cluster API server."
  value       = azurerm_kubernetes_cluster.default.kube_config[0].host
}

output "certificate_authority_data" {
  description = "Base64 encoded certificate data for the Azure Kubernetes managed cluster API server."
  value       = azurerm_kubernetes_cluster.default.kube_config[0].cluster_ca_certificate
}

output "oidc_issuer_url" {
  description = "URL for the cluster OpenID Connect identity provider."
  value       = azurerm_kubernetes_cluster.default.oidc_issuer_url
}

output "cluster_identity" {
  description = "User assigned identity used by the cluster."
  value       = azurerm_user_assigned_identity.default
}

output "kubelet_identity" {
  description = "User assigned identity used by the Kubelet."
  value       = azurerm_kubernetes_cluster.default.kubelet_identity[0]
}

output "effective_outbound_ips" {
  description = "Outbound IPs from the Azure Kubernetes Service cluster managed load balancer (this will be an empty array if the cluster is uisng a user-assigned NAT Gateway)."
  value       = [for ip in data.azurerm_public_ip.outbound : ip.ip_address]
}

output "node_resource_group_name" {
  description = "Auto-generated resource group which contains the resources for this managed Kubernetes cluster."
  value       = azurerm_kubernetes_cluster.default.node_resource_group
}

output "oms_agent_identity" {
  description = "Identity that the OMS agent uses."
  value       = var.oms_agent ? azurerm_kubernetes_cluster.default.oms_agent[0].oms_agent_identity : null
}

output "windows_config" {
  description = "Windows configuration."
  value = {
    enabled        = var.windows_support
    admin_username = var.windows_support ? random_password.windows_admin_username[0].result : null
    admin_password = var.windows_support ? random_password.windows_admin_password[0].result : null
  }
}

output "kube_admin_config" {
  description = "kube_admin_config for the Azure Kubernetes managed cluster API server."
  value       = azurerm_kubernetes_cluster.default.kube_admin_config
}
