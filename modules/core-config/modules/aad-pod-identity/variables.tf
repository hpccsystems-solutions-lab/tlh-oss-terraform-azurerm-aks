variable "subscription_id" {
  description = "ID of the subscription."
  type        = string
  nullable    = false
}

variable "resource_group_name" {
  description = "Name of the main resource group."
  type        = string
  nullable    = false
}

variable "node_resource_group_name" {
  description = "Name of the resource group containing the nodes."
  type        = string
  nullable    = false
}

variable "cni" {
  description = "Kubernetes CNI."
  type        = string
  nullable    = false
}

variable "kubelet_identity_id" {
  description = "ID of the Kubelet identity."
  type        = string
  nullable    = false
}

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

variable "timeouts" {
  description = "Timeout configuration."
  type = object({
    helm_modify = number
  })
  nullable = false
}

variable "experimental_finalizer_wait" {
  description = "Provide experimental feature flag configuration."
  type        = string
  nullable    = true
}
