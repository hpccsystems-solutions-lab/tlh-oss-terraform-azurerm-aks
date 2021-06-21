variable "resource_group_name" {
  description = "resource group containing AKS cluster"
  type        = string
}

variable "namespace" {
  type        = string
  description = "The name of the Kubernetes namespace to contain the external-dns resources"
  default     = "dns"
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

variable "azure_subscription_id" {
  type        = string
  description = "The GUID of your Azure subscription"

  validation {
    condition     = can(regex("[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}", var.azure_subscription_id))
    error_message = "The \"azure_subscription_id\" variable must be a GUID (xxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)."
  }
}