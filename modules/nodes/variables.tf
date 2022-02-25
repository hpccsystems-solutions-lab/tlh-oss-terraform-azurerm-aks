variable "cluster_name" {
  description = "The name of the AKS cluster to create, also used as a prefix in names of related resources."
  type        = string
}

variable "network_plugin" {
  description = "Kubernetes Network Plugin (kubenet or azure)"
  type        = string
}

variable "location" {
  description = "Azure region in which to build resources."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the Resource Group to deploy the AKS cluster service to, must already exist."
  type        = string
}

variable "subnets" {
  description = "The primary subnets to be used for the nodes."
  type = object({
    private = object({ id = string })
    public  = object({ id = string })
  })
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

variable "tags" {
  description = "Additional tags for all nodes."
  type        = map(string)
  default     = {}
}

variable "ingress_node_pool" {
  description = "Specifies if a cluster managed ingress node group is required, if true the system ingress node group will be given instances. If you're using custom ingress controllers this either needs to be set to true or you need to follow the instructions for managing your own ingress node group."
  type        = bool
}

variable "node_pools" {
  description = "Node pool definitions."
  type = list(object({
    name                = string
    single_vmss         = bool
    public              = bool
    placement_group_key = string
    node_type           = string
    node_size           = string
    min_capacity        = number
    max_capacity        = number
    labels              = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
    tags = map(string)
  }))

  validation {
    condition     = (length([for pool in var.node_pools : pool.name if(length(pool.name) > 11 && length(regexall("-win", pool.node_type)) == 0)]) == 0)
    error_message = "Node pool name must be fewer than 12 characters for os_type Linux."
  }

  validation {
    condition     = (length([for pool in var.node_pools : pool.name if(length(pool.name) > 5 && length(regexall("-win", pool.node_type)) > 0)]) == 0)
    error_message = "Node pool name must be fewer than 6 characters for os_type Windows."
  }
}
