# Azure Kubernetes Service (AKS) Terraform Module

## Overview

This module is designed to provide a simple and opinionated way to build standard AKS clusters and is based on the open-source [terraform-azurerm-kubernetes](https://github.com/Azure-Terraform/terraform-azurerm-kubernetes) module. This module takes a set of configuration options and templates out the resulting cluster structure as well as providing the required additional resources.

- _EKS cluster_
  - _OIDC IAM identity provider_
  - _Templated worker groups_
  - _Secondary subnet support_
  - _Custom worker taints (optional)_
- _Flux configuration setup_
  - _Simple bootstrap_
  - _Vault cert integration (optional)_
- _Service IAM roles_
  - _autoscaler_
  - _external-dns_
  - _kube2iam_
  - _logstash_
  - _velero_
- _Backup bucket_
  - _Access policies (optional)_
- _EFS filesystem (optional)_

### Behaviour

This module is designed to provide a standard set of defaults for all node pools and optimized instance type selection for a given size.

---

## Variables
<!--- BEGIN_TF_DOCS --->
<!--- END_TF_DOCS --->