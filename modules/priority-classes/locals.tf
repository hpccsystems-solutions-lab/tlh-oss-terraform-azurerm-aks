locals {
  standard_priority_class_labels = {
    "lnrs.io/run-level"      = "0"
    "lnrs.io/run-class"      = "mandatory"
    "lnrs.io/cloud-provider" = "all"
  }

  standard_priority_class_annotations = {
    "fluxcd.io/ignore" = "false"
  }

  standard_priority_classes = {
    lnrs-cluster-critical = {
      description = "Used for critical cluster services"
      value = 900000000
      labels = local.standard_priority_class_labels
      annotations = local.standard_priority_class_annotations
    }
    lnrs-node-health = {
      description = "Used for core services that manage cluster node health"
      value = 10000000
      labels = local.standard_priority_class_labels
      annotations = local.standard_priority_class_annotations
    }
    lnrs-platform-critical = {
      description = "Used for high priority platform services"
      value = 800000000
      labels = local.standard_priority_class_labels
      annotations = local.standard_priority_class_annotations
    }
    lnrs-platform-preempt = {
      description = "Used for low priority platform services"
      value = 100
      labels = local.standard_priority_class_labels
      annotations = local.standard_priority_class_annotations
    }
  }

  additional_priority_classes = var.additional_priority_classes != null ? var.additional_priority_classes : {}

  merged_priority_classes = merge(local.standard_priority_classes, local.additional_priority_classes)
}