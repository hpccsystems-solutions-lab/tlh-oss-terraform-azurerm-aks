variable "cluster_name" {
  description = "The name of the EKS cluster to create, also used as a prefix in names of related resources."
  type        = string
}

variable "subnets" {
  description = "The primary subnets to be used for the cluster and workers."
  type = list(object({
    id    = string
    group = string
  }))
}

variable "availability_zones" {
  description = "Availability zones to use for cluster."
  type        = list(number)
  default     = [1, 2, 3]
}

variable "instance_types" {
  description = "Extend or overwrite the default instance types map."
  type        = map(string)
  default     = {}
}

variable "spot_instance_types" {
  description = "Extend or overwrite the default override instance types for spot groups."
  type        = map(list(string))
  default     = {}
}

variable "instance_eni_count" {
  description = "Extend or overwrite the default maximum network interfaces."
  type        = map(string)
  default     = {}
}

variable "ips_per_eni" {
  description = "Extend or overwrite the default ip addresses per network interface."
  type        = map(string)
  default     = {}
}

variable "worker_group_defaults" {
  description = "Override default values for the workers, this will NOT override the values that the module sets directly."
  type        = any
}

variable "worker_group_taints" {
  description = "Extend or overwrite the default worker taints to apply based on the worker tier and/or lifecycle (by default ingress & egress taints are set but these can be overridden)."
  type        = map(string)
}

variable "worker_group_tags" {
  description = "Additional tags for all workers."
  type        = map(string)
}

variable "default_node_pool" {
  description = "Worker pool used for system services."
  type = object({
    instance_size  = string
    instance_count = number
  })
  default = {
    instance_size  = "medium"
    instance_count = 3
  }
}

variable "worker_groups" {
  description = "Worker group definitions."
  type = list(object({
    name          = string
    tier          = string
    lifecycle     = string
    instance_size = string
    subnet_group  = string
    min_instances = number
    max_instances = number
    tags          = map(string)
  }))
}