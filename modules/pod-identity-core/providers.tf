terraform {
  required_version = ">=0.14.8"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.56.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.10.0"
    }
  }
}