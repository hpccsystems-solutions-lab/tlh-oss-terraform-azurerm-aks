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
    cluster_admin_users  = map(string)
    cluster_admin_groups = list(string)
    cluster_view_users   = map(string)
    cluster_view_groups  = list(string)
  })
  nullable = false
}
