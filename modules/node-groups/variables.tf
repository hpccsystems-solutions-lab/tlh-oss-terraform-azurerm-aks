variable "subscription_id" {
  description = "ID of the subscription being used."
  type        = string
  nullable    = false
}

variable "location" {
  description = "Azure region in which to build resources."
  type        = string
  nullable    = false
}

variable "resource_group_name" {
  description = "Name of the Resource Group to deploy the AKS cluster service to, must already exist."
  type        = string
  nullable    = false
}

variable "cluster_id" {
  description = "ID of the Azure Kubernetes managed cluster."
  type        = string
  nullable    = false
}

variable "cluster_name" {
  description = "Name of the Azure Kubernetes managed cluster."
  type        = string
  nullable    = false
}

variable "cluster_version" {
  description = "The Kubernetes version of the Azure Kubernetes managed cluster."
  type        = string
  nullable    = false
}

variable "cluster_version_full" {
  description = "The full Kubernetes version of the Azure Kubernetes managed cluster."
  type        = string
  nullable    = false
}

variable "cluster_patch_upgrade" {
  description = "If the cluster upgrade channel should be set to patch instead of node-image."
  type        = bool
  nullable    = false
}

variable "cni" {
  description = "Kubernetes CNI, \"kubenet\" & \"azure\" are supported."
  type        = string
  nullable    = false
}

variable "fips" {
  description = "If true, the cluster will be created with FIPS 140-2 mode enabled; this can't be changed once the cluster has been created."
  type        = bool
  nullable    = false
}

variable "subnet_id" {
  description = "ID of the subnet to use for the node groups."
  type        = string
  nullable    = false
}

variable "availability_zones" {
  description = "Availability zones to use for the node groups."
  type        = list(number)
  nullable    = false
}

variable "bootstrap_name" {
  description = "Name to use for the bootstrap node group."
  type        = string
  nullable    = false
}

variable "bootstrap_vm_size" {
  description = "VM size to use for the bootstrap node group."
  type        = string
  nullable    = false
}

variable "node_groups" {
  description = "Node groups to configure."
  type = map(object({
    node_arch           = string
    node_os             = string
    node_type           = string
    node_type_variant   = string
    node_type_version   = string
    node_size           = string
    ultra_ssd           = bool
    os_disk_size        = number
    temp_disk_mode      = string
    nvme_mode           = string
    placement_group_key = string
    single_group        = bool
    min_capacity        = number
    max_capacity        = number
    max_pods            = number
    max_surge           = string
    labels              = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
    os_config = object({
      sysctl = map(any)
    })
    tags = map(string)
  }))
  nullable = false

  validation {
    condition     = alltrue([for k, v in var.node_groups : length(k) <= 10])
    error_message = "Node group names must be 10 characters or less."
  }

  validation {
    condition     = alltrue([for k, v in var.node_groups : contains(["amd64", "arm64"], v.node_arch)])
    error_message = "Node group architecture must be either \"amd64\" or \"arm64\"."
  }

  validation {
    condition     = alltrue([for k, v in var.node_groups : contains(["ubuntu", "windows2019", "windows2022"], v.node_os)])
    error_message = "Node group OS must be one of \"ubuntu\", \"windows2019\" or \"windows2022\" (EXPERIMENTAL)."
  }

  validation {
    condition     = alltrue([for k, v in var.node_groups : contains(["gp", "gpd", "mem", "memd", "cpu", "stor"], v.node_type)])
    error_message = "Node group type must be one of \"gp\", \"gpd\", \"mem\", \"memd\", \"cpu\" or \"stor\"."
  }

  validation {
    condition     = alltrue([for k, v in var.node_groups : contains(["NONE", "KUBELET", "HOST_PATH"], v.temp_disk_mode)])
    error_message = "Temp disk mode must be one of \"NONE\", \"KUBELET\", \"HOST_PATH\"."
  }

  validation {
    condition     = alltrue([for k, v in var.node_groups : contains(["NONE", "PV", "HOST_PATH"], v.nvme_mode)])
    error_message = "NVMe mode must be one of \"NONE\", \"PV\", \"HOST_PATH\"."
  }

  validation {
    condition     = alltrue([for k, v in var.node_groups : length(coalesce(v.placement_group_key, "_")) <= 11])
    error_message = "Node group placement key must be 11 characters or less."
  }

  validation {
    condition     = alltrue([for k, v in var.node_groups : v.max_pods == -1 || (v.max_pods >= 12 && v.max_pods <= 110)])
    error_message = "Node group max pads must either be -1 or between 12 & 110."
  }

  validation {
    condition     = alltrue([for k, v in var.node_groups : can(tonumber(replace(v.max_surge, "%", "")))])
    error_message = "Node group max surge must either be a number or a percent; e.g. 1 or 10%."
  }
}

variable "labels" {
  description = "Labels to be applied to all Kubernetes resources."
  type        = map(string)
  nullable    = false
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  nullable    = false
}

variable "timeouts" {
  description = "Timeout configuration."
  type = object({
    node_group_create = number
    node_group_update = number
    node_group_read   = number
    node_group_delete = number
  })
  nullable = false
}

variable "experimental" {
  description = "Provide experimental feature flag configuration."
  type = object({
    arm64                = bool
    node_group_os_config = bool
    azure_cni_max_pods   = bool
  })
  nullable = false
}
