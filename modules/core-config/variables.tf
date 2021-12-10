variable "azure_environment" {
  description = "Azure Cloud Environment."
  type        = string
}

variable "azure_tenant_id" {
  type        = string
  description = "The GUID of your Azure tenant"

  validation {
    condition     = can(regex("[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}", var.azure_tenant_id))
    error_message = "The \"azure_tenant_id\" variable must be a GUID (xxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)."
  }
}

variable "azure_subscription_id" {
  type        = string
  description = "The GUID of your Azure subscription"

  validation {
    condition     = can(regex("[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}", var.azure_subscription_id))
    error_message = "The \"azure_subscription_id\" variable must be a GUID (xxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)."
  }
}

variable "tags" {
  description = "Tags to be applied to all resources."
  type        = map(string)
}

variable "resource_group_name" {
  description = "The name of the Resource Group where the Kubernetes Cluster exists."
  type        = string
}

variable "location" {
  description = "Azure region in which to build resources."
  type        = string
}

variable "cluster_name" {
  description = "The name of the AKS cluster."
  type        = string
}

variable "cluster_id" {
  description = "The unique identifier of the AKS cluster."
  type        = string
}

variable "cluster_version" {
  description = "The Kubernetes minor version of the cluster (e.g. x.y)"
  type        = string
}

variable "aks_identity" {
  description = "Kubelet identity client_id."
  type        = string
}

variable "aks_node_resource_group_name" {
  description = "resource group created by AKS"
  type        = string
}

variable "network_plugin" {
  description = "Kubernetes Network Plugin (kubenet or azure)"
  type        = string
  default     = "kubenet"

  validation {
    condition     = contains(["kubenet", "azure"], var.network_plugin)
    error_message = "Network plugin must be kubenet or azure."
  }
}

variable "azuread_clusterrole_map" {
  description = "Map of Azure AD User and Group Ids to configure in Kubernetes clusterrolebindings"
  type = object(
    {
      cluster_admin_users  = map(string)
      cluster_view_users   = map(string)
      standard_view_users  = map(string)
      standard_view_groups = map(string)
    }
  )
}

variable "config" {
  description = "Platform service configuration options"
  type        = any
}

variable "log_analytics_workspace_id" {
  description = "ID of the Azure Log Analytics Workspace optionally configured for the cluster"
  type        = string
}