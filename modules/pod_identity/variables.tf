variable "aks_identity" {
  description = "Kubelet identity client_id."
  type        = string
}

variable "aks_resource_group_id" {
  description = "resource group id containing AKS cluster"
  type        = string
}

variable "aks_node_resource_group" {
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