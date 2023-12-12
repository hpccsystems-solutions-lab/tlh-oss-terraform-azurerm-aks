resource "time_static" "timestamp" {}

resource "terraform_data" "immutable_inputs" {
  input = {
    cluster_name = var.cluster_name
    cni          = local.cni
    ipv6         = false
    system_nodes = {
      arch         = var.system_nodes.node_arch
      os           = "ubuntu"
      type         = "gp"
      type_variant = "default"
      type_version = var.system_nodes.node_type_version
      size         = var.system_nodes.node_size
    }
  }

  lifecycle {
    ignore_changes = [
      input.cluster_name,
      input.ipv6,
      input.cni,
      input.system_nodes
    ]

    precondition {
      condition     = var.system_nodes.min_capacity % length(local.availability_zones) == 0
      error_message = "Minimum capacity should be divisible by the total availability zones for the Azure region."
    }

    postcondition {
      condition     = var.cluster_name == self.output.cluster_name
      error_message = "Cluster name is immutable."
    }

    postcondition {
      condition     = local.cni == upper(self.output.cni)
      error_message = "Cluster CNI is immutable."
    }

    postcondition {
      condition     = var.system_nodes.node_type_version == self.output.system_nodes.type_version
      error_message = "You can't change the system node type version for an existing cluster."
    }

    postcondition {
      condition     = var.system_nodes.node_size == self.output.system_nodes.size
      error_message = "You can't change the system node size for an existing cluster."
    }

    postcondition {
      condition     = var.system_nodes.node_arch == self.output.system_nodes.arch
      error_message = "You can't change the system node architecture for an existing cluster."
    }
  }
}

module "cluster" {
  source = "./modules/cluster"

  subscription_id                      = local.subscription_id
  location                             = var.location
  resource_group_name                  = var.resource_group_name
  cluster_name                         = var.cluster_name
  cluster_version                      = var.cluster_version
  manual_upgrades                      = local.unsupported.manual_upgrades
  sku_tier                             = var.sku_tier
  fips                                 = var.fips
  cluster_endpoint_access_cidrs        = var.cluster_endpoint_access_cidrs
  cni                                  = local.cni
  subnet_id                            = local.subnet_id
  route_table_id                       = local.route_table_id
  podnet_cidr_block                    = var.podnet_cidr_block
  nat_gateway_id                       = var.nat_gateway_id
  managed_outbound_ip_count            = var.managed_outbound_ip_count
  managed_outbound_ports_allocated     = var.managed_outbound_ports_allocated
  managed_outbound_idle_timeout        = var.managed_outbound_idle_timeout
  #admin_group_object_ids               = var.admin_group_object_ids
  bootstrap_name                       = local.bootstrap_name
  bootstrap_vm_size                    = local.bootstrap_vm_size
  logging                              = local.logging
  storage                              = var.storage
  maintenance                          = var.maintenance
  oms_agent                            = var.experimental.oms_agent
  oms_agent_log_analytics_workspace_id = var.experimental.oms_agent_log_analytics_workspace_id
  windows_support                      = var.experimental.windows_support || local.unsupported.windows_support
  tags                                 = local.tags
  timeouts                             = local.timeouts

  depends_on = [
    terraform_data.immutable_inputs
  ]
}

module "rbac" {
  source = "./modules/rbac"

  azure_env     = local.azure_env
  cluster_id    = module.cluster.id
  rbac_bindings = merge(var.rbac_bindings, { cluster_admin_groups = [] })
  labels        = local.labels

  depends_on = [
    module.cluster
  ]
}

module "node_groups" {
  source = "./modules/node-groups"

  subscription_id      = local.subscription_id
  location             = var.location
  resource_group_name  = var.resource_group_name
  cluster_id           = module.cluster.id
  cluster_name         = var.cluster_name
  cluster_version      = var.cluster_version
  cluster_version_full = module.cluster.cluster_version_full
  cni                  = local.cni
  fips                 = var.fips
  subnet_id            = local.subnet_id
  availability_zones   = local.availability_zones
  bootstrap_name       = local.bootstrap_name
  bootstrap_vm_size    = local.bootstrap_vm_size
  system_nodes         = var.system_nodes
  node_groups          = var.node_groups
  labels               = local.labels
  tags                 = local.tags

  timeouts = local.timeouts

  experimental = var.experimental

  depends_on = [
    module.cluster,
    module.rbac
  ]
}

module "core_config" {
  source = "./modules/core-config"

  azure_env           = local.azure_env
  tenant_id           = local.tenant_id
  subscription_id     = local.subscription_id
  location            = var.location
  resource_group_name = var.resource_group_name

  cluster_name            = var.cluster_name
  cluster_version         = var.cluster_version
  cluster_oidc_issuer_url = module.cluster.oidc_issuer_url
  cni                     = local.cni

  ingress_node_group = module.node_groups.ingress_node_group

  subnet_id          = local.subnet_id
  availability_zones = var.availability_zones

  kubelet_identity_id      = module.cluster.kubelet_identity.object_id
  node_resource_group_name = module.cluster.node_resource_group_name

  dns_resource_group_lookup = var.dns_resource_group_lookup

  monitoring = {
    enabled = !local.unsupported.monitoring_disabled
  }

  logging = local.logging
  storage = var.storage

  core_services_config = local.core_services_config

  labels = local.labels
  tags   = local.tags

  timeouts = local.timeouts

  experimental = var.experimental

  depends_on = [
    module.rbac,
    module.node_groups
  ]
}

module "cluster_version_tag" {
  source = "./modules/resource-tags"

  subscription_id     = local.subscription_id
  resource_group_name = var.resource_group_name
  resource_id         = module.cluster.id
  resource_tags       = { "lnrs.io_terraform-module-version" = local.module_version }

  depends_on = [
    module.cluster,
    module.rbac,
    module.node_groups,
    module.core_config
  ]
}

resource "kubernetes_config_map" "terraform_modules" {
  metadata {
    name      = "terraform-modules"
    namespace = "default"
  }

  lifecycle {
    ignore_changes = [data]
  }

  depends_on = [
    module.cluster,
    module.rbac,
    module.node_groups,
    module.core_config
  ]
}

resource "kubernetes_config_map_v1_data" "terraform_modules" {
  metadata {
    name      = "terraform-modules"
    namespace = "default"
  }

  data = {
    (local.module_name) = local.module_version
  }

  depends_on = [
    module.cluster,
    module.rbac,
    module.node_groups,
    module.core_config,
    kubernetes_config_map.terraform_modules
  ]
}

# This data will be from the first time a module version of v1.13.0 or greater is applied as AKS doesn't capture it's creation date
resource "terraform_data" "creation_metadata" {
  input = {
    timestamp       = time_static.timestamp.rfc3339
    module_version  = local.module_version
    cluster_version = var.cluster_version
  }

  lifecycle {
    ignore_changes = [input]
  }

  depends_on = [
    module.cluster,
    module.rbac,
    module.node_groups,
    module.core_config
  ]
}
