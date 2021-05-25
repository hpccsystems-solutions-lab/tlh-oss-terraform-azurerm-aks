variable "cluster_id" {
  description = "The unique identifier of the AKS cluster."
  type        = string
}

variable "azuread_k8s_role_map" {
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
