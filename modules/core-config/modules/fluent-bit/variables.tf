variable "loki_enabled" {
  description = "If Loki is enabled in the cluster."
  type        = bool
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
}