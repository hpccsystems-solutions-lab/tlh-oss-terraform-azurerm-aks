variable "cluster_name" {
  description = "The name of the EKS cluster to create, also used as a prefix in names of related resources."
  type        = string
}

variable "subnets" {
  description = "The primary subnets to be used for the cluster and workers."
  type = object({
    private = object({id = string})
    public  = object({id = string})
  })
}

variable "availability_zones" {
  description = "Availability zones to use for cluster."
  type        = list(number)
  default     = [1, 2, 3]
}

variable "vm_types" {
  description = "Extend or overwrite the default vm types map."
  type        = map(string)
  default     = {}
}

variable "spot_vm_types" {
  description = "Extend or overwrite the default override vm types for spot groups."
  type        = map(string)
  default     = {}
}

variable "network_plugin" {
  description = "Kubernetes Network Plugin (kubenet or AzureCNI)"
  type        = string
}

variable "node_pool_defaults" {
  description = "Override default values for the workers, this will NOT override the values that the module sets directly."
  type        = any
  default     = {}
}

variable "node_pool_taints" {
  description = "Extend or overwrite the default worker taints to apply based on the worker tier and/or lifecycle (by default ingress & egress taints are set but these can be overridden)."
  type        = map(string)
  default     = {}
}

variable "node_pool_tags" {
  description = "Additional tags for all workers."
  type        = map(string)
  default     = {}
}

variable "default_node_pool" {
  description = "Override default values for default node pool."
  type        = any
  default     = {}
}

variable "node_pools" {
  description = "Node pool definitions."
  type = list(object({
    name      = string
    tier      = string
    lifecycle = string
    vm_size   = string
    os_type   = string
    subnet    = string
    min_count = number
    max_count = number
    tags      = map(string)
  }))
}