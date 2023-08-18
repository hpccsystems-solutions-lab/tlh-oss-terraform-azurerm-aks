variable "subscription_id" {
  description = "Azure Subscription ID."
  type        = string
  nullable    = false
}

variable "triggers" {
  description = "Triggers for resource."
  type        = map(any)
  nullable    = false
  default     = {}
}

variable "environment_variables" {
  description = "Environment variables for the script run."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "create_script" {
  description = "Path to or contents of the create script to run."
  type        = string
  nullable    = true
  default     = null
}

variable "read_script" {
  description = "Path to or contents of the read script to run."
  type        = string
  nullable    = true
  default     = null
}

variable "update_script" {
  description = "Path to or contents of the update script to run."
  type        = string
  nullable    = true
  default     = null
}

variable "delete_script" {
  description = "Path to or contents of the delete script to run."
  type        = string
  nullable    = true
  default     = null
}
