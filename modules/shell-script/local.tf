locals {
  read_only = var.read_script != null && var.create_script == null && var.update_script == null && var.delete_script == null

  default_read_script = file("${path.module}/scripts/read.sh")
  no_op_script        = file("${path.module}/scripts/no-op.sh")

  environment_variables = merge(var.environment_variables, {
    "SUBSCRIPTION_ID" = var.subscription_id
  })

  create_script = var.create_script != null ? (fileexists(var.create_script) ? file(var.create_script) : var.create_script) : local.no_op_script
  read_script   = var.read_script != null ? (fileexists(var.read_script) ? file(var.read_script) : var.read_script) : local.default_read_script
  update_script = var.update_script != null ? (fileexists(var.update_script) ? file(var.update_script) : var.update_script) : local.no_op_script
  delete_script = var.delete_script != null ? (fileexists(var.delete_script) ? file(var.delete_script) : var.delete_script) : local.no_op_script
}
