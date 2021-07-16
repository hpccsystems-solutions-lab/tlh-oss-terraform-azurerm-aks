terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.67.0"
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
  source = "github.com/Azure-Terraform/terraform-azurerm-virtual-network.git?ref=v4.0.1"

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
      service_endpoints = ["Microsoft.Storage"]
    }
    route_table = {
      disable_bgp_route_propagation = true
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

  node_pool_defaults = {}

  node_pools = [
    {
      name        = "ingress"
      single_vmss = true
      public      = true
      vm_size     = "medium"
      os_type     = "Linux"
      min_count   = "1"
      max_count   = "2"
      taints = [{
        key    = "ingress"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]
      labels = {
        "lnrs.io/tier" = "ingress"
      }
      tags        = {}
    },
    {
      name        = "workers"
      single_vmss = false
      public      = false
      vm_size     = "large"
      os_type     = "Linux"
      min_count   = "1"
      max_count   = "2"
      taints      = []
      labels = {
        "lnrs.io/tier" = "standard"
      }
      tags        = {}
    }
  ]

  virtual_network = module.virtual_network.aks

  core_services_config = merge({
    alertmanager = {
      smtp_host = var.smtp_host
      smtp_from = var.smtp_from
      receivers = [{ name = "alerts", email_configs = [{ to = var.alerts_mailto, require_tls = false }]}]
    }

    internal_ingress = {
      domain    = "private.zone.azure.lnrsg.io"
    }

    cert_manager = {
      letsencrypt_environment = "staging"
    }
  }, var.config)

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
}

module "storage_account" {
  source = "github.com/Azure-Terraform/terraform-azurerm-storage-account.git?ref=v0.5.0"

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  names               = module.metadata.names
  tags                = module.metadata.tags

  account_kind     = "StorageV2"
  replication_type = "LRS"

  access_list = {
    "my_ip" = chomp(data.http.my_ip.body)
  }

  service_endpoints = {
    "aks-public" = module.virtual_network.aks.subnets.public.id
  }
}

resource "azurerm_storage_container" "content" {
  name                  = "content"
  storage_account_name  = module.storage_account.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "custom" {
  name                   = "custom.html"
  storage_account_name   = module.storage_account.name
  storage_container_name = azurerm_storage_container.content.name
  type                   = "Block"
  source_content         = <<-EOT
<!DOCTYPE html>
<html>
<body>
<h1>Custom HTML</h1>
<p>This file was copied from an Azure Blob.</p>
</body>
</html>
EOT
}

resource "azurerm_user_assigned_identity" "nginx" {
  name                = "${module.metadata.names.product_group}-${module.metadata.names.subscription_type}-nginx"
  resource_group_name = module.resource_group.name
  location            = module.metadata.location
  tags                = module.metadata.tags
}

resource "azurerm_role_assignment" "blob_reader" {
  depends_on = [ azurerm_user_assigned_identity.nginx ]

  scope                = azurerm_storage_container.content.resource_manager_id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_user_assigned_identity.nginx.principal_id
}

resource "helm_release" "nginx" {
  depends_on = [module.aks]
  name       = "nginx"
  chart      = "./helm_charts/webserver"
  timeout = 180

  values = [<<-EOT
    name: nginx
    image: nginx:latest
    dns_name: ${random_string.random.result}.${var.config.external_dns.zones.0}
    nodeSelector:
      lnrs.io/tier: ingress
    tolerations:
    - key: "ingress"
      operator: "Equal"
      value: "true"
      effect: "NoSchedule"
    namespace: default
    azureIdentity:
      name: ${azurerm_user_assigned_identity.nginx.name}
      type: 0
      resourceID: ${azurerm_user_assigned_identity.nginx.id}
      clientID: ${azurerm_user_assigned_identity.nginx.client_id}
    azureIdentityBinding:
      name: ${azurerm_user_assigned_identity.nginx.name}-binding
      selector: ${azurerm_user_assigned_identity.nginx.name}
    blob_url: ${azurerm_storage_blob.custom.url}
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
  value = "http://${random_string.random.result}.${var.config.external_dns.zones.0}"
}

output "aks_login" {
  value = "az aks get-credentials --name ${module.aks.aks_cluster_name} --resource-group ${module.resource_group.name}"
}
