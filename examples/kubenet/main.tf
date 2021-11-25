terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.77"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.5"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
  required_version = "~> 1.0"
}

provider "azurerm" {
  features {}
}

provider "kubernetes" {
  host                   = module.aks.kube_config.host
  client_certificate     = base64decode(module.aks.kube_config.client_certificate)
  client_key             = base64decode(module.aks.kube_config.client_key)
  cluster_ca_certificate = base64decode(module.aks.kube_config.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = module.aks.kube_config.host
    client_certificate     = base64decode(module.aks.kube_config.client_certificate)
    client_key             = base64decode(module.aks.kube_config.client_key)
    cluster_ca_certificate = base64decode(module.aks.kube_config.cluster_ca_certificate)
  }
}

data "http" "my_ip" {
  url = "https://ifconfig.me"
}

data "azurerm_subscription" "current" {
}

resource "random_string" "random" {
  length  = 12
  upper   = false
  number  = false
  special = false
}

module "subscription" {
  source          = "github.com/Azure-Terraform/terraform-azurerm-subscription-data.git?ref=v1.0.0"
  subscription_id = data.azurerm_subscription.current.subscription_id
}

module "naming" {
  source = "github.com/Azure-Terraform/example-naming-template.git?ref=v1.0.0"
}

module "metadata" {
  source = "github.com/Azure-Terraform/terraform-azurerm-metadata.git?ref=v1.5.0"

  naming_rules = module.naming.yaml

  market              = "us"
  project             = "https://github.com/LexisNexis-RBA/terraform-azurerm-aks/tree/master/example"
  location            = "eastus2"
  environment         = "sandbox"
  product_name        = random_string.random.result
  business_unit       = "infra"
  product_group       = "contoso"
  subscription_id     = module.subscription.output.subscription_id
  subscription_type   = "dev"
  resource_group_type = "app"
}

module "resource_group" {
  source = "github.com/Azure-Terraform/terraform-azurerm-resource-group.git?ref=v2.0.0"

  location = module.metadata.location
  names    = module.metadata.names
  tags     = module.metadata.tags
}

module "virtual_network" {
  source = "github.com/Azure-Terraform/terraform-azurerm-virtual-network.git?ref=v5.0.0"

  naming_rules = module.naming.yaml

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  names               = module.metadata.names
  tags                = module.metadata.tags

  enforce_subnet_names = false

  address_space = ["10.1.0.0/22"]

  aks_subnets = {
    demo = {
      private = {
        cidrs = ["10.1.3.0/25"]
      }
      public = {
        cidrs = ["10.1.3.128/25"]
      }
      route_table = {
        disable_bgp_route_propagation = true
        routes = {
          internet = {
            address_prefix = "0.0.0.0/0"
            next_hop_type  = "Internet"
          }
          local-vnet-10-1-0-0-21 = {
            address_prefix = "10.1.0.0/21"
            next_hop_type  = "vnetlocal"
          }
        }
      }
    }
  }
}

module "aks" {
  source = "../../"

  cluster_name        = random_string.random.result
  location            = module.metadata.location
  tags                = module.metadata.tags
  resource_group_name = module.resource_group.name

  ingress_node_pool = true

  node_pools = [
    {
      name         = "workers"
      single_vmss  = false
      public       = false
      node_type    = "x64-gp-v1"
      node_size    = "medium"
      min_capacity = 3
      max_capacity = 6
      taints       = []
      labels = {
        "lnrs.io/tier" = "standard"
      }
      tags = {}
    }
  ]

  virtual_network = module.virtual_network.aks["demo"]

  core_services_config = var.core_services_config

  # see /modules/core-config/modules/rbac/README.md
  azuread_clusterrole_map = var.azuread_clusterrole_map
}

output "aks_login" {
  value = "az aks get-credentials --name ${module.aks.cluster_name} --resource-group ${module.resource_group.name}"
}
