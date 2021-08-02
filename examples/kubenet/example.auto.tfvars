azuread_clusterrole_map = {
  cluster_admin_users = {
    iog_dev_write = "8d47c834-0c73-4467-9b79-783c1692c4e5"
  }
  cluster_view_users   = {}
  standard_view_users  = {}
  standard_view_groups = {}
}

core_services_config = {
  alertmanager = {
      smtp_host = "smptp.foo.bar"
      smtp_from = "foo@bar.com"
      receivers = [
        { name = "alerts", 
          email_configs = [
            { to          = "bar@foo.com"
              require_tls = false
            }
          ]
        }
      ]
  }
  external_dns = {
    resource_group_name = "app-dns-prod-eastus2" 
    zones               = ["us-infrastructure-dev.azure.lnrsg.io"]
  }
  cert_manager = {
    letsencrypt_environment = "staging"
    dns_zones = {
      "us-infrastructure-dev.azure.lnrsg.io" = "app-dns-prod-eastus2"
    }
  }
  ingress_internal_core = {
    domain = "us-infrastructure-dev.azure.lnrsg.io"
  }
}
