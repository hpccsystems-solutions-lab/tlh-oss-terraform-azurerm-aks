## The CRDs are required by a number of other services so are installed separately (core-config/main.tf)
## Provided for future compatibility - not used within this submodule
resource "kubectl_manifest" "crds" {
  for_each = var.skip_crds ? {} : local.crd_files

  yaml_body = file(each.value)

  server_side_apply = true
}

resource "kubectl_manifest" "resources" {
  for_each = local.resource_files

  yaml_body = file(each.value)

  server_side_apply = true

  depends_on = [
    kubectl_manifest.crds
  ]
}

## Managed identity for Grafana to query Azure data sources such as Log Analytics workspaces
module "identity_grafana" {
  source = "../../../identity"

  cluster_name        = var.cluster_name
  identity_name       = local.grafana_identity_name
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  tags                = var.tags
  namespace           = local.namespace

  ## By default Grafana is granted access to the following resources:
  #   - Log Analytics Reader access to the cluster resource group (cluster metrics and diagnostic logs)
  #   - If log_analytics_workspace_id is set as a module variable:
  #     - Reader access to its Resource Group, plus Log Analytics Reader access to the Workspace

  roles = concat(
    [
      {
        role_definition_resource_id = "Log Analytics Reader"
        scope                       = "/subscriptions/${var.azure_subscription_id}/resourceGroups/${var.resource_group_name}"
      }
    ],
    var.log_analytics_workspace_id == null ? [] :
    [{
        role_definition_resource_id = "Reader"
        scope                       = regex("([[:ascii:]]*)(/providers/)", var.log_analytics_workspace_id)[0]
    },
    {
        role_definition_resource_id = "Log Analytics Reader"
        scope                       = var.log_analytics_workspace_id
    }]
  )
}

resource "helm_release" "default" {
  depends_on = [
    module.identity_grafana,
    kubectl_manifest.crds
  ]

  name      = "kube-prometheus-stack"
  namespace = local.namespace

  repository = "https://prometheus-community.github.io/helm-charts/"
  chart      = "kube-prometheus-stack"
  version    = local.chart_version
  skip_crds  = true

  values = [
    yamlencode(local.chart_values)
  ]
}

resource "kubernetes_secret" "grafana_auth" {
  metadata {
    name      = local.grafana_auth_secret_name
    namespace = local.namespace
  }

  type = "Opaque"
  data = {
    "admin-user"     = "admin"
    "admin-password" = var.grafana_admin_password
  }
}
