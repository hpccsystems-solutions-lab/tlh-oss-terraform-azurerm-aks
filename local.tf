data "azurerm_subscription" "current" {
}

# data "azurerm_client_config" "current" {
# }

locals {
  module_name    = "terraform-azurerm-aks"
  module_version = "v1.16.0-beta.1"

  # az aks get-versions --location eastus --output table
  # az aks get-versions --location westeurope --output table
  # https://releases.aks.azure.com/webpage/index.html
  cluster_version_full_lookup = {
    westeurope = {
      "1.26" = "1.26.3"
      "1.25" = "1.25.6"
      "1.24" = "1.24.10"
    }

    eastus = {
      "1.26" = "1.26.3"
      "1.25" = "1.25.6"
      "1.24" = "1.24.10"
    }

    centralus = {
      "1.26" = "1.26.3"
      "1.25" = "1.25.6"
      "1.24" = "1.24.10"
    }

    usgovvirginia = {
      "1.26" = "1.26.3"
      "1.25" = "1.25.6"
      "1.24" = "1.24.10"
    }

    usgovtexas = {
      "1.26" = "1.26.3"
      "1.25" = "1.25.6"
      "1.24" = "1.24.10"
    }
  }

  availability_zones = [1, 2, 3]

  bootstrap_name    = "bootstrap"
  bootstrap_vm_size = "Standard_B2s"

  cluster_version_full = try(local.cluster_version_full_lookup[var.location][var.cluster_version], local.cluster_version_full_lookup["westeurope"][var.cluster_version])

  tenant_id       = data.azurerm_subscription.current.tenant_id
  subscription_id = data.azurerm_subscription.current.subscription_id
  # client_id       = data.azurerm_client_config.current.client_id

  virtual_network_resource_group_id = "/subscriptions/${local.subscription_id}/resourceGroups/${var.virtual_network_resource_group_name}"
  virtual_network_id                = "${local.virtual_network_resource_group_id}/providers/Microsoft.Network/virtualNetworks/${var.virtual_network_name}"
  subnet_id                         = "${local.virtual_network_id}/subnets/${var.subnet_name}"
  route_table_id                    = "${local.virtual_network_resource_group_id}/providers/Microsoft.Network/routeTables/${var.route_table_name}"

  core_services_config = merge(var.core_services_config, {
    fluent_bit_aggregator = {
      enabled           = var.experimental.fluent_bit_aggregator
      replicas_per_zone = var.experimental.fluent_bit_aggregator_replicas_per_zone
      extra_env         = var.experimental.fluent_bit_aggregator_extra_env
      secret_env        = var.experimental.fluent_bit_aggregator_secret_env
      lua_scripts       = var.experimental.fluent_bit_aggregator_lua_scripts
      raw_filters       = var.experimental.fluent_bit_aggregator_raw_filters
      raw_outputs       = var.experimental.fluent_bit_aggregator_raw_outputs
    }

    loki = {
      enabled   = var.experimental.loki
      node_logs = var.experimental.systemd_logs_loki
    }

    oms_agent = {
      enabled                     = var.experimental.oms_agent
      log_analytics_workspace_id  = var.experimental.oms_agent ? var.experimental.oms_agent_log_analytics_workspace_id : null
      manage_config               = var.experimental.oms_agent_create_configmap
      containerlog_schema_version = var.experimental.oms_agent_containerlog_schema_version
    }
  })

  maintenance = merge(var.maintenance, {
    utc_offset = var.maintenance.utc_offset != null ? var.maintenance.utc_offset : format("%+03g:00", coalesce(var.maintenance_window_offset, 0))

    basic = length(var.maintenance_window_allowed_days) > 0 || length(var.maintenance_window_allowed_hours) > 0 ? [for d in coalescelist(var.maintenance_window_allowed_days, ["TUESDAY", "WEDNESDAY", "THURSDAY"]) : {
      day   = upper(d)
      hours = coalescelist(var.maintenance_window_allowed_hours, [10, 11, 12, 13, 14, 15])
    }] : []

    not_allowed = length(var.maintenance.not_allowed) > 0 ? var.maintenance.not_allowed : var.maintenance_window_not_allowed
  })

  labels = {
    "lnrs.io/k8s-platform" = "true"
  }

  tags = merge(var.tags, {
    "lnrs.io_terraform"                         = "true"
    "lnrs.io_terraform-module"                  = local.module_name
    "kubernetes.io_cluster_${var.cluster_name}" = "owned"
    "lnrs.io_k8s-platform"                      = "true"
  })

  # Timeouts are in seconds for compatibility with all use cases and must be converted to string format to support Terraform resource timeout blocks
  # https://www.terraform.io/language/resources/syntax#operation-timeouts
  timeouts = {
    cluster_create    = 5400
    cluster_update    = 5400
    cluster_read      = 300
    cluster_delete    = 5400
    node_group_create = 3600
    node_group_update = 3600
    node_group_read   = 300
    node_group_delete = 3600
    helm_modify       = 600
  }

  cni       = var.experimental.windows_support ? "azure" : "kubenet"
  azure_env = startswith(var.location, "usgov") ? "usgovernment" : "public"
}
