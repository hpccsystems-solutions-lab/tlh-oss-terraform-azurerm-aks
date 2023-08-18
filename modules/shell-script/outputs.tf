output "values" {
  value = local.read_only ? data.shell_script.default[0].output : shell_script.default[0].output
}
