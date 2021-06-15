terraform {
  required_version = ">= 0.14.8"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.57.0"
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
