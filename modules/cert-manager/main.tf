# Create cert-manager CRDs with kubectl according to this link:
# https://cert-manager.io/docs/installation/kubernetes/#option-1-installing-crds-with-kubectl
# Helm discourages management of CRDs via itself:
# https://helm.sh/docs/chart_best_practices/custom_resource_definitions/
resource "kubectl_manifest" "crds" {
  for_each = fileset(path.module, "crds/customresourcedefinition*.yaml")

  yaml_body = file("${path.module}/${each.value}")
}

# cert-manager will use this identity to manage a DNS zone
resource "azurerm_user_assigned_identity" "main" {
  name                 = "${var.names.product_group}-${var.names.subscription_type}-cert-manager"
  resource_group_name  = var.resource_group_name
  location             = var.location
  tags                 = var.tags
}

# Grant the above UAI access to the specified DNS zone
resource "azurerm_role_assignment" "main" {
  scope                = data.azurerm_dns_zone.dns_zone.id
  role_definition_name = "DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.main.principal_id
}

# Configure authentication with Azure DNS as described here:
# https://cert-manager.io/docs/configuration/acme/dns01/azuredns/
resource "kubectl_manifest" "azure_identity" {
  yaml_body = templatefile("${path.module}/templates/azureidentity.yaml.template",{
    identity_name = azurerm_user_assigned_identity.main.name
    identity_id   = azurerm_user_assigned_identity.main.id
    client_id     = azurerm_user_assigned_identity.main.client_id
  })
}

resource "kubectl_manifest" "azure_identity_binding" {
  depends_on = [kubectl_manifest.azure_identity]

  yaml_body = templatefile("${path.module}/templates/azureidentitybinding.yaml.template",{
    identity_name         = azurerm_user_assigned_identity.main.name
    identity_binding_name = "${azurerm_user_assigned_identity.main.name}-binding"
    selector_label        = azurerm_user_assigned_identity.main.name
  })
}

# Now install cert-manager with Helm
resource "helm_release" "cert_manager" {
  depends_on = [
    kubectl_manifest.crds,
    kubectl_manifest.azure_identity_binding,
  ]

  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "1.3.1"
  namespace  = "cert-manager"
  skip_crds  = true

  max_history = 20
  timeout     = 300

  values = [<<-EOT
---
global:
  priorityClassName: lnrs-platform-critical
installCRDs: false
replicaCount: 1
podLabels:
  aadpodidbinding: ${azurerm_user_assigned_identity.main.name}
nodeSelector:
  kubernetes.azure.com/mode: system
securityContext:
  fsGroup: 65534
extraArgs:
  - --dns01-recursive-nameservers-only
  - --dns01-recursive-nameservers=8.8.8.8:53,1.1.1.1:53
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 256Mi
# Enable this when we have Prometheus up and running in our clusters
# prometheus:
#   enabled: true
#   servicemonitor:
#     enabled: true
#     prometheusInstance: Prometheus
#     targetPort: 9402
#     path: /metrics
#     interval: 60s
#     scrapeTimeout: 30s
#     labels:
#       lnrs.io/monitoring-platform: core-prometheus

cainjector:
  replicaCount: 1
  nodeSelector:
    kubernetes.azure.com/mode: system
  extraArgs:
    - --leader-elect=false
  resources:
    requests:
      cpu: 200m
      memory: 256Mi
    limits:
      cpu: 1000m
      memory: 500Mi

webhook:
  replicaCount: 2
  nodeSelector:
    kubernetes.azure.com/mode: system
  securePort: 10251
  hostNetwork: true
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      cpu: 200m
      memory: 128Mi
EOT
  ]
}