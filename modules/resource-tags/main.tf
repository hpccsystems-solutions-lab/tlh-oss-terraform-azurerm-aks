resource "shell_script" "default" {
  interpreter = ["/bin/bash", "-c"]

  environment = {
    "SUBSCRIPTION_ID" = var.subscription_id
    "RESOURCE_ID"     = var.resource_id
    "RESOURCE_TAGS"   = local.resource_tags
  }

  lifecycle_commands {
    create = file("${path.module}/scripts/tag.sh")
    read   = file("${path.module}/scripts/read.sh")
    update = file("${path.module}/scripts/tag.sh")
    delete = file("${path.module}/scripts/no-op.sh")
  }
}
