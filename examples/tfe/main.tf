resource "random_string" "random" {
  length  = 12
  upper   = false
  number  = false
  special = false
}

module "default_azure_credentials" {
  providers = { vault = vault.azure_credentials }
  source = "github.com/openrba/terraform-enterprise-azure-credentials.git?ref=v0.3.0"

  connection_info = var.default_connection_info
}

module "subscription" {
  source  = "tfe.lnrisk.io/Infrastructure/subscription-data/azurerm"
  version = "1.0.0"

  subscription_id = data.azurerm_client_config.current.subscription_id
}

module "naming" {
  source  = "tfe.lnrisk.io/Infrastructure/naming/azurerm"
  version = "1.0.29"
}

module "metadata" {
  source  = "tfe.lnrisk.io/Infrastructure/metadata/azurerm"
  version = "1.5.1"

  naming_rules = module.naming.yaml

  market              = "us"
  project             = "https://gitlab.ins.risk.regn.net/example/"
  location            = "eastus2"
  environment         = "sandbox"
  product_name        = "tfedev"
  business_unit       = "iog"
  product_group       = "demo"
  subscription_id     = module.subscription.output.subscription_id
  subscription_type   = "nonprod"
  resource_group_type = "app"
}

module "resource_group" {
  source  = "tfe.lnrisk.io/Infrastructure/resource-group/azurerm"
  version = "2.1.0"

  location = module.metadata.location
  names    = module.metadata.names
  tags     = module.metadata.tags
}

module "virtual_network" {
  source  = "tfe.lnrisk.io/Infrastructure/virtual-network/azurerm"
  version = "6.0.0"

  naming_rules = module.naming.yaml

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  names               = module.metadata.names
  tags                = module.metadata.tags

  enforce_subnet_names = false

  address_space = ["10.1.0.0/22"]

  aks_subnets = {
    demo = {
      subnet_info = {
        cidrs = ["10.1.0.0/24"]
      }
      route_table = {
        disable_bgp_route_propagation = true
        routes = {
          internet = {
            address_prefix = "0.0.0.0/0"
            next_hop_type  = "Internet"
          }
          local-vnet-10-1-0-0-22 = {
            address_prefix = "10.1.0.0/22"
            next_hop_type  = "VnetLocal"
          }
        }
      }
    }
  }
}

module "aks" {
  depends_on = [
    module.virtual_network
  ]

  source = "git@github.com:LexisNexis-RBA/terraform-azurerm-aks.git"

  location            = module.metadata.location
  resource_group_name = module.resource_group.name

  cluster_name    = local.cluster_name
  cluster_version = local.cluster_version
  network_plugin  = "kubenet"
  sku_tier_paid   = false

  cluster_endpoint_public_access = true
  cluster_endpoint_access_cidrs  = ["0.0.0.0/0"]

  virtual_network_resource_group_name = module.resource_group.name
  virtual_network_name                = module.virtual_network.vnet.name
  subnet_name                         = module.virtual_network.aks.demo.subnet.name
  route_table_name                    = module.virtual_network.aks.demo.route_table.name

  dns_resource_group_lookup = { "${local.internal_domain}" = local.dns_resource_group }

  admin_group_object_ids = [var.aad_group_id]

  azuread_clusterrole_map = local.azuread_clusterrole_map

  node_group_templates = local.node_group_templates

  core_services_config = {
    alertmanager = {
      smtp_host = local.smtp_host
      smtp_from = local.smtp_from
      routes    = local.alert_manager_routes
      receivers = local.alert_manager_recievers
    }

    grafana = {
      admin_password = local.grafana_admin_password
    }

    ingress_internal_core = {
      domain           = local.internal_domain
      subdomain_suffix = local.cluster_name_short
      public_dns       = true 
    }
  }

  tags = module.metadata.tags
}