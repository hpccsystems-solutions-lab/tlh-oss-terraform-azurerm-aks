provider "vault" {
  alias   = "azure_credentials"
  address = var.default_connection_info.vault_address
  token   = var.default_connection_info.vault_token
}

provider "azurerm" {
  tenant_id       = module.default_azure_credentials.tenant_id
  subscription_id = module.default_azure_credentials.subscription_id
  client_id       = module.default_azure_credentials.client_id
  client_secret   = module.default_azure_credentials.client_secret

  features {}
}

provider "azuread" {
  tenant_id     = module.default_azure_credentials.tenant_id
  client_id     = module.default_azure_credentials.client_id
  client_secret = module.default_azure_credentials.client_secret
}

provider "kubernetes" {
  host                   = module.aks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.aks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args        = ["get-token", "--login", "spn", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630", "--environment", "AzurePublicCloud", "--tenant-id", local.azure_auth_env.AZURE_TENANT_ID]
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
    args        = ["get-token", "--login", "spn", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630", "--environment", "AzurePublicCloud", "--tenant-id", local.azure_auth_env.AZURE_TENANT_ID]
    env         = local.k8s_exec_auth_env
  }
}

provider "helm" {
  kubernetes {
    host                   = module.aks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.aks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "kubelogin"
      args        = ["get-token", "--login", "spn", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630", "--environment", "AzurePublicCloud", "--tenant-id", local.azure_auth_env.AZURE_TENANT_ID]
      env         = local.k8s_exec_auth_env
    }
  }

  experiments {
    manifest = true
  }
}

provider "shell" {
  sensitive_environment = local.azure_auth_env
}