variable "namespace" {
  description = "Namespace to install the Kubernetes resources into."
  type        = string
}

variable "labels" {
  description = "Labels to be applied to all Kubernetes resources."
  type        = map(string)
}

variable "log_level" {
  description = "Log level."
  type        = string
  nullable    = false
}

variable "ingress_node_group" {
  description = "If an ingress node group is provisioned."
  type        = bool
}

variable "lb_subnet_name" {
  description = "Name of the subnets to create the LB in."
  type        = string
  nullable    = true
}

variable "lb_source_cidrs" {
  description = "CIDR range for LB traffic sources."
  type        = list(string)
  nullable    = false
}

variable "domain" {
  description = "The domain to use for internal ingress resources."
  type        = string
  nullable    = false
}

variable "certificate_issuer_kind" {
  description = "The certificate issuer kind."
  type        = string
  nullable    = true
}

variable "certificate_issuer_name" {
  description = "The certificate issuer."
  type        = string
  nullable    = false
}

variable "timeouts" {
  description = "Timeout configuration."
  type = object({
    helm_modify = number
  })
  nullable = false
}
