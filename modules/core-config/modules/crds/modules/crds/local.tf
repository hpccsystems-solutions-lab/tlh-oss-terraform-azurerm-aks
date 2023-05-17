locals {
  crd_files = { for x in fileset(path.module, "../../../${var.module}/crds/*.yaml") : basename(x) => "${path.module}/${x}" }
}
