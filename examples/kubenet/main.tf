terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.57.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">=2.3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 1.13"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">=2.0.3"
    }
  }
  required_version = ">=0.14.8"
}

provider "azurerm" {
  features {}
}

provider "kubernetes" {
  host                   = module.aks.kube_config.host
  client_certificate     = base64decode(module.aks.kube_config.client_certificate)
  client_key             = base64decode(module.aks.kube_config.client_key)
  cluster_ca_certificate = base64decode(module.aks.kube_config.cluster_ca_certificate)
  load_config_file       = "false"
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
  url = "https://ipv4.icanhazip.com"
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
  source = "github.com/Azure-Terraform/terraform-azurerm-virtual-network.git?ref=v2.10.0"

  naming_rules = module.naming.yaml

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  names               = module.metadata.names
  tags                = module.metadata.tags

  enforce_subnet_names = false

  address_space = ["10.1.0.0/22"]

  aks_subnets = {
    private = {
      cidrs = ["10.1.0.0/24"]
      service_endpoints = []
    }
    public = {
      cidrs = ["10.1.1.0/24"]
      service_endpoints = []
    }
    route_table = "default"
  }

  route_tables = {
    default = {
      disable_bgp_route_propagation = true
      use_inline_routes             = false
      routes = {
        internet = {
          address_prefix         = "0.0.0.0/0"
          next_hop_type          = "Internet"
        }
        local-vnet-10-1-0-0-22 = {
          address_prefix         = "10.1.0.0/22"
          next_hop_type          = "vnetlocal"
        }
      }
    }
  }
}

module "aks" {
  source = "../../"

  cluster_name         = random_string.random.result
  location             = module.metadata.location
  tags                 = module.metadata.tags
  resource_group_name  = module.resource_group.name

  external_dns_zones     = var.external_dns_zones
  cert_manager_dns_zones = var.cert_manager_dns_zones

  node_pool_tags     = {}
  node_pool_defaults = {}
  node_pool_taints   = {}

  node_pools = [
    {
      name      = "private"
      tier      = "standard"
      lifecycle = "normal"
      vm_size   = "large"
      os_type   = "Linux"
      min_count = "1"
      max_count = "2"
      labels    = {}
      tags      = {}
    },
    {
      name      = "public"
      tier      = "ingress"
      lifecycle = "normal"
      vm_size   = "medium"
      os_type   = "Linux"
      min_count = "1"
      max_count = "2"
      labels    = {}
      tags      = {}
    }
  ]

  virtual_network = {
    subnets = {
      private = module.virtual_network.aks_subnets.private
      public  = module.virtual_network.aks_subnets.public
    }
    route_table_id = module.virtual_network.aks_subnets.route_table_id
  }

  additional_priority_classes = {
    name-of-priority-class = {
      description = "A description for this priority class"
      value       = 1500 # lower number = lower priority
      labels      = {
        label1 = "foo"
        label2 = "bar"
      }
      annotations = {
        "lnrs.io/foo" = "bar"
        "lnrs.io/baz" = "qux"
      }
    }
  }

  additional_storage_classes = {
    special-storage-class = {
      labels              = {
        "test" = "foo"
      }
      annotations         = {}
      storage_provisioner = "kubernetes.io/azure-disk"
      parameters = {
        cachingmode        = "ReadOnly"
        kind               = "Managed"
        storageaccounttype = "StandardSSD_LRS"
      }
      reclaim_policy         = "Delete"
      mount_options          = ["debug"]
      volume_binding_mode    = "WaitForFirstConsumer"
      allow_volume_expansion = true
    }
  }

  # see /modules/core-config/modules/rbac/README.md
  azuread_clusterrole_map = var.azuread_clusterrole_map
  rbac_admin_object_ids   = var.rbac_admin_object_ids
}

resource "azurerm_network_security_rule" "ingress_public_allow_nginx" {
  name                        = "AllowNginx"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "Internet"
  destination_address_prefix  = data.kubernetes_service.nginx.load_balancer_ingress.0.ip
  resource_group_name         = module.virtual_network.aks_subnets.public.resource_group_name
  network_security_group_name = module.virtual_network.aks_subnets.public.network_security_group_name
}

resource "helm_release" "nginx" {
  depends_on = [module.aks]
  name       = "nginx"
  chart      = "./helm_charts/webserver"

  values = [<<-EOT
    name: nginx
    image: nginx:latest
    dns_name: ${random_string.random.result}.${var.external_dns_zones.names.0}
    nodeSelector:
      lnrs.io/tier: ingress
    tolerations:
    - key: "ingress"
      operator: "Equal"
      value: "true"
      effect: "NoSchedule"
    EOT
  ]
}

data "kubernetes_service" "nginx" {
  depends_on = [helm_release.nginx]
  metadata {
    name = "nginx"
  }
}

output "nginx_url" {
  value = "http://${random_string.random.result}.${var.external_dns_zones.names.0}"
}

output "aks_login" {
  value = "az aks get-credentials --name ${module.aks.aks_cluster_name} --resource-group ${module.resource_group.name}"
}
