locals {
  content_hash = length(var.file) > 0 ? filesha256(var.file) : sha256(var.content)

  obj = length(var.file) > 0 ? yamldecode(file(var.file)) : yamldecode(var.content)

  delete_content = yamlencode({
    apiVersion = local.obj.apiVersion
    kind       = local.obj.kind
    metadata   = local.obj.metadata
  })
}