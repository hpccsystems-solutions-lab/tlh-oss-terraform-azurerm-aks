data "azurerm_subscription" "current" {
}

# data "azurerm_client_config" "current" {
# }

locals {
  module_name    = "terraform-azurerm-aks"
  module_version = "v1.20.0-beta.1"

  availability_zones = [1, 2, 3]

  bootstrap_name    = "bootstrap"
  bootstrap_vm_size = "Standard_B2s"

  tenant_id       = data.azurerm_subscription.current.tenant_id
  subscription_id = data.azurerm_subscription.current.subscription_id
  # client_id       = data.azurerm_client_config.current.client_id
  azure_env = startswith(var.location, "usgov") ? "usgovernment" : "public"

  cni = var.experimental.azure_cni_overlay ? "AZURE_OVERLAY" : (var.experimental.windows_support || var.unsupported.windows_support ? "AZURE" : "KUBENET")

  virtual_network_resource_group_id = "/subscriptions/${local.subscription_id}/resourceGroups/${var.virtual_network_resource_group_name}"
  virtual_network_id                = "${local.virtual_network_resource_group_id}/providers/Microsoft.Network/virtualNetworks/${var.virtual_network_name}"
  subnet_id                         = "${local.virtual_network_id}/subnets/${var.subnet_name}"
  route_table_id                    = "${local.virtual_network_resource_group_id}/providers/Microsoft.Network/routeTables/${var.route_table_name}"

  logging = merge(var.logging, {
    enabled = !var.unsupported.logging_disabled
    workloads = {
      core_service_log_level = var.logging.workloads.core_service_log_level

      storage_account = {
        enabled     = var.logging.workloads.storage_account.enabled || var.logging.workloads.storage_account_logs
        id          = var.logging.workloads.storage_account.id
        container   = coalesce(var.logging.workloads.storage_account_container, var.logging.workloads.storage_account.container)
        path_prefix = var.logging.workloads.storage_account_path_prefix != null ? var.logging.workloads.storage_account_path_prefix : var.logging.workloads.storage_account.path_prefix
      }

      loki = var.logging.workloads.loki
    }
  })

  core_services_config = merge(var.core_services_config, {
    fluent_bit_aggregator = {
      enabled            = var.experimental.fluent_bit_aggregator
      replicas_per_zone  = var.experimental.fluent_bit_aggregator_replicas_per_zone
      extra_env          = var.experimental.fluent_bit_aggregator_extra_env
      secret_env         = var.experimental.fluent_bit_aggregator_secret_env
      lua_scripts        = var.experimental.fluent_bit_aggregator_lua_scripts
      raw_filters        = var.experimental.fluent_bit_aggregator_raw_filters
      raw_outputs        = var.experimental.fluent_bit_aggregator_raw_outputs
      resource_overrides = var.experimental.fluent_bit_aggregator_resource_overrides
    }

    oms_agent = {
      enabled                     = var.experimental.oms_agent
      log_analytics_workspace_id  = var.experimental.oms_agent ? var.experimental.oms_agent_log_analytics_workspace_id : null
      manage_config               = var.experimental.oms_agent_create_configmap
      containerlog_schema_version = var.experimental.oms_agent_containerlog_schema_version
    }

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
}
