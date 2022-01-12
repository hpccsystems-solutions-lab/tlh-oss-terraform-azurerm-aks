terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
    }
    helm = {
      source  = "hashicorp/helm"
    }
  }
}
