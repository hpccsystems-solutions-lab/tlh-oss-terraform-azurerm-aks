locals {
  account_code = ""
  # example: "us-infra-dev"

  cluster_name = ""
  # example: "us-infra-dev-aks-000"

  cluster_version = ""
  # example : "1.21"

  cluster_admin_users = {}
  # example: { "user@risk.regn.net" = "aaa-bbb-ccc-ddd-eee" }

  internal_domain = ""
  # example: "us-infrastructure-dev.azure.lnrsg.io"

  dns_resource_group = ""
  # example: "app-dns-prod-eastus2"

  smtp_host = ""
  # example: "appmail-test.risk.regn.net"

  smtp_from = ""
  # example: "${local.cluster_name}@risk.regn.net"

  grafana_admin_password = ""
  # example: data.vault_generic_secret.default.data["grafana_admin_password"]

  cluster_name_short = trimprefix(local.cluster_name, "${local.account_code}-")

  k8s_exec_auth_env = {
    AAD_SERVICE_PRINCIPAL_CLIENT_ID     = module.default_azure_credentials.client_id
    AAD_SERVICE_PRINCIPAL_CLIENT_SECRET = module.default_azure_credentials.client_secret
  }

  azure_auth_env = {
    AZURE_TENANT_ID       = module.default_azure_credentials.tenant_id
    AZURE_SUBSCRIPTION_ID = module.default_azure_credentials.subscription_id
    AZURE_CLIENT_ID       = module.default_azure_credentials.client_id
    AZURE_CLIENT_SECRET   = module.default_azure_credentials.client_secret
  }

  alert_manager_recievers = []
  alert_manager_routes    = []

  azuread_clusterrole_map = {
    cluster_admin_users  = local.cluster_admin_users
    cluster_view_users   = {}
    standard_view_users  = {}
    standard_view_groups = {}
  }

  admin_group_object_ids = [var.aad_group_id]

  node_group_templates = [
    {
      name                = "workers"
      node_os             = "ubuntu"
      node_type           = "gp"
      node_type_version   = "v1"
      node_size           = "large"
      single_group        = false
      min_capacity        = 0
      max_capacity        = 18
      placement_group_key = null
      labels = {
        "lnrs.io/tier" = "standard"
      }
      taints = []
      tags   = {}
    }
  ]
}
