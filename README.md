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
| helm | >= 2.0.3 |
| kubectl | >= 1.10.0 |
| kubernetes | >= 2.0.0 |

## Providers

No provider.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| additional\_priority\_classes | A map defining additional priority classes. Refer to [this link](https://github.com/LexisNexis-RBA/terraform-kubernetes-priority-class) for additional information. | <pre>map(object({<br>    description = string<br>    value       = number<br>    labels      = map(string)<br>    annotations = map(string)<br>  }))</pre> | `null` | no |
| additional\_storage\_classes | A map defining additional storage classes. Refer to [this link](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/blob/main/modules/storage-classes/README.md) for additional information. | <pre>map(object({<br>    labels                 = map(string)<br>    annotations            = map(string)<br>    storage_provisioner    = string<br>    parameters             = map(string)<br>    reclaim_policy         = string<br>    mount_options          = list(string)<br>    volume_binding_mode    = string<br>    allow_volume_expansion = bool<br>  }))</pre> | `null` | no |
| cluster\_name | The name of the AKS cluster to create, also used as a prefix in names of related resources. | `string` | n/a | yes |
| cluster\_version | The Kubernetes version to use for the AKS cluster. | `string` | `"1.18"` | no |
| configmaps | Map of configmaps to apply to the cluster, the namespace must already exist or be in the namespaces variable. | <pre>map(object({<br>    name      = string<br>    namespace = string<br>    data      = map(string)<br>  }))</pre> | `{}` | no |
| custom\_route\_table\_ids | Custom route tables used by node pool subnets. | `map(string)` | `{}` | no |
| default\_node\_pool | Override default values for default node pool. | `any` | `{}` | no |
| location | Azure region in which to build resources. | `string` | n/a | yes |
| namespaces | List of namespaces to create on the cluster. | `list(string)` | `[]` | no |
| network\_plugin | Kubernetes Network Plugin (kubenet or AzureCNI) | `string` | `"kubenet"` | no |
| node\_pool\_defaults | Override default values for the node pools, this will NOT override the values that the module sets directly. | `any` | `{}` | no |
| node\_pool\_tags | Additional tags for all workers. | `map(string)` | `{}` | no |
| node\_pool\_taints | Extend or overwrite the default node pool taints to apply based on the node pool tier and/or lifecycle (by default ingress & egress taints are set but these can be overridden). | `map(string)` | `{}` | no |
| node\_pools | Node pool definitions. | <pre>list(object({<br>    name      = string<br>    tier      = string<br>    lifecycle = string<br>    vm_size   = string<br>    os_type   = string<br>    min_count = number<br>    max_count = number<br>    tags      = map(string)<br>  }))</pre> | n/a | yes |
| resource\_group\_name | The name of the Resource Group where the Kubernetes Cluster should exist. | `string` | n/a | yes |
| secrets | Map of secrets to apply to the cluster, the namespace must already exist or be in the namespaces variable. | <pre>map(object({<br>    name      = string<br>    namespace = string<br>    type      = string<br>    data      = map(string)<br>  }))</pre> | `{}` | no |
| subnets | Subnet info. | <pre>object(<br>    {<br>      private = object(<br>        {<br>          id                          = string<br>          resource_group_name         = string<br>          network_security_group_name = string<br>        }<br>      )<br>      public = object(<br>        {<br>          id                          = string<br>          resource_group_name         = string<br>          network_security_group_name = string<br>        }<br>      )<br>    }<br>  )</pre> | n/a | yes |
| tags | Tags to be applied to all resources. | `map(string)` | n/a | yes |
| vm\_types | Extend or overwrite the default vm types map. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| aks\_cluster\_effective\_outbound\_ips\_ids | n/a |
| aks\_cluster\_name | n/a |
| kube\_config | n/a |

<!--- END_TF_DOCS --->
