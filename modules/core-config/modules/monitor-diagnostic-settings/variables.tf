variable "azure_subscription_id" {
  type        = string
  description = "The GUID of your Azure subscription"

  validation {
    condition     = can(regex("[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}", var.azure_subscription_id))
    error_message = "The \"azure_subscription_id\" variable must be a GUID (xxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)."
  }
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group of your AKS cluster"
}

variable "resource_group_location" {
  type        = string
  description = "The location of the resource group of your AKS cluster"
}

variable "cluster_id" {
  description = "The unique identifier of the AKS cluster."
  type        = string
}

variable "cluster_name" {
  description = "The name of the cluster that has been created."
  type        = string
}

variable "storage_account_id" {
  description = "Storage account id to store a secondary copy of diagnostic logs."
  type        = string
}

variable "tags" {
  type        = map(string)
  description = "Tags to assign to Azure resources created by this module"
  default     = {}
}