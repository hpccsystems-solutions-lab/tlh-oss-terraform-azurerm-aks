locals {
  node_arch = "amd64"

  os_types = {
    "ubuntu"      = "Linux"
    "windows"     = "Windows"
    "windows2019" = "Windows"
    "windows2022" = "Windows"
  }

  os_skus = {
    "ubuntu"      = "Ubuntu"
    "windows"     = null
    "windows2019" = "Windows2019"
    "windows2022" = "Windows2022"
  }

  vm_sizes = {
    "amd64_gp_v1" = {
      "large"    = "Standard_D2s_v4"
      "xlarge"   = "Standard_D4s_v4"
      "2xlarge"  = "Standard_D8s_v4"
      "4xlarge"  = "Standard_D16s_v4"
      "8xlarge"  = "Standard_D32s_v4"
      "12xlarge" = "Standard_D48s_v4"
      "16xlarge" = "Standard_D64s_v4"
    }

    "amd64_gp_v2" = {
      "large"    = "Standard_D2s_v5"
      "xlarge"   = "Standard_D4s_v5"
      "2xlarge"  = "Standard_D8s_v5"
      "4xlarge"  = "Standard_D16s_v5"
      "8xlarge"  = "Standard_D32s_v5"
      "12xlarge" = "Standard_D48s_v5"
      "16xlarge" = "Standard_D64s_v5"
      "24xlarge" = "Standard_D96s_v5"
    }

    "arm64_gp_v1" = {
      "large"    = "Standard_D2ps_v5"
      "xlarge"   = "Standard_D4ps_v5"
      "2xlarge"  = "Standard_D8ps_v5"
      "4xlarge"  = "Standard_D16ps_v5"
      "8xlarge"  = "Standard_D32ps_v5"
      "12xlarge" = "Standard_D48ps_v5"
      "16xlarge" = "Standard_D64ps_v5"
      "24xlarge" = "Standard_D96ps_v5"
    }

    "amd64_gpd_v1" = {
      "large"    = "Standard_D2ds_v4"
      "xlarge"   = "Standard_D4ds_v4"
      "2xlarge"  = "Standard_D8ds_v4"
      "4xlarge"  = "Standard_D16ds_v4"
      "8xlarge"  = "Standard_D32ds_v4"
      "12xlarge" = "Standard_D48ds_v4"
      "16xlarge" = "Standard_D64ds_v4"
    }

    "amd64_gpd_v2" = {
      "large"    = "Standard_D2ds_v5"
      "xlarge"   = "Standard_D4ds_v5"
      "2xlarge"  = "Standard_D8ds_v5"
      "4xlarge"  = "Standard_D16ds_v5"
      "8xlarge"  = "Standard_D32ds_v5"
      "12xlarge" = "Standard_D48ds_v5"
      "16xlarge" = "Standard_D64ds_v5"
      "24xlarge" = "Standard_D96ds_v5"
    }

    "arm64_gpd_v1" = {
      "large"    = "Standard_D2pds_v5"
      "xlarge"   = "Standard_D4pds_v5"
      "2xlarge"  = "Standard_D8pds_v5"
      "4xlarge"  = "Standard_D16pds_v5"
      "8xlarge"  = "Standard_D32pds_v5"
      "12xlarge" = "Standard_D48pds_v5"
      "16xlarge" = "Standard_D64pds_v5"
      "24xlarge" = "Standard_D96pds_v5"
    }

    "amd64_mem_v1" = {
      "large"    = "Standard_E2s_v4"
      "xlarge"   = "Standard_E4s_v4"
      "2xlarge"  = "Standard_E8s_v4"
      "4xlarge"  = "Standard_E16s_v4"
      "8xlarge"  = "Standard_E32s_v4"
      "12xlarge" = "Standard_E48s_v4"
      "16xlarge" = "Standard_E64s_v4"
    }

    "amd64_mem_v2" = {
      "large"    = "Standard_E2s_v5"
      "xlarge"   = "Standard_E4s_v5"
      "2xlarge"  = "Standard_E8s_v5"
      "4xlarge"  = "Standard_E16s_v5"
      "8xlarge"  = "Standard_E32s_v5"
      "12xlarge" = "Standard_E48s_v5"
      "16xlarge" = "Standard_E64s_v5"
      "24xlarge" = "Standard_E96s_v5"
      "26xlarge" = "Standard_E104s_v5"
    }

    "arm64_mem_v1" = {
      "large"   = "Standard_E2ps_v5"
      "xlarge"  = "Standard_E4ps_v5"
      "2xlarge" = "Standard_E8ps_v5"
      "4xlarge" = "Standard_E16ps_v5"
      "8xlarge" = "Standard_E32ps_v5"
    }

    "amd64_memd_v1" = {
      "large"    = "Standard_E2ds_v4"
      "xlarge"   = "Standard_E4ds_v4"
      "2xlarge"  = "Standard_E8ds_v4"
      "4xlarge"  = "Standard_E16ds_v4"
      "8xlarge"  = "Standard_E32ds_v4"
      "12xlarge" = "Standard_E48ds_v4"
      "16xlarge" = "Standard_E64ds_v4"
    }

    "amd64_memd_v2" = {
      "large"    = "Standard_E2ds_v5"
      "xlarge"   = "Standard_E4ds_v5"
      "2xlarge"  = "Standard_E8ds_v5"
      "4xlarge"  = "Standard_E16ds_v5"
      "8xlarge"  = "Standard_E32ds_v5"
      "12xlarge" = "Standard_E48ds_v5"
      "16xlarge" = "Standard_E64ds_v5"
      "24xlarge" = "Standard_E96ds_v5"
      "26xlarge" = "Standard_E104ds_v5"
    }

    "arm64_memd_v1" = {
      "large"   = "Standard_E2pds_v5"
      "xlarge"  = "Standard_E4pds_v5"
      "2xlarge" = "Standard_E8pds_v5"
      "4xlarge" = "Standard_E16pds_v5"
      "8xlarge" = "Standard_E32pds_v5"
    }

    "amd64_cpu_v1" = {
      "large"    = "Standard_F2s_v2"
      "xlarge"   = "Standard_F4s_v2"
      "2xlarge"  = "Standard_F8s_v2"
      "4xlarge"  = "Standard_F16s_v2"
      "8xlarge"  = "Standard_F32s_v2"
      "12xlarge" = "Standard_F48s_v2"
      "16xlarge" = "Standard_F64s_v2"
      "18xlarge" = "Standard_F72s_v2"
    }

    "amd64_stor_v1" = {
      "2xlarge"  = "Standard_L8s_v2"
      "4xlarge"  = "Standard_L16s_v2"
      "8xlarge"  = "Standard_L32s_v2"
      "12xlarge" = "Standard_L48s_v2"
      "16xlarge" = "Standard_L64s_v2"
      "20xlarge" = "Standard_L80s_v2"
    }

    "amd64_stor_v2" = {
      "2xlarge"  = "Standard_L8s_v3"
      "4xlarge"  = "Standard_L16s_v3"
      "8xlarge"  = "Standard_L32s_v3"
      "12xlarge" = "Standard_L48s_v3"
      "16xlarge" = "Standard_L64s_v3"
      "20xlarge" = "Standard_L80s_v3"
    }
  }

  vm_labels = {
    "gp"   = {}
    "gpd"  = { "lnrs.io/local-storage" = "true" }
    "mem"  = {}
    "memd" = { "lnrs.io/local-storage" = "true" }
    "cpu"  = {}
    "stor" = { "lnrs.io/local-storage" = "true" }
  }

  vm_taints = {
    "gp"   = []
    "gpd"  = []
    "mem"  = []
    "memd" = []
    "cpu"  = []
    "stor" = []
  }

  max_pods = {
    azure   = 30
    kubenet = 110
  }

  taint_effects = {
    "NO_SCHEDULE"        = "NoSchedule"
    "NO_EXECUTE"         = "NoExecute"
    "PREFER_NO_SCHEDULE" = "PreferNoSchedule"
  }

  enable_auto_scaling = var.max_capacity > 0 && var.min_capacity != var.max_capacity
}
