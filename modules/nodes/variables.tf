variable "cluster_name" {
  description = "The name of the AKS cluster to create, also used as a prefix in names of related resources."
  type        = string
}

variable "subnets" {
  description = "The primary subnets to be used for the nodes."
  type = object({
    private = object({ id = string })
    public  = object({ id = string })
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

variable "orchestrator_version" {
  description = "Version of Kubernetes used for the Agents"
  type        = string
  default     = null
}

variable "node_pool_defaults" {
  description = "Override default values for the nodes, this will NOT override the values that the module sets directly."
  type        = any
  default     = {}
}

variable "tags" {
  description = "Additional tags for all nodes."
  type        = map(string)
  default     = {}
}

variable "node_pools" {
  description = "Node pool definitions."
  type = list(object({
    name            = string
    single_vmss     = bool
    public          = bool
    vm_size         = string
    os_type         = string
    min_count       = number
    max_count       = number
    labels          = map(string)
    taints          = list(object({
      key    = string
      value  = string
      effect = string
    }))
    tags            = map(string)
  }))

  validation {
    condition     = (length([for pool in var.node_pools : pool.name if(length(pool.name) > 11 && lower(pool.os_type) == "linux")]) == 0)
    error_message = "Node pool name must be fewer than 12 characters for os_type Linux."
  }

  validation {
    condition     = (length([for pool in var.node_pools : pool.name if(length(pool.name) > 5 && lower(pool.os_type) == "windows")]) == 0)
    error_message = "Node pool name must be fewer than 6 characters for os_type Windows."
  }
}