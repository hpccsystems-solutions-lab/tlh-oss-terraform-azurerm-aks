resource "kubernetes_priority_class" "global_default" {
  description    = "Default cluster priority class"
  value          = 1000
  global_default = true

  metadata {
    name        = "lnrs-cluster-default"
    labels      = local.standard_priority_class_labels
    annotations = local.standard_priority_class_annotations
  }
}

resource "kubernetes_priority_class" "merged" {
  for_each = local.merged_priority_classes

  description    = each.value["description"]
  value          = each.value["value"]
  global_default = false

  metadata {
    name        = each.key
    labels      = each.value["labels"]
    annotations = each.value["annotations"]
  }
}