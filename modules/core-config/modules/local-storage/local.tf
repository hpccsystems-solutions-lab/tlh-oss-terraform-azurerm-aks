locals {
  namespace = "storage"

  chart_version = "2.5.0"

  chart_values = {
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
        namePattern = "nvme*"
        volumeMode  = "Filesystem"
      },
      {
        blockCleanerCommand = [
          "/scripts/shred.sh",
          "2",
        ]
        fsType      = "ext4"
        hostDir     = "/dev"
        mountDir    = "/mnt/ssd"
        name        = "local-ssd-delete"
        namePattern = "sdb1*"
        volumeMode  = "Filesystem"
      }
    ]

    common = {
      useNodeNameOnly = true
    }

    daemonset = {

      nodeSelector = {
        "lnrs.io/local-storage" = "true"
      }

      podLabels = {
        "lnrs.io/k8s-platform"  = "true"
      }

      resources = {
        requests = {
          cpu    = "50m"
          memory = "32Mi"
        }

        limits = {
          cpu    = "200m"
          memory = "64Mi"
        }
      }

      tolerations = [
        {
          operator = "Exists"
        }
      ]
    }

    serviceMonitor = {
      enabled          = true
      additionalLabels = {
        "lnrs.io/monitoring-platform" = "core-prometheus"
      }
    }
  }
}
