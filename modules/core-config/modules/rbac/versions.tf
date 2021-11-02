terraform {
  required_version = ">= 0.14.8"

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.12.1"
    }
  }
}