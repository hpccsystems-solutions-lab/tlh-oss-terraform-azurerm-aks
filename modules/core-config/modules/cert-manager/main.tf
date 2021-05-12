# Create cert-manager CRDs with kubectl according to this link:
# https://cert-manager.io/docs/installation/kubernetes/#option-1-installing-crds-with-kubectl
# Helm discourages management of CRDs via itself:
# https://helm.sh/docs/chart_best_practices/custom_resource_definitions/
resource "kubectl_manifest" "crds" {
  for_each = fileset(path.module, "crds/customresourcedefinition*.yaml")

  yaml_body = file("${path.module}/${each.value}")
}

# Configure authentication with Azure DNS as described here:
# https://cert-manager.io/docs/configuration/acme/dns01/azuredns/

module "identity" {
  source = "../../../identity"

  identity_name       = "cert-manager"
  cluster_name        = var.cluster_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  namespace                   = var.namespace
  role_definition_resource_id = data.azurerm_role_definition.dns_zone_contributor.id
  scope                       = data.azurerm_dns_zone.dns_zone.id
}

# Now install cert-manager with Helm
resource "helm_release" "main" {
  depends_on = [module.identity]

  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "1.3.1"
  namespace  = var.namespace
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
  aadpodidbinding: ${module.identity.name}"
nodeSelector:
  kubernetes.azure.com/mode: system
tolerations:
  - key: "CriticalAddonsOnly"
    operator: "Exists"
    effect: "NoSchedule"
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
  tolerations:
    - key: "CriticalAddonsOnly"
      operator: "Exists"
      effect: "NoSchedule"
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
  tolerations:
    - key: "CriticalAddonsOnly"
      operator: "Exists"
      effect: "NoSchedule"
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

module "issuer" {
  depends_on = [
    helm_release.main,
    kubectl_manifest.crds
  ]

  source = "./issuer"

  namespace = var.namespace
  azure_environment = var.azure_environment
  azure_subscription_id = var.azure_subscription_id
  dns_zone = var.dns_zone
  letsencrypt_endpoint = local.letsencrypt_endpoint[lower(var.letsencrypt_environment)]
  letsencrypt_email = var.letsencrypt_email
}