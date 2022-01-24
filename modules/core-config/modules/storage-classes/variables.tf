variable "cluster_version" {
  description = "The Kubernetes minor version to use for the AKS cluster."
  type        = string
  default     = "1.21"

  validation {
    condition     = contains(["1.21", "1.20", "1.19"], var.cluster_version)
    error_message = "This module only supports AKS versions 1.21, 1.20 & 1.19."
  }
}