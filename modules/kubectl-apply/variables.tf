variable "kubeconfig_path" {
  description = "The path to the kubeconfig file."
  type        = string
}

variable "kubectl_bin" {
  description = "The path to kubectl binary."
  type        = string
}

variable "file" {
  description = "The file to apply with kubectl, this has precident over content."
  type        = string
  default     = ""
}

variable "content" {
  description = "The content to apply with kubectl, file has precident over this."
  type        = string
  default     = ""
}