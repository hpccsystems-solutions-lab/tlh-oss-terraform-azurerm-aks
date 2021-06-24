variable "external_dns_zones" {
  description = "DNS Zone details for external-dns."
  type = object({
    names               = list(string)
    resource_group_name = string
  })
}

variable "azuread_clusterrole_map" {
  description = "Map of Azure AD User and Group Ids to configure in Kubernetes clusterrolebindings"
  type = object(
    {
      cluster_admin_users   = map(string)
      cluster_view_users    = map(string)
      standard_view_users   = map(string)
      standard_view_groups  = map(string)
    }
  )
  default = {
    cluster_admin_users  = {}
    cluster_view_users   = {}
    standard_view_users  = {}
    standard_view_groups = {}
  }
}

variable "config" {
  description = "cluster config"
  type        = map(any)
  default     = {}
}

variable "smtp_host" {
  description = "SMTP host and optionally appended port to send alerts to"
  type = string
}

variable "smtp_from" {
  description = "Email address alerts are sent from"
  type = string
}

variable "alerts_mailto" {
  description = "Email address alerts are sent to"
  type = string
}