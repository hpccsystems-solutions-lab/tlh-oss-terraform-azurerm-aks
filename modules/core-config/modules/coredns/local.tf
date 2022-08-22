locals {
  custom_config_map_name = "coredns-custom"

  forward_zone_config = <<-EOT
    %{for zone, ip in var.forward_zones}
    ${zone}:53 {
      forward . ${ip}
    }
    %{endfor~}
  EOT

  resource_files = { for x in fileset(path.module, "resources/*.yaml") : basename(x) => "${path.module}/${x}" }
}
