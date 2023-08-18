resource "shell_script" "default" {
  count = !local.read_only ? 1 : 0

  interpreter = ["/bin/bash", "-c"]

  triggers = var.triggers

  environment = local.environment_variables

  lifecycle_commands {
    create = var.create_script
    read   = local.read_script
    update = local.update_script
    delete = local.delete_script
  }
}

data "shell_script" "default" {
  count = local.read_only ? 1 : 0

  interpreter = ["/bin/bash", "-c"]

  environment = local.environment_variables

  lifecycle_commands {
    read = local.read_script
  }
}
