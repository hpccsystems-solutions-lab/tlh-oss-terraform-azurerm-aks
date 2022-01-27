variable "azuread_clusterrole_map" {
  description = "Map of Azure AD User and Group Ids to configure in Kubernetes clusterrolebindings"
  type = object(
    {
      cluster_admin_users  = map(string)
      cluster_view_users   = map(string)
      standard_view_users  = map(string)
      standard_view_groups = map(string)
    }
  )
  default = {
    cluster_admin_users  = {}
    cluster_view_users   = {}
    standard_view_users  = {}
    standard_view_groups = {}
  }
}

variable "core_services_config" {
  description = "Core services config parameters (see docs)"
  type        = any
  default     = {
    alertmanager = {
      smtp_host = "smtp-hostname.ds:25"
      smtp_from = "cluster-name@lexisnexisrisk.com"
    }

    ingress_internal_core = {
      domain    = "example.azure.lnrsg.io"
    }
  }
}
