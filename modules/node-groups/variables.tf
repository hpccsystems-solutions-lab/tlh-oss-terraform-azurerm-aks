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
