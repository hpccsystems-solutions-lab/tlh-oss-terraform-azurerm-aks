terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.51.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "=2.3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "=2.0.2"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "=2.0.3"
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
  source = "github.com/Azure-Terraform/terraform-azurerm-virtual-network.git?ref=v2.6.0"

  naming_rules = module.naming.yaml

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  names               = module.metadata.names
  tags                = module.metadata.tags

  address_space = ["10.1.0.0/22"]

  subnets = {
    "iaas-private" = {
      cidrs                   = ["10.1.0.0/24"]
      allow_internet_outbound = true # Allow traffic to Internet for image download
    }
    "iaas-public" = {
      cidrs                   = ["10.1.1.0/24"]
      allow_lb_inbound        = true # Allow traffic from Azure Load Balancer to pods
      allow_internet_outbound = true # Allow traffic to Internet for image download
    }
  }
}

module "aks" {
  source = "../../"

  cluster_name = random_string.random.result

  location            = module.metadata.location
  tags                = module.metadata.tags
  resource_group_name = module.resource_group.name

  network_plugin = "azure"

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
      subnet    = "private"
      min_count = "1"
      max_count = "2"
      tags      = {}
    },
    {
      name      = "publ"
      tier      = "ingress"
      lifecycle = "normal"
      vm_size   = "medium"
      os_type   = "Linux"
      subnet    = "public"
      min_count = "1"
      max_count = "2"
      tags      = {}
    },
    {
      name      = "pubw"
      tier      = "ingress"
      lifecycle = "normal"
      vm_size   = "medium"
      os_type   = "Windows"
      subnet    = "public"
      min_count = "1"
      max_count = "2"
      tags      = {}
    }
  ]

  subnets = {
    private = {
      id                          = module.virtual_network.subnets["iaas-private"].id
      resource_group_name         = module.virtual_network.subnets["iaas-private"].resource_group_name
      network_security_group_name = module.virtual_network.subnets["iaas-private"].network_security_group_name
    }
    public = {
      id                          = module.virtual_network.subnets["iaas-public"].id
      resource_group_name         = module.virtual_network.subnets["iaas-public"].resource_group_name
      network_security_group_name = module.virtual_network.subnets["iaas-public"].network_security_group_name
    }
  }
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
  resource_group_name         = module.virtual_network.subnets["iaas-public"].resource_group_name
  network_security_group_name = module.virtual_network.subnets["iaas-public"].network_security_group_name
}

resource "azurerm_network_security_rule" "ingress_public_allow_iis" {
  name                        = "AllowIIS"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "Internet"
  destination_address_prefix  = data.kubernetes_service.iis.status.0.load_balancer.0.ingress.0.ip
  resource_group_name         = module.virtual_network.subnets["iaas-public"].resource_group_name
  network_security_group_name = module.virtual_network.subnets["iaas-public"].network_security_group_name
}

resource "helm_release" "nginx" {
  depends_on = [module.aks]
  name       = "nginx"
  chart      = "./helm_charts/webserver"

  values = [<<-EOT
    name: nginx
    image: nginx:latest
    nodeSelector:
      lnrs.io/tier: ingress
      kubernetes.io/os: linux
    tolerations:
    - key: "ingress"
      operator: "Equal"
      value: "true"
      effect: "NoSchedule"
    EOT
  ]
}

resource "helm_release" "iis" {
  depends_on = [module.aks]
  name       = "iis"
  chart      = "./helm_charts/webserver"

  values = [<<-EOT
    name: iis
    image: microsoft/iis:latest
    nodeSelector:
      lnrs.io/tier: ingress
      kubernetes.io/os: windows
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

data "kubernetes_service" "iis" {
  depends_on = [helm_release.iis] 
  metadata {
    name = "iis"
  }
}

output "nginx_url" {
  value = "http://${data.kubernetes_service.nginx.status.0.load_balancer.0.ingress.0.ip}"
}

output "iis_url" {
  value = "http://${data.kubernetes_service.iis.status.0.load_balancer.0.ingress.0.ip}"
}

output "aks_login" {
  value = "az aks get-credentials --name ${module.aks.aks_cluster_name} --resource-group ${module.resource_group.name}"
}
