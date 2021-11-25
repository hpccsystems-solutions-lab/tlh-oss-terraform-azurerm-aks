locals {
  storage_provisioner = "kubernetes.io/azure-disk"

  standard_storage_class_labels = {
    "lnrs.io/k8s-platform" = "true"
  }

  default_storage_classes = {
    azure-disk-standard-ssd-retain = {
      labels              = local.standard_storage_class_labels
      storage_provisioner = local.storage_provisioner
      parameters = {
        cachingmode        = "ReadOnly"
        kind               = "Managed"
        storageaccounttype = "StandardSSD_LRS"
      }
      reclaim_policy         = "Retain"
      mount_options          = ["debug"]
      volume_binding_mode    = "WaitForFirstConsumer"
      allow_volume_expansion = true
    }
    azure-disk-premium-ssd-retain = {
      labels              = local.standard_storage_class_labels
      storage_provisioner = local.storage_provisioner
      parameters = {
        cachingmode        = "ReadOnly"
        kind               = "Managed"
        storageaccounttype = "Premium_LRS"
      }
      reclaim_policy         = "Retain"
      mount_options          = ["debug"]
      volume_binding_mode    = "WaitForFirstConsumer"
      allow_volume_expansion = true
    }
    azure-disk-standard-ssd-delete = {
      labels              = local.standard_storage_class_labels
      storage_provisioner = local.storage_provisioner
      parameters = {
        cachingmode        = "ReadOnly"
        kind               = "Managed"
        storageaccounttype = "StandardSSD_LRS"
      }
      reclaim_policy         = "Delete"
      mount_options          = ["debug"]
      volume_binding_mode    = "WaitForFirstConsumer"
      allow_volume_expansion = true
    }
    azure-disk-premium-ssd-delete = {
      labels              = local.standard_storage_class_labels
      storage_provisioner = local.storage_provisioner
      parameters = {
        cachingmode        = "ReadOnly"
        kind               = "Managed"
        storageaccounttype = "Premium_LRS"
      }
      reclaim_policy         = "Delete"
      mount_options          = ["debug"]
      volume_binding_mode    = "WaitForFirstConsumer"
      allow_volume_expansion = true
    }
    local-nvme-delete = {
      labels                 = local.standard_storage_class_labels
      storage_provisioner    = "kubernetes.io/no-provisioner"
      parameters             = {}
      reclaim_policy         = "Delete"
      mount_options          = ["debug"]
      volume_binding_mode    = "WaitForFirstConsumer"
      allow_volume_expansion = false
    }
    local-ssd-delete = {
      labels                 = local.standard_storage_class_labels
      storage_provisioner    = "kubernetes.io/no-provisioner"
      parameters             = {}
      reclaim_policy         = "Delete"
      mount_options          = ["debug"]
      volume_binding_mode    = "WaitForFirstConsumer"
      allow_volume_expansion = false
    }
  }
}