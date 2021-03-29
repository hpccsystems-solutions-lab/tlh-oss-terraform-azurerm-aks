resource "random_password" "windows_admin_username" {
  count   = (local.windows_nodes ? 1 : 0)
  length  = 8
  special = false
  number  = false
}

resource "random_password" "windows_admin_password" {
  count   = (local.windows_nodes ? 1 : 0)
  length  = 14
  special = true
}