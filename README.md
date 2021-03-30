# Azure Kubernetes Service (AKS) Terraform Module

## Overview

This module is designed to provide a simple and opinionated way to build standard AKS clusters and is based on the open-source [terraform-azurerm-kubernetes](https://github.com/Azure-Terraform/terraform-azurerm-kubernetes) module. This module takes a set of configuration options and templates out the resulting cluster structure as well as providing the required additional resources.

### Behavior

This module is designed to provide a standard set of defaults for all node pools and optimized instance type selection for a given size.

---

<!--- BEGIN_TF_DOCS --->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.14.8 |
| azurerm | >= 2.51.0 |

## Providers

No provider.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster\_name | The name of the AKS cluster to create, also used as a prefix in names of related resources. | `string` | n/a | yes |
| cluster\_version | The Kubernetes version to use for the AKS cluster. | `string` | `"1.18"` | no |
| default\_node\_pool | Override default values for default node pool. | `any` | `{}` | no |
| location | Azure region in which to build resources. | `string` | n/a | yes |
| network\_plugin | Kubernetes Network Plugin (kubenet or AzureCNI) | `string` | `"kubenet"` | no |
| node\_pool\_defaults | Override default values for the node pools, this will NOT override the values that the module sets directly. | `any` | `{}` | no |
| node\_pool\_tags | Additional tags for all workers. | `map(string)` | `{}` | no |
| node\_pool\_taints | Extend or overwrite the default node pool taints to apply based on the node pool tier and/or lifecycle (by default ingress & egress taints are set but these can be overridden). | `map(string)` | `{}` | no |
| node\_pools | Node pool definitions. | <pre>list(object({<br>    name      = string<br>    tier      = string<br>    lifecycle = string<br>    vm_size   = string<br>    os_type   = string<br>    subnet    = string<br>    min_count = number<br>    max_count = number<br>    tags      = map(string)<br>  }))</pre> | n/a | yes |
| resource\_group\_name | The name of the Resource Group where the Kubernetes Cluster should exist. | `string` | n/a | yes |
| subnets | Subnet info. | <pre>object(<br>    {<br>      private = object(<br>        {<br>          id                          = string<br>          resource_group_name         = string<br>          network_security_group_name = string<br>        }<br>      )<br>      public = object(<br>        {<br>          id                          = string<br>          resource_group_name         = string<br>          network_security_group_name = string<br>        }<br>      )<br>    }<br>  )</pre> | n/a | yes |
| tags | Tags to be applied to all resources. | `map(string)` | n/a | yes |
| vm\_types | Extend or overwrite the default vm types map. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| aks\_cluster\_name | n/a |
| kube\_config | n/a |

<!--- END_TF_DOCS --->
