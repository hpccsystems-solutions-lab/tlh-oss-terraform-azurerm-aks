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

variable "manage_config" {
  description = "If the OMS agent ConfigMap should be created with default settings."
  type        = bool
  nullable    = false
}

variable "core_namespaces" {
  description = "Namespaces belonging to the core cluster implementation."
  type        = list(string)
  nullable    = false
}

variable "containerlog_schema_version" {
  description = "Containerlog schema version."
  type        = string
  nullable    = false
}
