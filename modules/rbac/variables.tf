variable "azure_env" {
  description = "Azure cloud environment type."
  type        = string
  nullable    = false
}

variable "cluster_id" {
  description = "ID of the Azure Kubernetes managed cluster."
  type        = string
  nullable    = false
}

variable "labels" {
  description = "Labels to be applied to all Kubernetes resources."
  type        = map(string)
  nullable    = false
}

variable "rbac_bindings" {
  description = "Azure AD user and group IDs to configure in Kubernetes ClusterRoleBindings."
  type = object({
    cluster_admin_users  = optional(map(string), {})
    cluster_admin_groups = optional(list(string), [])
    cluster_view_users   = optional(map(string), {})
    cluster_view_groups  = optional(list(string), [])
  })
  nullable = false
}
