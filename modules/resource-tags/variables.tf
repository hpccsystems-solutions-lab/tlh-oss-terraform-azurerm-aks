variable "subscription_id" {
  description = "ID of the subscription being used."
  type        = string
  nullable    = false
}

variable "resource_group_name" {
  description = "Name of the Resource Group to deploy the AKS cluster service to, must already exist."
  type        = string
  nullable    = false
}

variable "resource_id" {
  description = "ID of the resource to tag."
  type        = string
  nullable    = false
}

variable "resource_tags" {
  description = "Tags to apply to the resource."
  type        = map(string)
  nullable    = false
}
