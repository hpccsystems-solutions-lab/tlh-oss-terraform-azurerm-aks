terraform {
  required_version = ">=0.14.8"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.56.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.1.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.10.0"
    }
  }
}