terraform {
  required_version = ">= 1.3.3, != 1.3.4"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.47.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.8.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.15.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.3.0"
    }
    shell = {
      source  = "scottwinkler/shell"
      version = ">=1.7.10"
    }
    static = {
      source  = "tiwood/static"
      version = ">= 0.1.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">=0.7.2"
    }
  }
}
