# Azure Kubernetes Service (AKS) Terraform Module

## Overview

This module is designed to provide a simple and opinionated way to build standard AKS clusters and is based on the open-source [terraform-azurerm-kubernetes](https://github.com/Azure-Terraform/terraform-azurerm-kubernetes) module. This module takes a set of configuration options and templates out the resulting cluster structure as well as providing the required additional resources.

### Behavior

This module is designed to provide a standard set of defaults for all node pools and optimized instance type selection for a given size.

See [examples](/examples) for general usage and the [documentation index](/docs) for in-depth details for each subsystem or service.

---
