locals {
  storage_provisioner = "kubernetes.io/azure-disk"

  standard_storage_class_labels = {
    "lnrs.io/run-level"      = "0"
    "lnrs.io/run-class"      = "default"
    "lnrs.io/cloud-provider" = "azure"
  }

  standard_storage_class_annotations = {
    "fluxcd.io/ignore" = "true"
  }

  default_storage_classes = {
    azure-disk-standard-ssd-retain = {
      labels              = local.standard_storage_class_labels
      annotations         = local.standard_storage_class_annotations
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
      annotations         = local.standard_storage_class_annotations
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
      annotations         = local.standard_storage_class_annotations
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
      annotations         = local.standard_storage_class_annotations
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
  }

  additional_storage_classes = var.additional_storage_classes != null ? var.additional_storage_classes : {}

  merged_storage_classes = merge(local.default_storage_classes, local.additional_storage_classes)
}