resource "shell_script" "default" {
  interpreter = ["/bin/bash", "-c"]

  environment = {
    "CLUSTER_ID"   = local.cluster_id
    "CLUSTER_TAGS" = local.cluster_tags
  }

  lifecycle_commands {
    create = file("${path.module}/scripts/cluster-tag.sh")
    read   = file("${path.module}/scripts/read.sh")
    update = file("${path.module}/scripts/cluster-tag.sh")
    delete = file("${path.module}/scripts/no-op.sh")
  }
}
