variable "pipeline_tags" {
  description = "Tags for the market."
  type        = map(string)
  default     = {}
}

variable "market_tags" {
  description = "Tags for the market."
  type        = map(string)
  default     = {}
}

variable "account_tags" {
  description = "Tags for the account."
  type        = map(string)
  default     = {}
}

variable "project_tags" {
  description = "Tags for the project."
  type        = map(string)
  default     = {}
}

# tflint-ignore: terraform_unused_declarations
variable "protected" {
  description = "If the pipeline should be protected."
  type        = bool
  default     = false
}
