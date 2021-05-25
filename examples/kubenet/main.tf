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
      version = ">=2.0.2"
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

resource "random_password" "admin" {
  length  = 14
  special = true
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
  source = "github.com/Azure-Terraform/terraform-azurerm-resource-group.git?ref=v1.0.0"

  location = module.metadata.location
  names    = module.metadata.names
  tags     = module.metadata.tags
}

module "virtual_network" {
  source = "github.com/Azure-Terraform/terraform-azurerm-virtual-network.git?ref=v2.9.0"

  naming_rules = module.naming.yaml

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  names               = module.metadata.names
  tags                = module.metadata.tags

  enforce_subnet_names = false

  address_space = ["10.1.0.0/22"]

  subnets = {
    aks-private = {
      cidrs                   = ["10.1.0.0/24"]
      configure_nsg_rules     = false
    }
    aks-public = {
      cidrs                   = ["10.1.1.0/24"]
      configure_nsg_rules     = false
    }
  }
}

module "aks" {
  source = "../../"

  cluster_name = random_string.random.result

  location            = module.metadata.location
  tags                = module.metadata.tags
  resource_group_name = module.resource_group.name

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

  subnets = {
    private = {
      id                          = module.virtual_network.subnets["aks-private"].id
      resource_group_name         = module.virtual_network.subnets["aks-private"].resource_group_name
      network_security_group_name = module.virtual_network.subnets["aks-private"].network_security_group_name
    }
    public = {
      id                          = module.virtual_network.subnets["aks-public"].id
      resource_group_name         = module.virtual_network.subnets["aks-public"].resource_group_name
      network_security_group_name = module.virtual_network.subnets["aks-public"].network_security_group_name
    }
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
  azuread_k8s_role_map = {
    cluster_admin_users  = {
      "murtaghj@b2b.regn.net" = "d76d0bbd-3243-47e2-bdff-b4a8d4f2b6c1"
    }
    cluster_view_users = {
      "INS AKS-1 View MID"    = "ca55d5e2-99f6-4047-baef-333313edcf98"
    }
    standard_view_users  = {
      "longm@b2b.regn.net"    = "d64e3f6b-6b16-4235-b4ce-67baa24a593d"
      "patelp@b2b.regn.net"   = "60b29c0c-00bb-48b3-9b9a-cfc3213c5d7d"
    }
    standard_view_groups = {}
  }

  rbac_admin_object_ids = var.rbac_admin_object_ids
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
  destination_address_prefix  = data.kubernetes_service.nginx.status.0.load_balancer.0.ingress.0.ip
  resource_group_name         = module.virtual_network.subnets["aks-public"].resource_group_name
  network_security_group_name = module.virtual_network.subnets["aks-public"].network_security_group_name
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
