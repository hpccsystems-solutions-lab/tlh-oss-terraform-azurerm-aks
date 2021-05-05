variable "resource_group_name" {
  description = "The name of the resource group containing your Kubernetes cluster"
  type        = string
}

variable "location" {
  description = "Azure region in which to build resources"
  type        = string
}

variable "names" {
  type        = map(string)
  description = "Names to be applied to resources"
}

variable "tags" {
  description = "Tags to be applied to all resources"
  type        = map(string)
}

variable "namespace_name" {
  type        = string
  description = "The name of the namespace to contain cert-manager resources"
  default     = "cert-manager"
}

variable "dns_zone" {
  description = "The name and resource group of the DNS zone associated with your Azure subscription"
  type = object({
    name = string
    resource_group_name = string
  })
  default = {
    name = ""
    resource_group_name = ""
  }
}