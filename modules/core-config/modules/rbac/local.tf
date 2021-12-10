locals {

  ad_member_domains = {
    AzurePublicCloud       = "onmicrosoft.com"
    AzureUSGovernmentCloud = "onmicrosoft.us"
  } 

  upn_regex = "@[a-zA-Z0-9-]+.${local.ad_member_domains[var.azure_environment]}"

  cluster_roles = {
    cluster_admin_users = [ for upn,object_id in var.azuread_clusterrole_map.cluster_admin_users :
      (length(regexall(local.upn_regex, upn)) > 0 ? upn : object_id)
    ]

    cluster_view_users = [ for upn,object_id in var.azuread_clusterrole_map.cluster_view_users :
      (length(regexall(local.upn_regex, upn)) > 0 ? upn : object_id)
    ]

    standard_view_users = [ for upn,object_id in var.azuread_clusterrole_map.standard_view_users :
      (length(regexall(local.upn_regex, upn)) > 0 ? upn : object_id)
    ]

    standard_view_groups = values(var.azuread_clusterrole_map.standard_view_groups)
  }
}