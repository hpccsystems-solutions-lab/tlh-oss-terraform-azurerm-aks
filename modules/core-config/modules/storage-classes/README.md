# Storage classes submodule

## Description

A simple module that creates [Kubernetes storage classes](https://kubernetes.io/docs/concepts/storage/storage-classes/) in accordance with company standards. It was adapted from the [core-cluster-config project](https://gitlab.b2b.regn.net/kubernetes/reference-code/core-cluster-config/-/tree/cb0b4918eefce482d275bb878ba577378a835fbc/common/storage) for EKS.

Since storage classes are cloud-specific, this module exists only as a submodule of our AKS module contained at the root of this Git repository.

The standard storage classes created by this module are:

- `azure-disk-standard-ssd-retain`: Azure Managed Disk in Standard SSD tier, with reclaim policy "Retain"
- `azure-disk-premium-ssd-retain`: Azure Managed Disk in Premium SSD tier, with reclaim policy "Retain"
- `azure-disk-standard-ssd-delete`: Azure Managed Disk in Standard SSD tier, with reclaim policy "Delete"
- `azure-disk-premium-ssd-delete`: Azure Managed Disk in Premium SSD tier, with reclaim policy "Delete"

**Note**: AKS provisions a set of default storage classes. We've tried to delete them but AKS also uses Kubernetes Reconciliation to restore the default storage classes if they're modified or deleted. One of those storage classes is called `default`, is set as a cluster default, cannot be overridden by any means ([by design](https://docs.microsoft.com/en-us/azure/aks/concepts-storage#storage-classes)), and its main attributes are Azure Managed Disk + Standard SSD tier + reclaim policy = "Delete". 

What that means is if you create a persistent volume (PV) and don't specify a storage class, this default built-in storage class will be applied to your PV, and since its reclaim policy is set to "Delete", the PV will be deleted if the associated persistent volume claim (PVC) is deleted ([reference](https://kubernetes.io/docs/tasks/administer-cluster/change-pv-reclaim-policy/)). This may lead to data loss.

In short, avoid using this built-in default storage class, unless its settings meet your needs and you understand the implications of its reclaim policy being set to "Delete". 

### Adding custom storage classes

You can use the `additional_storage_classes` input variable to create/manage extra classes. The same variable also exists as a top-level input in the AKS module (to which this is a submodule) so you can create your extra classes when creating your cluster, and manage them the same way on an ongoing basis.

Here's an example of how to create a custom storage class:

```hcl
module "aks" {
  source = "github.com/LexisNexis-RBA/terraform-azurerm-aks.git"

  ...
  ...

  additional_storage_classes = {
    special-storage-class = {
      labels              = {
        "test" = "foo"
      }
      annotations         = {}
      storage_provisioner = "kubernetes.io/azure-disk"
      parameters = {
        cachingmode        = "ReadOnly"
        kind               = "Managed"
        storageaccounttype = "StandardSSD_LRS"
      }
      reclaim_policy         = "Retain"
      mount_options          = ["debug"]
      volume_binding_mode    = "WaitForFirstConsumer"
      allow_volume_expansion = true
    }
  }
}
```