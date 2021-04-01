variable "additional_storage_classes" {
  type = map(object({
    labels                 = map(string)
    annotations            = map(string)
    storage_provisioner    = string
    parameters             = map(string)
    reclaim_policy         = string
    mount_options          = list(string)
    volume_binding_mode    = string
    allow_volume_expansion = bool
  }))
  default     = null
  description = "A map defining additional storage classes"
}