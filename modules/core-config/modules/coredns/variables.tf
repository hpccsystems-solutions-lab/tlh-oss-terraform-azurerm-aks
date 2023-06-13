variable "namespace" {
  description = "Namespace to install the Kubernetes resources into."
  type        = string
  nullable    = false
}

variable "labels" {
  description = "Labels to be applied to all Kubernetes resources."
  type        = map(string)
  nullable    = false
}

variable "forward_zones" {
  description = "Map of DNS zones and DNS server IP addresses to forward DNS requests to."
  type        = map(string)
  nullable    = false
}
