variable "podlabels" {
  type = map
  description = "Pod labels for the fluentd pods."
}

variable "additional_env" {
  description = "Additional environment variables."
  type        = list(any)
}

variable "debug" {
  description = "If Fluentd should write all processed log entries to stdout."
  type        = bool
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