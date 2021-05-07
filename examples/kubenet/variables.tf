variable "external_dns_zones" {
  description = "DNS Zone details for external-dns."
  type = object({
    names               = list(string)
    resource_group_name = string
  })
  default = null
}

variable "rbac_admin_object_ids" {
  description = "Admin group object ids for use with rbac active directory integration."
  type        = map(string) # keys are only for documentation purposes
  default     = {}
}