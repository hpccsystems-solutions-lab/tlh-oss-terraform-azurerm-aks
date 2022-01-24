# Upgrade Documentation

- [Upgrade Documentation](#upgrade-documentation)
  - [Upgrading Module Versions](#upgrading-module-versions)
    - [From `v1.0.0-beta.6` to `v1.0.0-beta.7`](#from-v100-beta6-to-v100-beta7)
    - [From `v1.0.0-beta.5` to `v1.0.0-beta.6`](#from-v100-beta5-to-v100-beta6)
    - [From `v1.0.0-beta.4` to `v1.0.0-beta.5`](#from-v100-beta4-to-v100-beta5)
    - [From `v1.0.0-beta.3` to `v1.0.0-beta.4`](#from-v100-beta3-to-v100-beta4)
    - [From `v1.0.0-beta.2` to `v1.0.0-beta.3`](#from-v100-beta2-to-v100-beta3)
    - [From `v1.0.0-beta.1` to `v1.0.0-beta.2`](#from-v100-beta1-to-v100-beta2)
  - [Upgrading Kubernetes Minor Versions](#upgrading-kubernetes-minor-versions)
    - [From `1.20.x` to `1.21.x`](#from-120x-to-121x)
    - [From `1.19.x` to `1.20.x`](#from-119x-to-120x)
  - [Upgrading Kubernetes Major Versions](#upgrading-kubernetes-major-versions)
  - [Deprecated API Migration Guide](#deprecated-api-migration-guide)
  - [Troubleshooting Failed AKS Version Upgrades](#troubleshooting-failed-aks-version-upgrades)

<br>

## Upgrading Module Versions

Below is a list of steps that need to be taken when upgrading from one module version to the next. If you are skipping a version you will need to take the accumulative steps.

### From `v1.0.0-beta.6` to `v1.0.0-beta.7`

`kube-prometheus-stack` - Due to an upgrade of the `kube-state-metrics` chart, removal of its deployment needs to done manually `prior` to upgrading to the `v1.0.0-beta.7` tag. The command below needs to run by a cluster operator with permissions to delete resources.

```console
kubectl delete deployment kube-prometheus-stack-kube-state-metrics -n monitoring
```

`DEPRECATION WARNING` - The `kube-prometheus-stack` helm chart version is upgraded to `30.1.0` which includes `Alertmanager` version `0.23`. Since this upgrade deprecated syntax warning appear in the kube-prometheus-stack-operator pod logs. If you have created your own custom routes this is advanced warning and maybe a good idea to start considering testing the new [matchers](https://prometheus.io/docs/alerting/latest/configuration/#route) configuration.

```console
kubectl logs kube-prometheus-stack-operator-76d7dc6bd-v89j6 -n monitoring

level=warn ts=2022-01-22T08:31:55.923186487Z caller=amcfg.go:1326 component=alertmanageroperator alertmanager=kube-prometheus-stack-alertmanager namespace=monitoring receiver=alerts msg="'matchers' field is using a deprecated syntax which will be removed in future versions" match="unsupported value type" match_re="unsupported value type"
```

`storage-class` - The following storage classes have been migrated to CSI drivers in the 1.21 release - `azure-disk-standard-ssd-retain`, `azure-disk-premium-ssd-retain`, `azure-disk-standard-ssd-delete` and `azure-disk-premium-ssd-delete`. If you created custom storage classes using the kubernetes.io/azure-disk or kubernetes.io/azure-file provisioners they will need to be [migrated to CSI drivers](https://docs.microsoft.com/en-us/azure/aks/csi-storage-drivers#migrating-custom-in-tree-storage-classes-to-csi). Please use `v1.0.0-beta.7` or above to create new 1.21 clusters.

### From `v1.0.0-beta.5` to `v1.0.0-beta.6`

`module` - Providers have now been removed from the module which requires changes to the Terraform workspace. All providers **must** be declared and configuration for the `kubernetes`, `kubectl` & `helm` providers **must** be set. See [examples](/examples) for valid configuration.

### From `v1.0.0-beta.4` to `v1.0.0-beta.5`

`nodepool` - Existing node types must have "-v1" appended to be compatible with beta.5.  Example:  The `v1.0.0-beta.4` node type of "x64-gp" would need to be changed to "x64-gp-v1" to maintain compatibility.  All future node types will be versioned.  See [matrix](./modules/nodes/matrix.md) for node types and details.

Example module input change:

From:

```terraform
module "aks" {

  node_pools = [
    {
      name         = "wnp1" # windows worker node pool 1
      node_type    = "x64-gp-win"
    },
    {
      name         = "inp1" # linux ingress node 1
      node_type    = "x64-gp"
    }
  ]
```

To:

```terraform
module "aks" {

  node_pools = [
    {
      name         = "wnp1" # windows worker node pool 1
      node_type    = "x64-gp-v1-win"
    },
    {
      name         = "inp1" # linux ingress node 1
      node_type    = "x64-gp-v1"
    }
  ]
```


`fluentd` - Changed `filter_config`, `route_config` and `output_config` variables to `filters`, `routes` and `outputs`. If you are currently using `filter_config`, `route_config` or `output_config` in the fluentd section of the core_services_config these will need to be renamed accordingly.

Example core_services_config input change:

From:

```terraform
module "aks" {
  ...
  core_services_config = {
    fluentd = {
      output_config = <<-EOT
        <label @DEFAULT>
          <match kube.var.log.containers.example-**.log>
            @type elasticsearch
            ....
        </label>
      EOT
    }
    ...
  }
}
```

To:

```terraform
module "aks" {
  ...
  core_services_config = {
    fluentd = {
      outputs = <<-EOT
        <label @DEFAULT>
          <match kube.var.log.containers.example-**.log>
            @type elasticsearch
            ....
        </label>
      EOT
    }
    ...
  }
}
```
### From `v1.0.0-beta.3` to `v1.0.0-beta.4`

No additional action required.

### From `v1.0.0-beta.2` to `v1.0.0-beta.3`

No additional action required.

### From `v1.0.0-beta.1` to `v1.0.0-beta.2`

No additional action required.

---

## Upgrading Kubernetes Minor Versions

Below is a list of steps that need to be taken when upgrading from one minor version of kubernetes to the next. For more information on upgrading an AKS cluster please visit the official [Microsoft documentation](https://docs.microsoft.com/en-us/azure/aks/upgrade-cluster)

`Note`: When you upgrade a supported AKS cluster, Kubernetes minor versions cannot be skipped. All upgrades must be performed sequentially by major version number. For example, upgrades between `1.19.x` -> `1.20.x` or `1.20.x` -> `1.21.x` are allowed, however `1.19.x` -> `1.21.x` is not allowed.

To perform an AKS cluster to the next major version of kubernetes you need to change the `cluster_version` input to the module.

So to upgrade from kubernetes version `1.19.x` to `1.20.x` you would make the following change to the `cluster_version` input to the module. This will instantiate a cluster upgrade on the resulting terraform apply.

From:

```terraform
module "aks" {
  cluster_version = "1.20"
```

To:

```terraform
module "aks" {
  cluster_version = "1.21"
```

> **NOTE** - It is important to complete any steps below `prior` to completing a cluster upgrade and any action required for deprecated APIs, please reference the [Deprecated API Migration Guide](#deprecated-api-migration-guide)

### From `1.20.x` to `1.21.x`

`storage-class` - When migrating from a 1.20.x cluster to 1.21.x the storage-classes are migrated from `in-tree` drivers to the new `CSI drivers`. This change requires you to delete the following storage classes `prior` to the upgrade. You can find more details in the storage-class [README.md](/modules/core-config/modules/storage-classes/README.md)

 The command below needs to run by a cluster operator with permissions to delete resources.

```console
kubectl delete storageclass azure-disk-premium-ssd-delete azure-disk-premium-ssd-retain azure-disk-standard-ssd-delete azure-disk-standard-ssd-retain
```

### From `1.19.x` to `1.20.x`

No additional action required.

---

## Upgrading Kubernetes Major Versions

---

## Deprecated API Migration Guide

As the Kubernetes API evolves, APIs are periodically reorganized or upgraded. When APIs evolve, the old API is deprecated and eventually removed. This page contains information you need to know when migrating from deprecated API versions to newer and more stable API versions.

For details please refer to the [official kubernetes documentation](https://kubernetes.io/docs/reference/using-api/deprecation-guide/)

---

## Troubleshooting Failed AKS Version Upgrades

[I'm receiving errors that my cluster is in failed state and upgrading or scaling will not work until it is fixed](https://docs.microsoft.com/en-us/azure/aks/troubleshooting#im-receiving-errors-that-my-cluster-is-in-failed-state-and-upgrading-or-scaling-will-not-work-until-it-is-fixed)

[I'm getting an insufficientSubnetSize error while deploying an AKS cluster with advanced networking. What should I do?](https://docs.microsoft.com/en-us/azure/aks/troubleshooting#im-receiving-errors-when-trying-to-upgrade-or-scale-that-state-my-cluster-is-being-upgraded-or-has-failed-upgrade)

[I'm getting a quota exceeded error during creation or upgrade. What should I do?](https://docs.microsoft.com/en-us/azure/aks/troubleshooting#im-getting-a-quota-exceeded-error-during-creation-or-upgrade-what-should-i-do)
