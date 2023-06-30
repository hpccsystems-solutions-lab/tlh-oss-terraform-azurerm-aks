locals {
  chart_version = "1.0.0"

  chart_values = {
    common = {
      rbac = {
        create     = true
        pspEnabled = false
      }

      serviceAccount = {
        create = true
      }

      useNodeNameOnly = true
    }

    serviceMonitor = {
      enabled = true
      additionalLabels = {
        "lnrs.io/monitoring-platform" = "true"
      }
    }

    daemonset = {
      podLabels = var.labels

      priorityClassName = "system-node-critical"

      nodeSelector = {
        "kubernetes.io/os"       = "linux"
        "node.lnrs.io/nvme"      = "true"
        "node.lnrs.io/nvme-mode" = "PV"
      }

      tolerations = [
        {
          operator = "Exists"
        }
      ]

      resources = {
        requests = {
          cpu    = "50m"
          memory = "64Mi"
        }

        limits = {
          cpu    = "1000m"
          memory = "64Mi"
        }
      }
    }

    classes = [
      {
        blockCleanerCommand = [
          "/scripts/shred.sh",
          "2",
        ]
        fsType      = "ext4"
        hostDir     = "/dev"
        mountDir    = "/mnt/nvme"
        name        = "local-nvme-delete"
        namePattern = "nvme*n*"
        volumeMode  = "Filesystem"
        storageClass = {
          reclaimPolicy = "Delete"
        }
      }
    ]
  }
}
