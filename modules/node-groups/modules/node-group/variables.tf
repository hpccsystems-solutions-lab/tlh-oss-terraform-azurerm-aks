variable "name" {
  description = "Name of the node group being created."
  type        = string
  nullable    = false
}

variable "cluster_id" {
  description = "ID of the Azure Kubernetes managed cluster."
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
  description = "ID of the subnet to use for the node group."
  type        = string
  nullable    = false
}

variable "availability_zones" {
  description = "Availability zones to use for the node group."
  type        = list(number)
  nullable    = false
}

variable "system" {
  description = "If the node group is of the system or user mode."
  type        = bool
  nullable    = false
}

variable "node_arch" {
  description = "Architecture of the node."
  type        = string
  nullable    = false
}

variable "min_capacity" {
  description = "Minimum number of nodes in the group."
  type        = number
  nullable    = false
}

variable "max_capacity" {
  description = "Maximum number of nodes in the group."
  type        = number
  nullable    = false
}

variable "node_os" {
  description = "The OS to use for the nodes, \"ubuntu\", \"windows2019\" or \"windows2022\" are supported."
  type        = string
  nullable    = false
}

variable "node_type" {
  description = "The type of nodes to create, \"gp\", \"gpd\", \"mem\", \"memd\" & \"stor\" are supported."
  type        = string
  nullable    = false
}

variable "node_type_variant" {
  description = "Variant of the node type."
  type        = string
  nullable    = false
}

variable "node_type_version" {
  description = "Version of the node type to use."
  type        = string
  nullable    = false
}

variable "node_size" {
  description = "The size of nodes to create."
  type        = string
  nullable    = false
}

variable "ultra_ssd" {
  description = "If the node group can use Azure ultra disks."
  type        = bool
  nullable    = false
}

variable "os_disk_size" {
  description = "Size of the OS disk to create, this will be ignored if temp_disk_mode is KUBELET."
  type        = number
  nullable    = false
}

variable "temp_disk_mode" {
  description = "Temp disk mode, this is only valid for node types with a temp disk."
  type        = string
  nullable    = false
}

variable "nvme_mode" {
  description = "The NVMe mode for node group, this is only valid for stor node types."
  type        = string
  nullable    = false
}

variable "os_config" {
  description = "Operating system configuration."
  type = object({
    sysctl = map(any)
  })
  nullable = false
}

variable "proximity_placement_group_id" {
  description = "Proximity placement group ID to use if set."
  type        = string
  nullable    = true
}

variable "max_pods" {
  description = "Maximum number of pods per node, this only apples to clusters using the AzureCNI."
  type        = number
  nullable    = false
}

variable "max_surge" {
  description = "Maximum number or percentage of nodes which will be added to the Node Pool size during an upgrade."
  type        = string
  nullable    = false
}

variable "labels" {
  description = "Labels to set on the nodes."
  type        = map(string)
  nullable    = false
}

variable "taints" {
  description = "Taints to set on the nodes."
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  nullable = false
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
