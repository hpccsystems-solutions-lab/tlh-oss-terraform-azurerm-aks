variable "cluster_name" {
  description = "The name of the cluster that this is being installed into."
  type        = string
}

variable "lb_source_cidrs" {
  description = "CIDR range for LB traffic sources."
  type        = list(string)
}
