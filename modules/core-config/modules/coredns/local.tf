locals {

  cluster_version_minor = tonumber(regex("^1\\.(\\d+)", var.cluster_version)[0])

  custom_config_map_name = "coredns-custom"

  coredns_custom_overwrite = {
    apiVersion = "v1"
    kind       = "ConfigMap"
    metadata = {
      name      = local.custom_config_map_name
      namespace = var.namespace
      labels    = var.labels
    }
  }

  forward_zone_config = <<-EOT
    %{for zone, ip in var.forward_zones}
    ${zone}:53 {
      forward . ${ip}
    }
    %{endfor~}
  EOT

  affinity = {
    nodeAffinity = {
      requiredDuringSchedulingIgnoredDuringExecution = {
        nodeSelectorTerms = [
          {
            matchExpressions = [
              {
                key      = "kubernetes.io/arch"
                operator = "In"
                values = [
                  "amd64",
                  "arm64"
                ]
              }
            ]
          }
        ]
      }
    }

    podAntiAffinity = {
      requiredDuringSchedulingIgnoredDuringExecution = concat([{
        labelSelector = {
          matchLabels = {
            "kubernetes.azure.com/managedby" = "aks"
            "k8s-app"                        = "kube-dns"
          }
        }
        topologyKey = "kubernetes.io/hostname"
        }], local.cluster_version_minor >= 27 ? [] : [{
        labelSelector = {
          matchLabels = {
            "kubernetes.azure.com/managedby" = "aks"
            "k8s-app"                        = "kube-dns"
          }
        }
        topologyKey = "topology.kubernetes.io/zone"
      }])
    }
  }

  topologySpreadConstraints = local.cluster_version_minor >= 27 ? [{
    maxSkew            = 1
    minDomains         = 3
    topologyKey        = "topology.kubernetes.io/zone"
    whenUnsatisfiable  = "DoNotSchedule"
    nodeAffinityPolicy = "Honor"
    nodeTaintsPolicy   = "Honor"
    labelSelector = {
      matchLabels = {
        "kubernetes.azure.com/managedby" = "aks"
        "k8s-app"                        = "kube-dns"
      }
    }
  }] : []

  resource_files = { for x in fileset(path.module, "resources/*.yaml") : basename(x) => "${path.module}/${x}" }
}
