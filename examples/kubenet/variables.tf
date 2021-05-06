variable "dns_zone" {
   description = "DNS Zone details for external-dns."
   type        =  object({
     name = string
     resource_group_name = string
   })
}

variable "rbac_admin_object_ids" {
  description = "Admin group object ids for use with rbac active directory integration."
  type        = map(string) # keys are only for documentation purposes
  default     = {}
}