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

variable "namespaces" {
  description = "List of namespaces to create on the cluster."
  type        = list(string)
}

variable "secrets" {
  description = "Map of secrets to apply to the cluster, the namespace must already exist or be in the namespaces variable."
  type = map(object({
    name      = string
    namespace = string
    type      = string
    data      = map(string)
  }))
}

variable "configmaps" {
  description = "Map of configmaps to apply to the cluster, the namespace must already exist or be in the namespaces variable."
  type = map(object({
    name      = string
    namespace = string
    data      = map(string)
  }))
}

variable "additional_priority_classes" {
  type = map(object({
    description = string
    value       = number
    labels      = map(string)
    annotations = map(string)
  }))
  default     = null
  description = "A map defining additional priority classes. Refer to [this link](https://github.com/LexisNexis-RBA/terraform-kubernetes-priority-class) for additional information."
}

variable "additional_storage_classes" {
  type = map(object({
    labels                 = map(string)
    annotations            = map(string)
    storage_provisioner    = string
    parameters             = map(string)
    reclaim_policy         = string
    mount_options          = list(string)
    volume_binding_mode    = string
    allow_volume_expansion = bool
  }))
  default     = null
  description = "A map defining additional storage classes. Refer to [this link](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/blob/main/modules/storage-classes/README.md) for additional information."

  validation {
    condition = var.additional_storage_classes == null ? true : (length([for strgclass in var.additional_storage_classes : strgclass.reclaim_policy if strgclass.reclaim_policy != "Retain"]) == 0 ||
    length([for strgclass in var.additional_storage_classes : strgclass.reclaim_policy if strgclass.reclaim_policy != "Delete"]) == 0)
    error_message = "The reclaim policy setting must be set to 'Delete' or 'Reclaim'."
  }

  validation {
    condition = var.additional_storage_classes == null ? true : (length([for strgclass in var.additional_storage_classes : strgclass.storage_provisioner if strgclass.storage_provisioner != "kubernetes.io/azure-file"]) == 0 ||
    length([for strgclass in var.additional_storage_classes : strgclass.storage_provisioner if strgclass.storage_provisioner != "kubernetes.io/azure-disk"]) == 0)
    error_message = "The storage provisioner setting must be set to 'kubernetes.io/azure-file' or 'kubernetes.io/azure-disk'."
  }

  validation {
    condition = var.additional_storage_classes == null ? true : (length([for strgclass in var.additional_storage_classes : strgclass.volume_binding_mode if strgclass.volume_binding_mode != "Immediate"]) == 0 ||
    length([for strgclass in var.additional_storage_classes : strgclass.volume_binding_mode if strgclass.volume_binding_mode != "WaitForFirstConsumer"]) == 0)
    error_message = "The volume binding mode setting must be set to 'Immediate' or 'WaitForFirstConsumer'."
  }
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

variable "external_dns_zones" {
  description = "DNS Zone details for external-dns."
  type = object({
    names               = list(string)
    resource_group_name = string
  })
}

variable "cert_manager_dns_zones" {
  description = "The name and resource group of the DNS zone associated with your Azure subscription"
  type = map(string)
}

variable "letsencrypt_environment" {
  description = "Let's Encrypt enfironment to use, staging or production."
  type        = string
  default     = "staging"

  validation {
    condition     = contains(["staging", "production"], lower(var.letsencrypt_environment))
    error_message = "The \"letsencrypt_environment\" variable must be either \"staging\" or \"production\"."
  }
}

variable "letsencrypt_email" {
  description = "Email address for expiration notifications."
  type        = string
  default     = ""
}

variable "azuread_clusterrole_map" {
  description = "Map of Azure AD User and Group Ids to configure in Kubernetes clusterrolebindings"
  type = object(
    {
      cluster_admin_users   = map(string)
      cluster_view_users    = map(string)
      standard_view_users   = map(string)
      standard_view_groups  = map(string)
    }
  )
}
