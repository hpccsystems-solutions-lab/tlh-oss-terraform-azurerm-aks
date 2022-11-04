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

variable "experimental_use_memory_buffer" {
  description = "Provide experimental feature flag configuration."
  type        = bool
  nullable    = false
}
