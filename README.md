# Azure Kubernetes Service (AKS) Terraform Module

## Overview

This module is designed to provide a simple and opinionated way to build standard AKS clusters and is based on the open-source [terraform-azurerm-kubernetes](https://github.com/Azure-Terraform/terraform-azurerm-kubernetes) module. This module takes a set of configuration options and templates out the resulting cluster structure as well as providing the required additional resources.

### Behavior

This module is designed to provide a standard set of defaults for all node pools and optimized instance type selection for a given size.

See [examples](/examples) for general usage and the [documentation index](/docs) for in-depth details for each subsystem or service.

---

<!--- BEGIN_TF_DOCS --->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.14.8 |
| azurerm | >= 2.57.0 |
| helm | >= 2.1.1 |
| kubectl | >= 1.10.0 |
| kubernetes | ~> 1.13 |
| time | >= 0.7.1 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 2.57.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| azuread\_clusterrole\_map | Map of Azure AD User and Group Ids to configure in Kubernetes clusterrolebindings | <pre>object(<br>    {<br>      cluster_admin_users   = map(string)<br>      cluster_view_users    = map(string)<br>      standard_view_users   = map(string)<br>      standard_view_groups  = map(string)<br>    }<br>  )</pre> | <pre>{<br>  "cluster_admin_users": {},<br>  "cluster_view_users": {},<br>  "standard_view_groups": {},<br>  "standard_view_users": {}<br>}</pre> | no |
| cluster\_name | The name of the AKS cluster to create, also used as a prefix in names of related resources. | `string` | n/a | yes |
| cluster\_version | The Kubernetes version to use for the AKS cluster. | `string` | `"1.19"` | no |
| configmaps | Map of configmaps to apply to the cluster, the namespace must already exist or be in the namespaces variable. | <pre>map(object({<br>    name      = string<br>    namespace = string<br>    data      = map(string)<br>  }))</pre> | `{}` | no |
| core\_services\_config | Configuration options for core platform services | `any` | n/a | yes |
| enable\_host\_encryption | Should the nodes in this Node Pool have host encryption enabled? | `bool` | `false` | no |
| location | Azure region in which to build resources. | `string` | n/a | yes |
| namespaces | List of namespaces to create on the cluster. | `list(string)` | `[]` | no |
| network\_plugin | Kubernetes Network Plugin (kubenet or azure) | `string` | `"kubenet"` | no |
| node\_pool\_defaults | Override default values for the node pools, this will NOT override the values that the module sets directly. | `any` | `{}` | no |
| node\_pools | Node pool definitions. | <pre>list(object({<br>    name        = string<br>    single_vmss = bool<br>    public      = bool<br>    vm_size     = string<br>    os_type     = string<br>    min_count   = number<br>    max_count   = number<br>    labels      = map(string)<br>    taints      = list(object({<br>      key    = string<br>      value  = string<br>      effect = string<br>    }))<br>    tags        = map(string)<br>  }))</pre> | n/a | yes |
| pod\_cidr | used for pod IP addresses | `string` | `"100.65.0.0/16"` | no |
| resource\_group\_name | The name of the Resource Group where the Kubernetes Cluster should exist. | `string` | n/a | yes |
| secrets | Map of secrets to apply to the cluster, the namespace must already exist or be in the namespaces variable. | <pre>map(object({<br>    name      = string<br>    namespace = string<br>    type      = string<br>    data      = map(string)<br>  }))</pre> | `{}` | no |
| tags | Tags to be applied to all resources. | `map(string)` | n/a | yes |
| virtual\_network | Virtual network configuration. | <pre>object({<br>    subnets = object({<br>      private = object({ <br>        id = string<br>      })<br>      public = object({<br>        id = string<br>      })<br>    })<br>    route_table_id = string<br>  })</pre> | n/a | yes |
| vm\_types | Extend or overwrite the default vm types map. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| aks\_cluster\_effective\_outbound\_ips\_ids | n/a |
| aks\_cluster\_name | n/a |
| kube\_config | n/a |
| kubelet\_identity | n/a |
| principal\_id | n/a |

<!--- END_TF_DOCS --->
