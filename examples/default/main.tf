terraform {
  required_version = "~> 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.4"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.13"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.8"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    shell = {
      source  = "scottwinkler/shell"
      version = "~> 1.7"
    }
  }
}

data "azurerm_subscription" "current" {
}

data "azurerm_client_config" "current" {
}

locals {
  tenant_id       = data.azurerm_subscription.current.tenant_id
  subscription_id = data.azurerm_subscription.current.subscription_id
  client_id       = data.azurerm_client_config.current.client_id

  azuread_clusterrole_map = {
    cluster_admin_users  = {}
    cluster_view_users   = {}
    standard_view_users  = {}
    standard_view_groups = {}
  }

  core_services_config = {
    alertmanager = {
      smtp_host = "smtp-hostname.ds:25"
      smtp_from = "cluster-name@lexisnexisrisk.com"
    }

    ingress_internal_core = {
      domain = "example.azure.lnrsg.io"
    }
  }

  k8s_exec_auth_env = {
    AAD_SERVICE_PRINCIPAL_CLIENT_ID     = local.client_id
    AAD_SERVICE_PRINCIPAL_CLIENT_SECRET = ""
  }

  azure_auth_env = {
    AZURE_TENANT_ID       = local.tenant_id
    AZURE_SUBSCRIPTION_ID = local.subscription_id
    AZURE_CLIENT_ID       = local.client_id
    AZURE_CLIENT_SECRET   = ""
  }
}

provider "azurerm" {
  features {}
}

provider "kubernetes" {
  host                   = module.aks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.aks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args        = ["get-token", "--login", "spn", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630", "--environment", "AzurePublicCloud", "--tenant-id", local.tenant_id]
    env         = local.k8s_exec_auth_env
  }
}

provider "kubectl" {
  host                   = module.aks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.aks.cluster_certificate_authority_data)
  load_config_file       = false
  apply_retry_count      = 6

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args        = ["get-token", "--login", "spn", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630", "--environment", "AzurePublicCloud", "--tenant-id", local.tenant_id]
    env         = local.k8s_exec_auth_env
  }
}

provider "helm" {
  host                   = module.aks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.aks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args        = ["get-token", "--login", "spn", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630", "--environment", "AzurePublicCloud", "--tenant-id", local.tenant_id]
    env         = local.k8s_exec_auth_env
  }
}

provider "shell" {
  sensitive_environment = local.azure_auth_env
}

data "http" "my_ip" {
  url = "https://ifconfig.me"
}

resource "random_string" "random" {
  length  = 12
  upper   = false
  number  = false
  special = false
}

module "subscription" {
  source          = "github.com/Azure-Terraform/terraform-azurerm-subscription-data.git?ref=v1.0.0"
  subscription_id = local.subscription_id
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

  location                  = module.metadata.location
  resource_group_name       = module.resource_group.name
  dns_resource_group_lookup = {}

  cluster_name    = random_string.random.result
  cluster_version = local.cluster_version
  network_plugin  = "kubenet"
  sku_tier_paid   = false

  cluster_endpoint_public_access = true
  cluster_endpoint_access_cidrs  = ["0.0.0.0/0"]

  virtual_network_resource_group_name = module.resource_group.name
  virtual_network_name                = module.virtual_network.vnet.name
  subnet_name                         = module.virtual_network.aks.demo.subnets.private.name
  route_table_name                    = module.virtual_network.route_tables.demo.name

  azuread_clusterrole_map = local.azuread_clusterrole_map

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

  core_services_config = local.core_services_config

  tags = module.metadata.tags
}

output "aks_login" {
  value = "az aks get-credentials --name ${module.aks.cluster_name} --resource-group ${module.resource_group.name}"
}
