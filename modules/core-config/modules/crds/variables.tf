variable "modules" {
  description = "The modules with CRDs to manage."
  type        = list(string)
  nullable    = false
}
