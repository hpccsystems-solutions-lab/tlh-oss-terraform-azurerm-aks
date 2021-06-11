variable "tags" {
  type        = map(string)
  description = "Tags to assign to Azure resources created by this module"
  default     = {}
}

variable "namespace" {
  type        = string
  description = "The name of the Kubernetes namespace to contain the external-dns resources"
  default     = "dns"
}

variable "tolerations" {
  type        = list(any)
  description = "Tolerations for the external-dns pods."
}

variable "helm_chart_version" {
  type        = string
  description = "The version of the external-dns Helm chart to use"
  default     = "4.10.0"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group of your AKS cluster"
}

variable "cluster_name" {
  type        = string
  description = "The name of your AKS cluster"
}

variable "dns_zones" {
  description = "DNS Zone details for external-dns."
  type = object({
    names               = list(string)
    resource_group_name = string
  })
}

variable "dns_permissions" {
  type        = list(string)
  description = "The default list of permissions granted to the MSI used by external-dns"
  default = [
    "Microsoft.Network/dnszones/read",
    "Microsoft.Network/dnszones/all/read",
    "Microsoft.Network/dnszones/recordsets/read",
    "Microsoft.Network/dnszones/A/*",
    "Microsoft.Network/dnszones/CNAME/read",
    "Microsoft.Network/dnszones/TXT/*",
    "Microsoft.Network/dnszones/NS/read",
    "Microsoft.Network/privateDnsZones/read",
    "Microsoft.Network/privateDnsZones/ALL/read",
    "Microsoft.Network/privateDnsZones/recordsets/read",
    "Microsoft.Network/privateDnsZones/A/*",
    "Microsoft.Network/privateDnsZones/CNAME/*",
    "Microsoft.Network/privateDnsZones/TXT/*",
  ]
}

variable "azure_cloud" {
  type        = string
  description = "The AKS node pool where external-dns should run"
  default     = "AZUREPUBLICCLOUD"

  validation {
    condition     = var.azure_cloud == "AZUREPUBLICCLOUD" || var.azure_cloud == "AZUREUSGOVERNMENTCLOUD"
    error_message = "The \"azure_cloud\" variable must be either \"AZUREPUBLICCLOUD\" or \"AZUREUSGOVERNMENTCLOUD\"."
  }
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

# See https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/ for what the next four variables mean
variable "resources_request_cpu" {
  type        = string
  description = "Request this amount of CPU from the cluster"
  default     = "10m"
}

variable "resources_request_memory" {
  type        = string
  description = "Request this amount of RAM from the cluster"
  default     = "64Mi"
}

variable "resources_limit_cpu" {
  type        = string
  description = "Limit CPU utilization to this value"
  default     = "100m"
}

variable "resources_limit_memory" {
  type        = string
  description = "Limit RAM utilization to this value"
  default     = "128Mi"
}