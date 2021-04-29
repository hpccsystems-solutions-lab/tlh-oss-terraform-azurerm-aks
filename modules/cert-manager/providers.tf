terraform {
  required_version = ">= 0.14.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.42.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.10"
    }
    # kubernetes = {
    #   source  = "hashicorp/kubernetes"
    #   version = ">= 2.0"
    # }
    # random = {
    #   source  = "hashicorp/random"
    #   version = ">= 3.0.0"
    # }
  }
}