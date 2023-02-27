locals {
  resource_tags = join(" ", [for k, v in var.resource_tags : "${k}=${v}"])
}
