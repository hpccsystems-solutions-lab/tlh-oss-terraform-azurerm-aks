# Storage classes submodule

## Description

A module to create [Kubernetes storage classes](https://kubernetes.io/docs/concepts/storage/storage-classes/) in accordance with company standards.

> as storage classes are cloud-specific, this module exists only as a submodule of this AKS module

Storage classes created by this module:

- `azure-disk-standard-ssd-retain`: Azure Managed Disk in Standard SSD tier, with reclaim policy "Retain"
- `azure-disk-premium-ssd-retain`: Azure Managed Disk in Premium SSD tier, with reclaim policy "Retain"
- `azure-disk-standard-ssd-delete`: Azure Managed Disk in Standard SSD tier, with reclaim policy "Delete"
- `azure-disk-premium-ssd-delete`: Azure Managed Disk in Premium SSD tier, with reclaim policy "Delete"
- `local-nvme-delete`: Provisions volumes on disks matching "nvme*"
- `local-ssd-delete`: Provisions volumes on disks matching "sdb1*"

**Note**: AKS provisions a set of default storage classes which are protected by a Kubernetes Reconciliation loop. One of those storage classes is called `default`, is set as a cluster default, cannot be overridden by any means ([by design](https://docs.microsoft.com/en-us/azure/aks/concepts-storage#storage-classes)), and its main attributes are Azure Managed Disk + Standard SSD tier + reclaim policy = "Delete". 

What that means is if you create a persistent volume (PV) and don't specify a storage class, this default built-in storage class will be applied to your PV, and since its reclaim policy is set to "Delete", the PV will be deleted if the associated persistent volume claim (PVC) is deleted ([reference](https://kubernetes.io/docs/tasks/administer-cluster/change-pv-reclaim-policy/)). This may lead to data loss.

In short, avoid using this built-in default storage class, unless its settings meet your needs and you understand the implications of its reclaim policy being set to "Delete". 
