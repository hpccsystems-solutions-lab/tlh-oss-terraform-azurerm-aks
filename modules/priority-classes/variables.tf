variable "additional_priority_classes" {
  type        = map(object({
    description = string
    value = number
    labels = map(string)
    annotations = map(string)
  }))
  default     = null
  description = "A map defining additional priority classes"
}