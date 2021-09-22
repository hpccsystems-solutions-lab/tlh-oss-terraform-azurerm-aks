variable "tags" {
  type        = map(string)
  description = "Tags to assign to Azure resources created by this module"
  default     = {}
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group of your AKS cluster"
}

variable "resource_group_location" {
  type        = string
  description = "The location of the resource group of your AKS cluster"
}

variable "cluster_name" {
  type        = string
  description = "The name of your AKS cluster"
}

variable "public_domain_filters" {
  description = "Public DNS Zone details for external-dns."
  type = object({
    names               = list(string)
    resource_group_name = string
  })
}

variable "private_domain_filters" {
  description = "Private DNS Zone details for external-dns."
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

variable "additional_sources" {
  description = "Additional Kubernetes sources to handle."
  type        = list(string)
}

