terraform {
  required_version = ">= 1.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.71.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.1.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 1.13"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.10.0"
    }
    time = {
      source = "hashicorp/time"
      version = ">= 0.7.1"
    } 
  }
}
