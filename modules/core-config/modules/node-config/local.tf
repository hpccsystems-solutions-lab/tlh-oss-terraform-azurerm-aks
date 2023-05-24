locals {
  chart_version = "0.5.0"

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
            },
            {
              matchExpressions = [
                {
                  key      = "node.lnrs.io/temp-disk"
                  operator = "In"
                  values   = ["true"]
                },
                {
                  key      = "node.lnrs.io/temp-disk-mode"
                  operator = "In"
                  values   = ["HOST_PATH"]
                }
              ]
            }
          ]
        }
      }
    }

    tolerations = [
      {
        operator = "Exists"
      }
    ]
  }
}
