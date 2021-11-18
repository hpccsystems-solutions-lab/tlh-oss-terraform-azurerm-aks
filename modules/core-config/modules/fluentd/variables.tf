variable "azure_subscription_id" {
  type        = string
  description = "The GUID of your Azure subscription"

  validation {
    condition     = can(regex("[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}", var.azure_subscription_id))
    error_message = "The \"azure_subscription_id\" variable must be a GUID (xxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)."
  }
}

variable "location" {
  description = "Azure region in which to build resources."
  type        = string
}

variable "cluster_name" {
  description = "The name of the AKS cluster."
  type        = string
}

variable "image_repository" {
  description = "Custom image repository to use for the Fluentd image, image_tag must also be set."
  type        = string
}

variable "image_tag" {
  description = "Custom image tag to use for the Fluentd image, image_repository must also be set."
  type        = string
}

variable "additional_env" {
  description = "Additional environment variables."
  type        = list(any)
}

variable "debug" {
  description = "If Fluentd should write all processed log entries to stdout."
  type        = bool
}

variable "pod_labels" {
  description = "labels to assign to fluentd pods, used for pod-identity and cloud storage integration."
  type        = map(any)
}

variable "filters" {
  description = "The filter config split into multiple strings."
  type        = string
}

variable "routes" {
  description = "The route config, split into multiple strings."
  type        = string
}

variable "outputs" {
  description = "The output config, split into multiple strings."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
}
