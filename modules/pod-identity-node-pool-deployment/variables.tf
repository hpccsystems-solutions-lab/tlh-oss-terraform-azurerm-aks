variable "aks_node_selector" {
  type = map(string)
  default = {}
}

variable "aks_node_tolerations" {
  default = ""
}

