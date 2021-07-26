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
  type        = map
}

variable "filter_config" {
  description = "The filter config."
  type        = string
}

variable "route_config" {
  description = "The route config."
  type        = string
}

variable "output_config" {
  description = "The output config."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
}
