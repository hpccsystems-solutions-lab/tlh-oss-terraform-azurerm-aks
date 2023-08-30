locals {
  chart_version = "0.5.0"

  cluster_version_minor = tonumber(regex("^1\\.(\\d+)", var.cluster_version)[0])

  chart_values = {
    commonLabels = var.labels

    serviceAccount = {
      create         = true
      automountToken = false
    }

    scripts = [
      for x in fileset(path.module, "scripts/*.sh") : {
        name     = trimsuffix(basename(x), ".sh")
        filename = basename(x)
        content  = file("${path.module}/${x}")
      }
    ]

    extraVolumes = [
      {
        name = "host-scripts"
        hostPath = {
          path = "/opt/lnrs-scripts"
          type = "DirectoryOrCreate"
        }
      }
    ]

    hostPID = true

    priorityClassName = "system-node-critical"

    config = {
      image = {
        repository = "cgr.dev/chainguard/bash"
        tag        = "latest"
      }

      securityContext = {
        privileged             = true
        runAsNonRoot           = false
        readOnlyRootFilesystem = true
      }

      command = [
        "bash",
        "-c",
        "/opt/host-exec.sh"
      ]

      extraVolumeMounts = [
        {
          name      = "host-scripts"
          mountPath = "/host-scripts"
        }
      ]

      resources = {
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }
        limits = {
          cpu    = "1000m"
          memory = "128Mi"
        }
      }
    }

    nodeSelector = {
      "kubernetes.io/os" = "linux"
    }

    affinity = {
      nodeAffinity = {
        requiredDuringSchedulingIgnoredDuringExecution = {
          nodeSelectorTerms = [
            {
              matchExpressions = [
                {
                  key      = "node.lnrs.io/nvme"
                  operator = "In"
                  values   = ["true"]
                },
                {
                  key      = "node.lnrs.io/nvme-mode"
                  operator = "In"
                  values   = ["HOST_PATH"]
                }
              ]
              labelSelector = {
                matchLabels = {
                  "app.kubernetes.io/name"     = "node-config"
                  "app.kubernetes.io/instance" = "node-config"
                }
              }
            }

          ]
        }
      }

      podAntiAffinity = {
        requiredDuringSchedulingIgnoredDuringExecution = concat([{
          labelSelector = {
            matchLabels = {
              "app.kubernetes.io/name"     = "node-config"
              "app.kubernetes.io/instance" = "node-config"
            }
          }
          topologyKey = "kubernetes.io/hostname"
          }], local.cluster_version_minor >= 27 ? [] : [{
          labelSelector = {
            matchLabels = {
              "app.kubernetes.io/name"     = "node-config"
              "app.kubernetes.io/instance" = "node-config"
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
          "app.kubernetes.io/name"     = "node-config"
          "app.kubernetes.io/instance" = "node-config"
        }
      }
    }] : []

    tolerations = [
      {
        operator = "Exists"
      }
    ]
  }
}
