variable "kubectl_version" {
  description = "Kubectl version to use for local_exec commands (leave empty for latest)."
  type        = string
  default     = null
}

variable "directory" {
  description = "Directory where kubectl should be installed."
  type        = string
}

variable "kubeconfig" {
  description = "Kubeconfig content."
  type        = string
}