# Azure Kubernetes Service (AKS) Terraform Module

## Overview

This module provides a simple and opinionated way to build a standard [Azure AKS](https://azure.microsoft.com/en-us/products/kubernetes-service/#overview) Kubernetes cluster with a common set of services. By providing a standard Kubernetes pattern we reduce the cognitive load on the teams who need to run these clusters and benefit from an economy of scale. The module API and behaviour is designed (as far as possible) to be common across all RSG Kubernetes implementations which allows for greater portability between implementations.

The module follows a [SemVer](https://semver.org/) versioning strategy and is packaged and released as a tested pattern with a corresponding [support policy](#support-policy). For detailed documentation and more information on the Kubernetes ecosystem please visit the [RSG Kubernetes Documentation](https://legendary-doodle-a57ed2c8.pages.github.io/).

---

## Support Policy

Support for this module **isn't** operational; by using this module you're agreeing that operational support will be provided to your end-users by your cluster operators and that the core engineering team will only interact with these operational teams.

At any given time the last 3 minor versions of this module are supported; this means these versions will get patch fixes for critical bugs, core service CVEs & AKS patches. It is the module operators and end-users responsibility to make sure that clusters are running the latest patch version of a supported version, failure to do this in a timely manner could expose the cluster to significant risks.

> **Info**
> If there have been versions `v3.0.0`, `v3.1.0`, `v3.1.1`, `v3.2.0`, `v3.3.0` & `v3.3.1` released then the supported versions would be `v3.1.1`, `v3.2.0` & `v3.3.1` (latest patch versions of the last 3 minor versions).

### General Help

Before using this module, the whole README should be read and you should be familiar with the concepts in the [RSG Kubernetes Documentation](https://legendary-doodle-a57ed2c8.pages.github.io/); some common questions are answered in the module [FAQ](./FAQ.md).

If you have unanswered questions after reading the documentation, please visit [RSG Kubernetes Discussions](https://github.com/LexisNexis-RBA/rsg-kubernetes/discussions) where you can either join an existing discussion or start your own.

### Issues

The core engineering team are responsible for triaging bugs in a timely manner and providing fixes either in the next minor release or as a patch to supported versions. The following constraints need to be met before an issue can be reported, failure to meet these may result in the issue being closed if not addressed promptly.

- The reporter **must** be a cluster operator
  - The core team doesn't have the capacity to deal directly with end-users
- Clusters **must** be running a supported minor version with the latest patch
  - Complex issues may need to be demonstrated on a cluster running the latest version
- **Only** clusters deployed using this module are supported
  - Forks of this module are not supported
  - Nesting this module in a wrapper module is not supported
- Issues should **only** be reported where the only change is this module
  - Terraform has a number of issues when using a large graph of changes
- Issues should **only** be created **after** checking there isn't already an open issue
  - Issues need to have context such as Kubernetes version, module version, region, etc
  - Issues should have an example of how to replicate them

---

## Architecture

See [documentation](/docs) for system architecture, requirements and user guides for cluster services.

### FIPS Support

When you create a new cluster, you can enable FIPS 140-2 mode by setting the `fips` module variable to `true` . Keep in mind that once a cluster has been created, you cannot enable or disable FIPS mode; you will need to create a new cluster if you want to change the FIPS mode.

FIPS 140-2 mode is a security standard that specifies the security requirements for cryptographic modules used in government and industry, and enabling it on your cluster can help ensure the security and integrity of the cryptographic functions used by your cluster. However, it can also introduce additional overhead and complexity, so operators should carefully consider whether it is necessary for the use case. It is crucial to ensure that any software running on the cluster is FIPS compliant in order for the cluster to function properly in FIPS 140-2 mode. This includes any applications or services that utilize cryptographic functions, as well as any external libraries or dependencies that may utilize cryptographic functions. Failure to do so can result in errors and potential security vulnerabilities.

### Networking

A VNet can contain multiple AKS clusters and be shared with non-AKS resources, however there **should** be a dedicated subnet and a unique route table for each AKS cluster. It is technically possible to host multiple AKS cluster node pools in a subnet, this is not recommended and may cause connectivity issues but can be achieved by passing in a unique non-overlapping CIDR block to each cluster via the `podnet_cidr_block` input variable. The two modes of network outbound traffic from the pods can be through a [load balancer](https://learn.microsoft.com/en-us/azure/load-balancer/load-balancer-overview) or a [managed NAT gateway](https://learn.microsoft.com/en-us/azure/aks/nat-gateway). The load balancer is configured by AKS within the module, while the NAT gateway needs to be configured externally.

Subnet configuration, in particular sizing, will largely depend on the network plugin (CNI) used. See the [network model comparison](https://docs.microsoft.com/en-us/azure/aks/concepts-network#compare-network-models) for more information.

### Service Endpoint

`v1.0.0-beta.24` introduces Thanos as a core service for Prometheus, providing high availability and long-term metrics. The backend utilizes an Azure service endpoint for secure access, improving security and decreasing internet traffic for cluster access. To use versions beyond `v1.0.0-beta.24`, operators must configure the Azure service endpoint in their subscription before consuming the service. See [rsg-terraform-azurerm-aks/issues/861](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/861) for more details.

### DNS

Configuration for the DNS can be configured via inputs in the `core_services_config` variable.

For example, the module exposes ingress endpoints for core services such as Prometheus, Grafana and AlertManager UIs. The endpoints must be secured via TLS and DNS records must be published to Azure DNS for clients to resolve.

```yaml
  core_services_config = {
    cert_manager = {
      acme_dns_zones      = ["us-accurint-prod.azure.lnrsg.io"]
      default_issuer_name = letsencrypt # for production usage of letsencrypt
    }

    external_dns = {
      private_resource_group_name = "us-accurint-prod-dns-rg"
      private_zones               = ["us-accurint-prod.azure.lnrsg.io"]
      # public_domain_filters       = ["us-accurint-prod.azure.lnrsg.io"] # use this if you use public dns zone
    }

    ingress_internal_core = {
      domain     = "us-accurint-prod.azure.lnrsg.io"
      public_dns = false # use true if you use public_domain_filters as above
    }
  }
```

- The `cert_manager` block specifies the **public zone** Let's Encrypt will use to validate the domain and its resource group.
- The `external_dns` block specifies domain(s) that user services can expose DNS records through and their resource group - all zones managed by _External DNS_ **must** be in a single resource group.
- The `ingress_internal_core` block specifies the domain to expose ingress resources to, consuming DNS/TLS services above.

It's very likely the same primary domain will be configured for all services, perhaps with _External DNS_ managing some additional domains. The resource group is a required input so the module can assign appropriate Azure role bindings. It is expected that in most cases all DNS domains will be hosted in a single resource group.

While _External DNS_ supports both public and private zones, in split-horizon setups only the private zone should be configured, otherwise both zones will be updated with service records. The only scenario for configuring both public and private zones of the same name is to migrate public records to private records. Once this is done, the public zone should be removed and records manually deleted in the public zone.

### Node Groups

The node group configuration provided by the `node_groups` input variable allows a cluster to be created with node groups that span multiple availability zones and can be configured with the specific required behaviour. The node group name prefix is the map key and at a minimum `node_size` & `max_capacity` must be provided with the other values having a default (see [Appendix B](#appendix-b)).

### Single Node Group

> **Warning**
> Do not use this it is likely to be deprecated in future module versions.

The single_group parameter controls whether a single node group is created that spans multiple zones, or if a separate node group is created for each zone in a cluster. When this parameter is set to `true`, a single node group is created that spans all zones, and the `min_capacity` and `max_capacity` settings apply to the total number of nodes across all zones. When set to false, separate node groups are created for each zone and the `min_capacity` and `max_capacity` settings apply to the number of nodes in each individual zone and must be scaled accordingly. It is advised to not use `single_group` unless you have a specific problem to solve and have spoken to the core engineering team.

#### Node image upgrades

AKS supports upgrading the images on a node so you're up to date with the newest OS and runtime updates. AKS regularly provides new images with the latest updates, so it's beneficial to upgrade your node's images regularly for the latest AKS features. Linux node images are updated weekly, and Windows node images updated monthly. For more information please visit the official [Microsoft documentation](https://docs.microsoft.com/en-us/azure/aks/node-image-upgrade).

Within the AKS module we use two features to automatically upgrade the node images:

- [Automatic upgrade channel](https://docs.microsoft.com/en-us/azure/aks/node-image-upgrade)
- [Maintenance Window](https://docs.microsoft.com/en-us/azure/aks/upgrade-cluster#set-auto-upgrade-channel)

Unlike EKS there is no way of specifying the node image version via Terraform so we use the Automatic upgrade channel set to node-image. this enables automatic node image upgrades outside of Terraform. Note Kubernetes patch, minor and major versions are controlled separately. Combining the automatic upgrade channel with a maintenance window gives us the ability to control when the upgrades take place.

The module sets a default of a maintenance window of Tuesdays, Wednesdays and Thursdays between the hours of 10am and 4pm. The default maintenance window can be overwritten in the client side code, for an example please visit the [RSG Kubernetes Documentation](https://legendary-doodle-a57ed2c8.pages.github.io/).

#### System Node Group

AKS always created a system node pool upon creation and modifying the system node pool results in the cluster being destroyed and re-built. An "initial" bootstrap node pool allows us to modify the system node pools without requiring a cluster re-build every time the system node pool gets modified. Once the cluster is ready, we attach our 3 system node pools (we need 3 to use storage) and when they are ready, we remove the "bootstrap" node pool.

#### Node Sizes

Node sizes are based on the number of CPUs, with the other resources being dependent on the node type; not all node types support all sizes.

When creating persistent volumes in Azure, make sure you use a size supported by azure disk. This applies to [Standard](https://docs.microsoft.com/en-us/azure/virtual-machines/disks-types#standard-ssd-size) and [Premium](https://docs.microsoft.com/en-us/azure/virtual-machines/disks-types#premium-ssd-size) disks; this doesn't apply to [Premium v2](https://learn.microsoft.com/en-us/azure/virtual-machines/disks-types#premium-ssd-v2) disks.

|   **Name** | **CPU Count** |
| ---------: | ------------: |
|    `large` |           `2` |
|   `xlarge` |           `4` |
|  `2xlarge` |           `8` |
|  `4xlarge` |          `16` |
|  `8xlarge` |          `32` |
| `12xlarge` |          `48` |
| `16xlarge` |          `64` |
| `18xlarge` |          `72` |
| `20xlarge` |          `80` |
| `24xlarge` |          `96` |
| `26xlarge` |         `104` |

#### Node Types

Node types describe the purpose of the node and maps down to the underlying [Azure virtual machines](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes). Select your node type for the kind of workloads you expect to be running, as a rule of thumb use `gp` unless you have additional requirements.

Due to the availability issues with specific Azure VMs when choosing a node type you also need to select the version; newer versions may well be less available in popular regions.

All the nodes provisioned by the module support premium storage.

##### General Purpose

[General purpose](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes-general) nodes, `gp` & `gpd`, offer a good balance of compute and memory. If you need a local temp disk `gpd` provides this.

| **Arch** | **Type** | **Variant** | **Version** | **VM Type**                                                                                          | **Sizes**                                                                               |
| -------- | -------- | ----------- | ----------- | ---------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| `amd64`  | `gp`     | `default`   | `v1`        | [Dsv4](https://docs.microsoft.com/en-us/azure/virtual-machines/dv4-dsv4-series#dsv4-series)          | `large`, `xlarge`, `2xlarge`, `4xlarge`, `8xlarge`, `12xlarge` & `16xlarge`             |
| `amd64`  | `gp`     | `default`   | `v2`        | [Dsv5](https://docs.microsoft.com/en-us/azure/virtual-machines/dv5-dsv5-series#dsv5-series)          | `large`, `xlarge`, `2xlarge`, `4xlarge`, `8xlarge`, `12xlarge`, `16xlarge` & `24xlarge` |
| `amd64`  | `gp`     | `amd`       | `v2`        | [Dasv5](https://learn.microsoft.com/en-us/azure/virtual-machines/dasv5-dadsv5-series#dasv5-series)   | `large`, `xlarge`, `2xlarge`, `4xlarge`, `8xlarge`, `12xlarge`, `16xlarge` & `24xlarge` |
| `arm64`  | `gp`     | `default`   | `v1`        | [Dpsv5](https://learn.microsoft.com/en-us/azure/virtual-machines/dpsv5-dpdsv5-series#dpsv5-series)   | `large`, `xlarge`, `2xlarge`, `4xlarge`, `8xlarge`, `12xlarge`, `16xlarge` & `24xlarge` |
| `amd64`  | `gpd`    | `default`   | `v1`        | [Ddsv4](https://docs.microsoft.com/en-us/azure/virtual-machines/ddv4-ddsv4-series#ddsv4-series)      | `large`, `xlarge`, `2xlarge`, `4xlarge`, `8xlarge`, `12xlarge` & `16xlarge`             |
| `amd64`  | `gpd`    | `default`   | `v2`        | [Ddsv5](https://docs.microsoft.com/en-us/azure/virtual-machines/ddv5-ddsv5-series#ddsv5-series)      | `large`, `xlarge`, `2xlarge`, `4xlarge`, `8xlarge`, `12xlarge`, `16xlarge` & `24xlarge` |
| `amd64`  | `gpd`    | `amd`       | `v2`        | [Dadsv5](https://learn.microsoft.com/en-us/azure/virtual-machines/dasv5-dadsv5-series#dadsv5-series) | `large`, `xlarge`, `2xlarge`, `4xlarge`, `8xlarge`, `12xlarge`, `16xlarge` & `24xlarge` |
| `arm64`  | `gpd`    | `default`   | `v1`        | [Dpdsv5](https://learn.microsoft.com/en-us/azure/virtual-machines/dpsv5-dpdsv5-series#dpdsv5-series) | `large`, `xlarge`, `2xlarge`, `4xlarge`, `8xlarge`, `12xlarge`, `16xlarge` & `24xlarge` |

##### Memory Optimised

[Memory optimised](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes-memory) nodes, `mem` & `memd`, offer a higher memory to CPU ration than general purpose nodes. If you need a local temp disk `memd` provides this.

| **Arch** | **Type** | **Variant** | **Version** | **VM Type**                                                                                          | **Sizes**                                                                                           |
| -------- | -------- | ----------- | ----------- | ---------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| `amd64`  | `mem`    | `default`   | `v1`        | [Esv4](https://docs.microsoft.com/en-us/azure/virtual-machines/ev4-esv4-series#esv4-series)          | `large`, `xlarge`, `2xlarge`, `4xlarge`, `8xlarge`, `12xlarge` & `16xlarge`                         |
| `amd64`  | `mem`    | `default`   | `v2`        | [Esv5](https://docs.microsoft.com/en-us/azure/virtual-machines/ev5-esv5-series#esv5-series)          | `large`, `xlarge`, `2xlarge`, `4xlarge`, `8xlarge`, `12xlarge`, `16xlarge`, `24xlarge` & `26xlarge` |
| `amd64`  | `mem`    | `amd`       | `v2`        | [Easv5](https://learn.microsoft.com/en-us/azure/virtual-machines/easv5-eadsv5-series#easv5-series)   | `large`, `xlarge`, `2xlarge`, `4xlarge`, `8xlarge`, `12xlarge`, `16xlarge`, `24xlarge` & `26xlarge` |
| `arm64`  | `mem`    | `default`   | `v1`        | [Epsv5](https://learn.microsoft.com/en-us/azure/virtual-machines/epsv5-epdsv5-series#epsv5-series)   | `large`, `xlarge`, `2xlarge`, `4xlarge` & `8xlarge`                                                 |
| `amd64`  | `memd`   | `default`   | `v1`        | [Edsv4](https://docs.microsoft.com/en-us/azure/virtual-machines/edv4-edsv4-series#edsv4-series)      | `large`, `xlarge`, `2xlarge`, `4xlarge`, `8xlarge`, `12xlarge` & `16xlarge`                         |
| `amd64`  | `memd`   | `default`   | `v2`        | [Edsv5](https://docs.microsoft.com/en-us/azure/virtual-machines/edv5-edsv5-series#edsv5-series)      | `large`, `xlarge`, `2xlarge`, `4xlarge`, `8xlarge`, `12xlarge`, `16xlarge`, `24xlarge` & `26xlarge` |
| `amd64`  | `memd`   | `amd`       | `v2`        | [Eadsv5](https://learn.microsoft.com/en-us/azure/virtual-machines/easv5-eadsv5-series#eadsv5-series) | `large`, `xlarge`, `2xlarge`, `4xlarge`, `8xlarge`, `12xlarge`, `16xlarge`, `24xlarge` & `26xlarge` |
| `arm64`  | `memd`   | `default`   | `v1`        | [Epdsv5](https://learn.microsoft.com/en-us/azure/virtual-machines/epsv5-epdsv5-series#epdsv5-series) | `large`, `xlarge`, `2xlarge`, `4xlarge` & `8xlarge`                                                 |

##### Compute Optimised

[Compute optimised](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes-compute) nodes, `cpu`, offer a higher CPU to memory ratio than general purpose nodes.

| **Arch** | **Type** | **Variant** | **Version** | **VM Type**                                                                 | **Sizes**                                                                               |
| -------- | -------- | ----------- | ----------- | --------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| `amd64`  | `cpu`    | `default`   | `v1`        | [Fsv2](https://docs.microsoft.com/en-us/azure/virtual-machines/fsv2-series) | `large`, `xlarge`, `2xlarge`, `4xlarge`, `8xlarge`, `12xlarge`, `16xlarge` & `18xlarge` |

##### Storage Optimised

[Storage optimised](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes-storage) nodes, `stor`, offer higher disk throughput and IO than general purpose nodes and come both with a local temp disk and one or more NVMe drives.

| **Arch** | **Type** | **Variant** | **Version** | **VM Type**                                                                    | **Sizes**                                                            |
| -------- | -------- | ----------- | ----------- | ------------------------------------------------------------------------------ | -------------------------------------------------------------------- |
| `amd64`  | `stor`   | `default`   | `v1`        | [Lsv2](https://docs.microsoft.com/en-us/azure/virtual-machines/lsv2-series)    | `2xlarge`, `4xlarge`, `8xlarge`, `12xlarge`, `16xlarge` & `20xlarge` |
| `amd64`  | `stor`   | `default`   | `v2`        | [Lsv3](https://docs.microsoft.com/en-us/azure/virtual-machines/lsv3-series)    | `2xlarge`, `4xlarge`, `8xlarge`, `12xlarge`, `16xlarge` & `20xlarge` |
| `amd64`  | `stor`   | `amd`       | `v2`        | [Lasv3](https://learn.microsoft.com/en-us/azure/virtual-machines/lasv3-series) | `2xlarge`, `4xlarge`, `8xlarge`, `12xlarge`, `16xlarge` & `20xlarge` |

### RBAC

This module currently only supports user access by users or groups passed into the module by the `rbac_bindings` input variable; these users and groups are linked to a `ClusterRole` via a `ClusterRoleBinding`. The following `ClusterRoles` can be bound to (the `ClusterRoles` with a `*` are [Kubernetes defaults](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#default-roles-and-role-bindings)).

| **ClusterRole**             | **Description**                                                                                                                                                                                                                                                                                                                             |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `cluster-admin`<sup>*</sup> | Allows super-user access to perform any action on any resource. It gives full control over every resource in the cluster and in all namespaces.                                                                                                                                                                                             |
| `view`<sup>*</sup>          | Allows read-only access to see most objects in all namespaces. It does not allow viewing roles or role bindings. This role does not allow viewing `Secrets`, since reading the contents of `Secrets` enables access to `ServiceAccount` credentials, which would allow API access as any `ServiceAccount` (a form of privilege escalation). |

---

## Usage

This module is expected to be referenced by it's major version (e.g. `v1`) and run regularly (at least every 4 weeks) to keep the cluster configuration up to date.

### Core Service Configuration

The core service configuration, input variable [core_services_config](#appendix-e), allows the customisation of the core cluster services. All core services run on a dedicated system node group reserved only for these services, although `DaemonSets` will be scheduled on all cluster nodes.

#### Node Auto-scaling

By default cluster nodes will be auto-scaled by the [Cluster Autoscaler](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/README.md) based on the node group configuration (resources, labels and taints).

#### Logging

AKS cluster logging is currently split up into two parts; the control plane logs are handled as part of the AKS service and are sent to Log Analytics, while the node and pod logs are handled by a core service reading the logs directly from the node and then sending them to a cluster aggregation service which can export the logs. The log export interface is specifically linked to the aggregator implementation, however there are plans to abstract this by supporting generic OpenTelemetry in addition to specific targets configured through the module. Additionally there are plans to enhance the system by supporting the aggregation of control plane logs into the cluster, allowing all logs to be managed as a unified set.

##### Control Plane Logs

Control plane logs are exported to one (or both) of a [Log Analytics Workspace](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/log-analytics-workspace-overview) or an [Azure Storage Account](https://learn.microsoft.com/en-us/azure/storage/common/storage-account-overview), these logs are retained for `30` days by default. Both of these destinations support the direct querying of the logs but sending logs to a Log Analytics Workspace will incur additional cost overhead.

The control plane logs can be configured via the [logging.control_plane](#appendix-c1) input variable which allows for the selection of the destinations as well as the profile ([see below](#control-plane-logging-profiles)) and additional configuration such as retention. Although the module can create a Log Analytics Workspace for control plane logs is is recommended to create the workspace outside of the module so that logs are retained even when a cluster is replaced.

The current, but **DEPRECATED**, behaviour for the cluster control plane logs is that the `recommended` profile is used to send logs to an Azure log analytics workspace created by this module.

###### Control Plane Logging Profiles

An AKS cluster generates a number of different [control plane logs](https://learn.microsoft.com/en-us/azure/aks/monitor-aks-reference#resource-logs) which need to be collected. To configure which log category types are collected you should specify a log profile, which can optionally be augmented with additional log category types.

The following control plane log profiles with their default log category types are supported (note that not all log category types are available in all Azure locations). You are strongly advised to use the `all` profile wherever possible and the `empty` profile is unsupported for any workload cluster and is only made available for testing purposes.

| **Profile**                    | **Log Category Types**                                                                                                                                                                                                              |
| :----------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `all`                          | `["kube-apiserver", "kube-audit", "kube-controller-manager", "kube-scheduler", "cluster-autoscaler", "cloud-controller-manager", "guard", "csi-azuredisk-controller", "csi-azurefile-controller", "csi-snapshot-controller"]`       |
| `audit-write-only`             | `["kube-apiserver", "kube-audit-admin", "kube-controller-manager", "kube-scheduler", "cluster-autoscaler", "cloud-controller-manager", "guard", "csi-azuredisk-controller", "csi-azurefile-controller", "csi-snapshot-controller"]` |
| `minimal`                      | `["kube-apiserver", "kube-audit-admin", "kube-controller-manager", "cloud-controller-manager", "guard"]`                                                                                                                            |
| `empty`                        | `[]`                                                                                                                                                                                                                                |
| `recommended` (**DEPRECATED**) | `["kube-apiserver", "kube-audit-admin", "kube-controller-manager", "kube-scheduler", "cluster-autoscaler", "cloud-controller-manager", "guard", "csi-azuredisk-controller", "csi-azurefile-controller", "csi-snapshot-controller"]` |
| `limited` (**DEPRECATED**)     | `["kube-apiserver", "kube-controller-manager", "cloud-controller-manager", "guard"]`                                                                                                                                                |

##### Node & Pod Logs

Both node (systemd) and pod/container logs are collected from the node by the _Fluent Bit_ collector `DaemonSet`, _Fluent Bit_ adds additional metadata to the collected logs before sending them off the ephemeral node to the persistent aggregation service. The persistent aggregation service is currently provided by _Fluentd_ running as a `StatefulSet` with a single pod in each cluster availability zone, _Fluentd_ makes sure that the logs can't be lost once they've been received by backing them on persistent storage. _Fluentd_ is then responsible for sending the logs to one or more destination. This architecture provides high throughput of logs, over 15k logs a second, and resilience to both node and network outages.

Logging outputs can be configured directly against _Fluentd_ via the module input variable `core_services_config.fluentd` (see [Appendix E5](#appendix-e5)); it is also possible to modify the logs as part of the route configuration but modifying logs in any way more advanced than adding fields for cluster context can significantly impact the _Fluentd_ throughput and so is strongly advised against.

In cluster _Loki_ support is currently experimental and can be enabled by setting the `experimental.loki` to `true`; this enables powerful log querying through the in cluster _Grafana_.

###### Workload Logging

The workload logging interface is to write logs to stdout/stderr, these logs will be collected and aggregated centrally in the cluster from where they can be exported to one or more destination. If your application creates JSON log lines the fields of this object are extracted, otherwise there is a `log` field with the application log data as a string; for JSON logging we suggest using `msg` for the log text field.

All pod logs have a `kube` tag and additional fields extracted from the Kubernetes metadata, please note that using [Kubernetes common labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/) makes the log fields more meaningful.

Pods annotated with the `fluentbit.io/exclude: "true"` annotation won't have their logs collected as part of the cluster logging system, this shouldn't be used unless you have an alternative way of ensuring that you're in compliance.

Pods annotated with the `lnrs.io/loki-ignore: "true"` annotation won't have their logs aggregated in the cluster _Loki_, this is advised against as it reduces log visibility but can be used to gradually integrate workloads with _Loki_.

#### Metrics

Cluster metrics are collected by _Prometheus_ which is managed by a _Prometheus Operator_ and made HA by running _Thanos_ as a sidecar and as a cluster service. Metrics can be exported from the cluster via the _Prometheus_ remote write protocol. It is planned to also support exporting metrics using the _OpenTelemetry_ interface.

##### Workload Metrics

The workload metrics interface is to expose metrics from the workload pod in _Prometheus_ format and then create either a [ServiceMonitor](https://prometheus-operator.dev/docs/operator/api/#monitoring.coreos.com/v1.ServiceMonitor) (if the workload has a service) or a [PodMonitor](https://prometheus-operator.dev/docs/operator/api/#monitoring.coreos.com/v1.PodMonitor) to configure how the metrics should be scraped by _Prometheus_. The `ServiceMonitor` and `PodMonitor` resources should be labelled with the `lnrs.io/monitoring-platform: "true"` label to ensure they are evaluated.

#### Metrics Alerts

Cluster alerts are powered by _AlertManager_ and are ignored by default, to configure the alerts you can use the module input variable `core_services_config.alertmanager` (see [Appendix E1](#appendix-e1)) to define [routes](https://prometheus.io/docs/alerting/latest/configuration/#route) and [receivers](https://prometheus.io/docs/alerting/latest/configuration/#receiver).

Custom [alert rules](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/) can be configured by adding additional [PrometheusRule](https://prometheus-operator.dev/docs/operator/api/#monitoring.coreos.com/v1.PrometheusRule) resources to the cluster with the `lnrs.io/monitoring-platform: "true"` and either the `lnrs.io/prometheus-rule: "true"` or `lnrs.io/thanos-rule: "true"` (only use the _Thanos_ rule label if you need to process more than 6h of metrics) labels set.

#### Traces

Traces aren't currently natively supported but it is planned to support at least the collection using the _OpenTelemetry_ interface.

#### Visualisation

The module provides in-cluster _Grafana_ as a visualisation service for metrics and logs; this can be configured via the `core_services_config.grafana` input variable (see [Appendix E7](#appendix-e7)). You can also add additional [data sources](https://grafana.com/docs/grafana/latest/datasources/) via a `ConfigMap` with the label `grafana_datasource: "1"` and additional [dashboards](https://grafana.com/docs/grafana/latest/dashboards/) via a `ConfigMap` with the label `grafana_dashboard: "1"`.

#### Certificates

Clusters have [Cert Manager](https://cert-manager.io/) installed to support generating certificates from [Certificate](https://cert-manager.io/docs/reference/api-docs/#cert-manager.io/v1.Certificate) resources referencing either a [ClusterIssuer](https://cert-manager.io/docs/reference/api-docs/#cert-manager.io/v1.ClusterIssuer) or an [Issuer](https://cert-manager.io/docs/reference/api-docs/#cert-manager.io/v1.Issuer); this can be configured via the `core_services_config.cert_manager` input variable (see [Appendix E2](#appendix-e2)). By default there are the following `ClusterIssuers` provided, `letsencrypt`, `letsencrypt-staging` & `zerossl`; all of which use [ACME DNS01](https://cert-manager.io/docs/configuration/acme/dns01/) which is configured via the `core_services_config.cert_manager.acme_dns_zones` input variable. It is possible to add additional `ClusterIssuer` or `Issuer` resources either via the `core_services_config.cert_manager.additional_issuers` or directly through the _Kubernetes_ API.

If an `Ingress` resource is annotated with the `cert-manager.io/cluster-issuer` or `cert-manager.io/issuer` and contains TLS configuration for the hosts _Cert Manager_ can automatically generate a certificate.

#### External DNS

Clusters have [External DNS](https://github.com/kubernetes-sigs/external-dns/blob/master/README.md) installed to manage configuring Azure DNS external to the cluster; this can be configured via the `core_services_config.external_dns` input variable (see [Appendix E4](#appendix-e4)). There will always be an instance managing private Route53 records but if you've configured public DNS zones there will also be a public instance running to manage these. To manage resources for private DNS the `lnrs.io/zone-type: private` annotation should be set, for public DNS the `lnrs.io/zone-type: public` annotation should be set and for split horizon (public & private) DNS the `lnrs.io/zone-type: public-private` annotation should be set.

 By default DNS records are only generated for `Ingress` resources with the `lnrs.io/zone-type` annotation set but additional _Kubernetes_ resource types can be supported by adding them to the `core_services_config.external_dns.additional_sources` input variable.

#### Storage

The module includes support for the [Azure Disks CSI driver](https://learn.microsoft.com/en-us/azure/aks/azure-disk-csi) (always on), [Azure Files CSI driver](https://learn.microsoft.com/en-us/azure/aks/azure-files-csi) (off by default), [Azure Blob CSI driver](https://learn.microsoft.com/en-us/azure/aks/azure-blob-csi) (off by default) and [Local Volume Static Provisioner](https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner) (off by default). There is also support creating a host path volume on the node from local disks (NVMe or the temp disk). The module storage configuration can be customised using the the [storage](#appendix-d) module input variable.

##### Azure Disks CSI Driver

The following `StorageClass` resources are created for the [Azure Disks CSI driver](https://learn.microsoft.com/en-us/azure/aks/azure-disk-csi) by default to support common [Azure disk types](https://learn.microsoft.com/en-us/azure/virtual-machines/disks-types) with default characteristics. When using a default `StorageClass` you are recommended to use the Premium SSD v2 classes where possible due to the best price-performance characteristics. If you need support for specific characteristics (such as higher IOPS or throughput) you should create a custom `StorageClass`.

- `azure-disk-standard-ssd-retain`
- `azure-disk-premium-ssd-retain`
- `azure-disk-premium-ssd-v2-retain`
- `azure-disk-standard-ssd-delete`
- `azure-disk-premium-ssd-delete`
- `azure-disk-premium-ssd-v2-delete`
- `azure-disk-standard-ssd-ephemeral`
- `azure-disk-premium-ssd-ephemeral`
- `azure-disk-premium-ssd-v2-ephemeral`

##### Azure Files CSI Driver

If you wish to use the [Azure Files CSI driver](https://learn.microsoft.com/en-us/azure/aks/azure-files-csi) you will need to enable it by setting `storage.file` to `true` and add one or more custom `StorageClass` resource.

##### Azure Blob CSI Driver

If you wish to use the [Azure Blob CSI driver](https://learn.microsoft.com/en-us/azure/aks/azure-blob-csi) you will need to enable it by setting `storage.blob` to `true` and add one or more custom `StorageClass` resource.

##### Local Volume Static Provisioner

If you wish to use the [Local Volume Static Provisioner](https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner) you will need to enable it by setting `storage.nvme_pv` to `true` and provision node groups with `nvme_mode` set to `PV`.

The current behaviour is to mount each NVMe drive on the node as a separate `PersistentVolume` but is should be possible to combine all of the drives into a single RAID-0 volume and either expose it as a single `PersistentVolume` or partition to support more `PersistentVolume` per node than there are NVMe drives.

##### Host Path Volume

If you wish to support creating a host path volume on nodes with local disks you will need to enable it by setting `storage.host_path` to `true` and provision node groups with either `temp_disk_mode` or `nvme_mode` set to `HOST_PATH`. This will create a host volume at `/mnt/scratch` backed by either the NVMe drives (RAID-0 if there are moe than one) or the temp disk. If a node has both NVMe drives and a temp disk and both are set to host path only the NVMe drives will be used.

#### Ingress

All traffic being routed into a cluster should be configured using an `Ingress` resources backed by an ingress controller and should **NOT** be configured directly as a `Service` resource of `LoadBalancer` type (this is what the ingress controllers do behind the scenes). There are a number of different ingress controller supported by _Kubernetes_ but it is strongly recommended to use an ingress controller backed by an official Terraform module to install. All ingress traffic should enter the cluster onto nodes specifically provisioned for ingress without any other workload on them.

Out of the box the cluster supports automatically generating certificates with the _Cert Manager_ default issuer, this can be overridden by the following `Ingress` annotations `cert-manager.io/cluster-issuer` or `cert-manager.io/issuer`. DNS records will be created by _External DNS_ from `Ingress` resources when the `lnrs.io/zone-type` is set, see the [DNS](#dns-1) config for how this works.

##### Ingress Controllers

- The following [official Terraform modules](https://github.com/search?q=topic%3Arsg-terraform-module+org%3ALexisNexis-RBA&type=Repositories) for ingress controllers are supported by the core engineering team and have been tested on AKS. These controller require you to have [ingress nodes](#ingress-nodes) registered in your cluster to work correctly.
- [K8s Ingress NGINX Terraform Module](https://github.com/LexisNexis-RBA/rsg-terraform-kubernetes-ingress-nginx)

##### Ingress Internal Core

> **Warning**
> With the release of Kubernetes `v1.25`, the behavior of ingress communication has changed compared to `v1.24`. If you are using pod-to-ingress communication when updating from Kubernetes `v1.24` to `v1.25`, you will encounter an SSL error when connecting cluster-hosted applications to the ingress due to a bug in how iptables rules were applied in the previous version.
>
> To pre-emptively address the issue of blocking node-to-pod traffic during a Kubernetes `v1.25` upgrade, you have two options depending on your requirements:
>
> Option 1: Specify the cluster pod CIDR in `core_services_config.ingress_internal_core.lb_source_cidrs`.
>
> Option 2: If you're using the [rsg-terraform-kubernetes-ingress-nginx](https://github.com/LexisNexis-RBA/rsg-terraform-kubernetes-ingress-nginx) module, add the pod CIDR to the `lb_source_cidrs` variable.
>
>This action will ensure that the correct iptables rules are applied, allowing traffic from the node to the pod via the ingress. The Kubernetes `v1.25` upgrade includes changes to the code that implements iptables rules, fixing an issue [kubernetes/kubernetes#109826](https://github.com/kubernetes/kubernetes/pull/109826) and enforcing the correct behavior of blocking node-to-pod traffic due to a lack of CIDRs in the service specification.
>
> Remember to perform the necessary steps before upgrading to Kubernetes `v1.25` to avoid any issues with node-to-pod traffic.

By default the platform deploys an internal `IngressClass`, named `core-internal`, to expose services such as _Prometheus_ and _Grafana_ UIs. This ingress shouldn't be used for user services but can be used for other internal dashboards; for user services instead deploy a dedicated ingress controller with it's own `IngressClass`.

By default this ingress doesn't support pod-to-ingress network traffic but you can override it by specifying `core_services_config.ingress_internal_core.lb_source_cidrs` (you will need to specify all the values). For better performance and network efficiency we recommend using internal communication for pod-to-pod interactions, rather than going outside and re-entering through an ingress; this utilizes the cluster's internal DNS service to access services inside the cluster using a `<service>.<namespace>.svc.cluster.local` domain name. However, if your use case requires pod-to-ingress communication, such as when ingress features like SSL termination, load balancing, or traffic routing rules are necessary, you will need to make sure you've configured the ingress correctly.

This is the only ingress controller in the cluster which doesn't require ingress nodes as it's required by all clusters and is not expected to carry a significant volume of traffic. If you do not configure ingress nodes this ingress controller will run on the system nodes.

##### Ingress Nodes

Ingress nodes mush have the `lnrs.io/tier: ingress` label and the `ingress=true:NoSchedule` taint to enable the ingress controller(s) to be scheduled and to isolate ingress traffic from other pods. You can also add additional labels and taints to keep specific ingress traffic isolated to it's own nodes. As ingress traffic is stateless a single node group can be used to span multiple zones by setting `single_group = true`.

An example of an ingress node group.

```terraform
locals {
  ingress_node_group = {
    {
      name                = "ingress"
      node_os             = "ubuntu"
      node_type           = "gp"
      node_type_version   = "v1"
      node_size           = "large"
      single_group        = true
      min_capacity        = 3
      max_capacity        = 6
      placement_group_key = null
      labels = {
        "lnrs.io/tier" = "ingress"
      }
      taints = [{
        key    = "ingress"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]
      tags   = {}
    }
  }
}
```

#### Calico and Network Policy

The module installs the Calico network policy engine on a Kubernetes cluster. Calico is a widely used networking solution for Kubernetes that allows users to define and enforce network policies for their pods. However, at this time this module does not expose Calico's functionality to operators. Instead, consumers can use native Kubernetes network policies to manage networking within their clusters.

Native Kubernetes network policies allow users to specify which pods can communicate with each other, as well as set up ingress and egress rules. This enables users to secure their clusters by controlling network traffic between pods and enforcing network segmentation. For more information on using network policies in Kubernetes, see the official documentation at: [kubernetes.io/docs/concepts/services-networking/network-policies/](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

### Tags

When utilizing custom tags with the module, it is essential to be aware of the potential limitations that may impact the removal of tags. Some tags may not be removed when attempting to remove them through the module, which can result in unexpected behaviour or errors in your pipeline. To avoid these issues, it is recommended to thoroughly review and test the behaviour of custom tags before implementing them in any environment. If necessary, persistent tags can be manually removed through the Azure portal, CLI or API to ensure that they are properly removed from the resource. For more information on tag limitations, you can refer to the Microsoft documentation [here](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources?tabs=json#limitations)

### Upgrading

Core service and node upgrades are automated as part of running this module and don't require any user interaction. Kubernetes minor version upgrades are supported by the module as long as the upgrade is only to the next minor version and the cluster has had the latest module version run against it.

### Regular Upgrade Steps

The following steps should be followed to automatically upgrade a clusters configuration.

- Re-run `terraform plan` with no code changes and the module reference set to a major version tag such as `v1`
- Review changes
- Apply updated configuration if there are any changes

### Kubernetes Minor Version Upgrade Steps

The following steps should be followed to upgrade a cluster's Kubernetes minor version.

- Follow the regular upgrade steps first
- Increment the _cluster_version_ by a single minor version e.g. `1.23` -> `1.24`
- Run `terraform plan`
- Review changes
- Apply changes

### Connecting to the Cluster

AKS clusters created by this module use [Azure AD authentication](https://docs.microsoft.com/en-us/azure/aks/managed-aad) and don't create local accounts.

#### Tooling Access

When running this module or using a Kubernetes based provider (`kubernetes`, `helm` or `kubectl`) the Terraform identity either needs to have the [Azure Kubernetes Service RBAC Cluster Admin](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#azure-kubernetes-service-rbac-cluster-admin) scoped to the cluster or you need to pass the identities AD group ID into the `admin_group_object_ids` module input variable.

> **INFO**
> If you're using TFE you need to use the `admin_group_object_ids` input variable unless specifically told otherwise.

From Terraform workspaces all Kubernetes based providers should be configured to use the [exec plugin](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs#exec-plugins) pattern and for AKS clusters this is [Kubelogin](https://github.com/Azure/kubelogin) which should be configured as below, note the constant `--server-id` of `6dae42f8-4368-4678-94ff-3960e28e3630` and the values which need to be defined in locals (or elsewhere). The `exec` block is the same as `kubernetes` for the `helm` and `kubectl` providers but is nested under the `kubernetes` block in them.

```terraform
provider "kubernetes" {
  host                   = module.aks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.aks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args        = ["get-token", "--login", "spn", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630", "--environment", local.azure_environment, "--tenant-id", local.tenant_id]
    env         =  { AAD_SERVICE_PRINCIPAL_CLIENT_ID = local.client_id, AAD_SERVICE_PRINCIPAL_CLIENT_SECRET = local.client_secret }
  }
}
```

#### End User Access

To connect to an AKS cluster after it's been created your AD user will need to have been added to the cluster via the `rbac_bindings` input variable. You can run the following commands, assuming that you have the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/) installed and you are logged in to it.

```shell
az aks install-cli
```

```shell
az account set --subscription "${SUBSCRIPTION}"
az aks get-credentials --resource-group "${RESOURCE_GROUP_NAME}" --name "${CLUSTER_NAME}"
kubelogin convert-kubeconfig -l azurecli
```

### Examples

- [Default example](./examples/default/)
- [DSG example](./examples/dsg/)
- [Windows example](./examples/windows/)

---

## Experimental Features

> **Info**
> Experimental features are not officially supported and do not follow SemVer like the rest of this module; use them at your own risk.

Experimental features allow end users to try out new functionality which isn't stable in the context of a stable module release, they are enabled by setting the required variables on the `experimental` module variable.

### AAD Pod Identity Finalizer Wait

If your cluster isn't being destroyed cleanly due to stuck AAD Pod Identity resources you can increase the time we wait before uninstalling the chart by setting `experimental = { aad_pod_identity_finalizer_wait = "300s" }`.

### OMS Agent Support

This module supports enabling the OMS agent as it needs to be done when the cluster is created; but the operation of the agent is not managed by the module and needs to be handled by the cluster operators separately. All core namespaces should be excluded by the cluster operator, especially the _logging_ namespace, unless they are specifically wanted.

To enable OMS agent support you need to set `experimental = { oms_agent = true, oms_log_analytics_workspace_id = "my-workspace-id" }`.

By default the module will configure the OMS agent by creating the `container-azm-ms-agentconfig` ConfigMap; this specifically excludes core namespaces from log collection. You can append additional data keys to the `ConfigMap` via the [config_map_v1_data](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map_v1_data) Terraform resource. It is possible to disable this behaviour by setting the `experimental.oms_agent_create_configmap` input variable to `false`; by doing this you're taking full responsibility for managing your own OMS agent configuration and should make sure that the default configuration log exclusion is replicated.

You can override the default Log Analytics ContainerLog schema to ContainerLogV2 by setting the `experimental.oms_agent_containerlog_schema_version` input variable to `v2`.

### Manual Service Memory Override

There are a number of services which can't be dynamically scaled horizontally but still need to be scaled as the cluster size and or load grows. in the future this will be handled by a combination of functionality, but until we have a working solution you can manually override the default memory given to them by setting one of the following variables  (e.g. `experimental = { fluentd_memory_override = "1024Mi" }`).

- _Fluentd_ - `fluentd_memory_override`
- _Prometheus_ - `prometheus_memory_override`

### Windows Node Support

> **Important**
> Teams must seek approval from their business unit Architect and IOG Architecture before using Windows node pools.

Windows Node support is **best effort** and is currently significantly limited, Windows node pools do not include platform `daemonsets` such as the Prometheus metrics exporter, Fluent Bit log collection or Azure AD Pod Identity. In the interim it is expected teams provide their own support for these features, e.g. use Azure Container Insights for log collection. Services provided by the AKS platform **should** work but have not been tested, including `kube-proxy`, CSI drivers and Calico network policy.

As of AKS `v1.25` the default AKS Windows version will be Windows Server 2022 which hasn't had any testing due to the lack of available resources, please make sure that you've updated your `node_os` inputs to specify the version of Windows required before upgrading to AKS `v1.25`.

There may be other requirements or specific configuration required for Windows nodes, yet to be identified. We encourage teams to identify, report and contribute code and documentation to improve support going forward.

To enable Windows support you need to set `experimental = { windows_support = true }`.

### Custom OS Configuration

To enable experimental support for [OS custom configuration](https://learn.microsoft.com/en-us/azure/aks/custom-node-configuration#linux-os-custom-configuration) you can set `experimental = { node_group_os_config = true }` and then add an `os_config` block to applicable `node_groups` objects.

```terraform
  node_groups = {
    workers = {
      node_os           = "ubuntu"
      node_type         = "gp"
      node_type_version = "v1"
      node_size         = "large"
      single_group      = false
      min_capacity      = 3
      max_capacity      = 6
      os_config = {
        sysctl = {
          net_core_rmem_max           = 2500000
          net_core_wmem_max           = 2500000
          net_ipv4_tcp_keepalive_time = 120
        }
      }
      labels = {}
      taints = []
      tags   = {}
    }
  }
```

Only a subset of Linux `systcl` configuration is supported (see above or [in code](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/blob/main/modules/node-groups/modules/node-group/main.tf)). Note not all parameters are required, please raise an issue for additional tunables.

### ARM64 Node Support

To enable the creation of ARM64 [Ampere Altra](https://azure.microsoft.com/en-us/blog/azure-virtual-machines-with-ampere-altra-arm-based-processors-generally-available/) nodes you can set the experimental flag `experimental = { arm64 = true }`. When this flag is set you can set `node_arch` to `arm64` to get an ARM64 instance, if this flag isn't set attempting to set `node_arch` will be ignored.

### Azure CNI Max Pods

To enable the customisation of the maximum number of pods per node when using the Azure CNI you can set the experimental flag `experimental = { azure_cni_max_pods = true }`. When this flag is set you can set `max_pods` to a value between `12` & `110`, if this flag isn't set attempting to set `max_pods` will be ignored.

### Disable Log Analytics For Control Plane Logs (**DEPRECATED**)

> **Note**
> This behaviour can now be achieved by using the `logging.control_plane` variable.

To disable the required sending of control plane logs to log analytics you can set the experimental flag `experimental = { control_plane_logging_log_analytics_disabled = true }` when `control_plane_logging_storage_account_enabled` is `true`.

### Fluent Bit Aggregator

The module now experimentally supports using _Fluent Bit_ as the log aggregator instead of _Fluentd_; the _Fluent Bit_ `StatefulSet` can have it's memory, CPU & replicas set in addition to the configuration of [filters](https://docs.fluentbit.io/manual/pipeline/filters) & [outputs](https://docs.fluentbit.io/manual/pipeline/outputs). This is currently an early experiment so if it is enabled you will not get any default behaviour and will have to configure all of the _Fluent Bit_ filters and outputs as raw configuration.

The _Fluent Bit Aggregator_ can be enabled by setting the experimental flag `experimental = { fluent_bit_aggregator = true }` but to make use of it you will need to provide raw Fluent Bit configuration via the `experimental.fluent_bit_aggregator_raw_filters` & `experimental.fluent_bit_aggregator_raw_outputs` flags. You can also provide custom scripts to be used by the [Lua filter](https://docs.fluentbit.io/manual/pipeline/filters/lua) via the `experimental.fluent_bit_aggregator_lua_scripts` flag. The `StatefulSet` can be configured by the `experimental.fluent_bit_aggregator_cpu_requests_override`, `experimental.fluent_bit_aggregator_cpu_limits_override`, `experimental.fluent_bit_aggregator_memory_override` & `experimental.fluent_bit_aggregator_replicas_per_zone` flags.

---

## Requirements

This module requires the following versions to be configured in the workspace `terraform {}` block.

### Terraform

| **Version** |
| :---------- |
| `>= 1.4.6`  |

### Providers

| **Name**                                                                                    | **Version** |
| :------------------------------------------------------------------------------------------ | :---------- |
| [hashicorp/azurerm](https://registry.terraform.io/providers/hashicorp/azurerm/latest)       | `>= 3.51.0` |
| [hashicorp/helm](https://registry.terraform.io/providers/hashicorp/helm/latest)             | `>= 2.8.0`  |
| [gavinbunney/kubectl](https://registry.terraform.io/providers/gavinbunney/kubectl/latest)   | `>= 1.14.0` |
| [hashicorp/kubernetes](https://registry.terraform.io/providers/hashicorp/kubernetes/latest) | `>= 2.15.0` |
| [hashicorp/random](https://registry.terraform.io/providers/hashicorp/random/latest)         | `>= 3.3.0`  |
| [scottwinkler/shell](https://registry.terraform.io/providers/scottwinkler/shell/latest)     | `>= 1.7.10` |
| [hashicorp/time](https://registry.terraform.io/providers/hashicorp/time/latest)             | `>= 0.7.2`  |

---

## Variables

| **Variable**                                              | **Description**                                                                                                                                                                                                                                                                                                                                                                                                     | **Type**                                   | **Default**       |
| :-------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | :----------------------------------------- | :---------------- |
| `location`                                                | Azure location to target.                                                                                                                                                                                                                                                                                                                                                                                           | `string`                                   |                   |
| `resource_group_name`                                     | Name of the resource group to create resources in, some resources will be created in a separate AKS managed resource group.                                                                                                                                                                                                                                                                                         | `string`                                   |                   |
| `cluster_name`                                            | Kubernetes Service managed cluster to create, also used as a prefix in names of related resources. This must be lowercase and contain the pattern `aks-{ordinal}` (e.g. `app-aks-0` or `app-aks-1`).                                                                                                                                                                                                                | `string`                                   |                   |
| `cluster_version`                                         | Kubernetes version to use for the Azure Kubernetes Service managed cluster; versions `1.26`, `1.25` or `1.24` are supported.                                                                                                                                                                                                                                                                                        | `string`                                   |                   |
| `sku_tier`                                                | Pricing tier for the Azure Kubernetes Service managed cluster; \"free\" & \"standard\" are supported. For production clusters or clusters with more than 10 nodes this should be set to `standard` (see [docs](https://learn.microsoft.com/en-us/azure/aks/free-standard-pricing-tiers)).                                                                                                                           | `string`                                   | `"free"`          |
| `cluster_endpoint_public_access`                          | Indicates whether or not the Azure Kubernetes Service managed cluster public API server endpoint is enabled.                                                                                                                                                                                                                                                                                                        | `bool`                                     |                   |
| `cluster_endpoint_access_cidrs`                           | List of CIDR blocks which can access the Azure Kubernetes Service managed cluster API server endpoint, an empty list will not error but will block public access to the cluster.                                                                                                                                                                                                                                    | `list(string)`                             |                   |
| `virtual_network_resource_group_name`                     | Name of the resource group containing the virtual network.                                                                                                                                                                                                                                                                                                                                                          | `string`                                   |                   |
| `virtual_network_name`                                    | Name of the virtual network to use for the cluster.                                                                                                                                                                                                                                                                                                                                                                 | `string`                                   |                   |
| `subnet_name`                                             | Name of the AKS subnet in the virtual network.                                                                                                                                                                                                                                                                                                                                                                      | `string`                                   |                   |
| `route_table_name`                                        | Name of the AKS subnet route table.                                                                                                                                                                                                                                                                                                                                                                                 | `string`                                   |                   |
| `dns_resource_group_lookup`                               | Lookup from DNS zone to resource group name.                                                                                                                                                                                                                                                                                                                                                                        | `map(string)`                              |                   |
| `podnet_cidr_block`                                       | CIDR range for pod IP addresses when using the `kubenet` network plugin, if you're running more than one cluster in a subnet (or sharing a route table) this value needs to be unique.                                                                                                                                                                                                                              | `string`                                   | `"100.65.0.0/16"` |
| `nat_gateway_id`                                          | ID of a user-assigned NAT Gateway to use for cluster egress traffic, if not set a cluster managed load balancer will be used. Please note that this can only be enabled when creating a new cluster.                                                                                                                                                                                                                | `string`                                   | `null`            |
| `managed_outbound_ip_count`                               | Count of desired managed outbound IPs for the cluster managed load balancer, see the [documentation](https://docs.microsoft.com/en-us/azure/aks/load-balancer-standard#scale-the-number-of-managed-outbound-public-ips). Ignored if NAT gateway is specified, must be between `1` and `100` inclusive.                                                                                                              | `number`                                   | `1`               |
| `managed_outbound_ports_allocated`                        | Number of desired SNAT port for each VM in the cluster managed load balancer, do not manually set this unless you've read the [documentation](https://docs.microsoft.com/en-us/azure/aks/load-balancer-standard#configure-the-allocated-outbound-ports) carefully and fully understand the impact of the change. Ignored if NAT gateway is specified, must be between `0` & `64000` inclusive and divisible by `8`. | `number`                                   | `0`               |
| `managed_outbound_idle_timeout`                           | Desired outbound flow idle timeout in seconds for the cluster managed load balancer, see the [documentation](https://docs.microsoft.com/en-us/azure/aks/load-balancer-standard#configure-the-load-balancer-idle-timeout). Ignored if NAT gateway is specified, must be between `240` and `7200` inclusive.                                                                                                          | `number`                                   | `240`             |
| `admin_group_object_ids`                                  | AD Object IDs to be added to the cluster admin group, this should only ever be used to make the Terraform identity an admin if it can't be done outside the module.                                                                                                                                                                                                                                                 | `list(string)`                             | `[]`              |
| `rbac_bindings`                                           | User and groups to configure in Kubernetes `ClusterRoleBindings`; for Azure AD these are the IDs.                                                                                                                                                                                                                                                                                                                   | `object` ([Appendix A](#appendix-a))       | `{}`              |
| `node_groups`                                             | Node groups to configure.                                                                                                                                                                                                                                                                                                                                                                                           | `map(object)` ([Appendix B](#appendix-b))  | `{}`              |
| `logging`                                                 | Logging configuration.                                                                                                                                                                                                                                                                                                                                                                                              | `map(object)` ([Appendix C](#appendix-c))  | `{}`              |
| `storage`                                                 | Storage configuration.                                                                                                                                                                                                                                                                                                                                                                                              | `map(object)` ([Appendix D](#appendix-d))  | `{}`              |
| `core_services_config`                                    | Core service configuration.                                                                                                                                                                                                                                                                                                                                                                                         | `any` ([Appendix E](#appendix-e))          |                   |
| `control_plane_logging_external_workspace`                | **DEPRECATED** - If `true`, the log analytics workspace referenced in `control_plane_logging_external_workspace_id` will be used to store the logs. Otherwise a log analytics workspace will be created to store the logs.                                                                                                                                                                                          | `bool`                                     | `false`           |
| `control_plane_logging_external_workspace_id`             | **DEPRECATED** - ID of the log analytics workspace to send control plane logs to if `control_plane_logging_external_workspace` is `true`.                                                                                                                                                                                                                                                                           | `string`                                   | `null`            |  | `bool` | `false` |
| `control_plane_logging_workspace_categories`              | **DEPRECATED** - The control plane log categories to send to the log analytics workspace.                                                                                                                                                                                                                                                                                                                           | `string`                                   | `recommended`     |
| `control_plane_logging_workspace_retention_enabled`       | **DEPRECATED** - If `true`, the control plane logs being sent to log analytics will use the retention specified in `control_plane_logging_workspace_retention_days` otherwise the log analytics workspace default retention will be used.                                                                                                                                                                           | `bool`                                     | `false`           |
| `control_plane_logging_workspace_retention_days`          | **DEPRECATED** - How long the logs should be retained by the log analytics workspace if `control_plane_logging_workspace_retention_enabled` is `true`, in days.                                                                                                                                                                                                                                                     | `number`                                   | `0`               |
| `control_plane_logging_storage_account_enabled`           | **DEPRECATED** - If `true`, cluster control plane logs will be sent to the storage account referenced in `control_plane_logging_storage_account_id` as well as the default log analytics workspace.                                                                                                                                                                                                                 | `bool`                                     | `false`           |
| `control_plane_logging_storage_account_id`                | **DEPRECATED** - ID of the storage account to add cluster control plane logs to if `control_plane_logging_storage_account_enabled` is `true`.                                                                                                                                                                                                                                                                       | `string`                                   | `null`            |
| `control_plane_logging_storage_account_categories`        | **DEPRECATED** - The control plane log categories to send to the storage account.                                                                                                                                                                                                                                                                                                                                   | `string`                                   | `all`             |
| `control_plane_logging_storage_account_retention_enabled` | **DEPRECATED** - If `true`, the control plane logs being sent to the storage account will use the retention specified in `control_plane_logging_storage_account_retention_days` otherwise no retention will be set.                                                                                                                                                                                                 | `bool`                                     | `true`            |
| `control_plane_logging_storage_account_retention_days`    | **DEPRECATED** - How long the logs should be retained by the storage account if `control_plane_logging_storage_account_retention_enabled` is `true`, in days.                                                                                                                                                                                                                                                       | `number`                                   | `30`              |
| `maintenance_window_offset`                               | Maintenance window offset to UTC.                                                                                                                                                                                                                                                                                                                                                                                   | `number`                                   | `null`            |
| `maintenance_window_allowed_days`                         | List of allowed days covering the maintenance window.                                                                                                                                                                                                                                                                                                                                                               | `list(string)`                             | `[]`              |
| `maintenance_window_allowed_hours`                        | List of allowed hours covering the maintenance window.                                                                                                                                                                                                                                                                                                                                                              | `list(number)`                             | `[]`              |
| `maintenance_window_not_allowed`                          | List of not allowed block objects consisting of start and end times in rfc3339 format. A not allowed block takes priority if it overlaps an allowed blocks in a maintenance window.                                                                                                                                                                                                                                 | `list(object)` ([Appendix F](#appendix-f)) | `[]`              |
| `tags`                                                    | Tags to apply to all resources.                                                                                                                                                                                                                                                                                                                                                                                     | `map(string)`                              | `{}`              |
| `fips`                                                    | If `true`, the cluster will be created with FIPS 140-2 mode enabled; this can't be changed once the cluster has been created.                                                                                                                                                                                                                                                                                       | `bool`                                     | `false`           |
| `experimental`                                            | Configure experimental features.                                                                                                                                                                                                                                                                                                                                                                                    | `any`                                      | `{}`              |

### Appendix A

Specification for the `rbac_bindings` object.

> **Note**
> User and group IDs can be found in Azure Active Directory.

| **Variable**          | **Description**                                                                                      | **Type**       | **Default** |
| :-------------------- | :--------------------------------------------------------------------------------------------------- | :------------- | :---------- |
| `cluster_admin_users` | Users to bind to the `cluster-admin` `ClusterRole`, identifier as the key and group ID as the value. | `map(string)`  | `{}`        |
| `cluster_view_users`  | Users to bind to the `view` `ClusterRole`, identifier as the key and group ID as the value.          | `map(string)`  | `{}`        |
| `cluster_view_groups` | Groups to bind to the `view` `ClusterRole`, list of group IDs.                                       | `list(string)` | `[]`        |

### Appendix B

Specification for the `node_groups` objects.

| **Variable**          | **Description**                                                                                                                                                                                                                                                                                                                                                         | **Type**                                     | **Default** |
| :-------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------- | :---------- |
| `node_arch`           | **EXPERIMENTAL** - Processor architecture to use for the node group(s), `amd64` & `arm64` are supported. See [docs](#arm64-node-support).                                                                                                                                                                                                                               | `string`                                     | `amd64`     |
| `node_os`             | OS to use for the node group(s), `ubuntu`, `windows2019` & `windows2022` (**EXPERIMENTAL**) are supported, [Windows node support](#windows-node-support) is not guaranteed but best-effort and needs manually enabling.                                                                                                                                                 | `string`                                     | `"ubuntu"`  |
| `node_type`           | Node type to use, one of `gp`, `gpd`, `mem`, `memd`, `cpu` or `stor`. See [node types](#node-types) for more information.                                                                                                                                                                                                                                               | `string`                                     | `"gp"`      |
| `node_type_variant`   | The variant of the node type to use. See [node types](#node-types) for more information.                                                                                                                                                                                                                                                                                | `string`                                     | `"default"` |
| `node_type_version`   | The version of the node type to use. See [node types](#node-types) for more information.                                                                                                                                                                                                                                                                                | `string`                                     | `"v1"`      |
| `node_size`           | Size of the instance to create in the node group(s). See [node sizes](#node-sizes) for more information.                                                                                                                                                                                                                                                                | `string`                                     |             |
| `ultra_ssd`           | If the node group can use Azure ultra disks.                                                                                                                                                                                                                                                                                                                            | `bool`                                       | `false`     |
| `os_disk_size`        | Size of the OS disk to create, this will be ignored if `temp_disk_mode` is `KUBELET`.                                                                                                                                                                                                                                                                                   | `number`                                     | `128`       |
| `temp_disk_mode`      | The temp disk mode for the node group, this is only valid for node types with a temp disk. The available values are `NONE` to do nothing, `KUBELET` (**EXPERIMENTAL**) to store the kubelet data (images, logs and empty dir volumes), & `HOST_PATH` (**EXPERIMENTAL**) to create a single volume at `/mnt/scratch` which can be used by a host mount volume.           | `string`                                     | `NONE`      |
| `nvme_mode`           | The NVMe mode for node group, this is only valid for `stor` node types. The available values are `NONE` to do nothing, `PV` to use the Local Volume Static Provisioner to create PersistentVolumes, & `HOST_PATH` (**EXPERIMENTAL**) to create a single volume (RAID-0 if more than 1 NVMe disk is present) at `/mnt/scratch` which can be used by a host mount volume. | `string`                                     | `NONE`      |
| `os_config`           | **EXPERIMENTAL** - Custom OS configuration. See [docs](#custom-os-configuration).                                                                                                                                                                                                                                                                                       | `object`                                     |             |
| `placement_group_key` | If specified the node group will be added to a proximity placement group created for the key in a zone, `single_group` must be `false`. The key must be lowercase, alphanumeric, maximum 11 characters, please refer to the [documentation](/docs/README.md#proximity-placement-groups) for warnings and considerations.                                                | `string`                                     | `null`      |
| `single_group`        | If this template represents a single node group spanning multiple zones or a node group per cluster zone.                                                                                                                                                                                                                                                               | `bool`                                       | `false`     |
| `min_capacity`        | Minimum number of nodes in the node group(s), this needs to be divisible by the number of subnets in use.                                                                                                                                                                                                                                                               | `number`                                     | `0`         |
| `max_capacity`        | Maximum number of nodes in the node group(s), this needs to be divisible by the number of subnets in use.                                                                                                                                                                                                                                                               | `number`                                     |             |
| `max_pods`            | **EXPERIMENTAL** - Custom maximum number of pods when using the Azure CNI; by default this is `30` but can be set to `-1` to use the default or explicitly between `20` & `110`. For Kubenet there is always a maximum of `110` pods. See [docs](#azure-cni-max-pods).                                                                                                  | `number`                                     | `-1`        |
| `max_surge`           | **EXPERIMENTAL** - Custom maximum number or percentage of nodes which will be added to the Node Pool size during an upgrade.                                                                                                                                                                                                                                            | `string`                                     | `10%`       |
| `labels`              | Additional labels for the node group(s). It is suggested to set the `lnrs.io/tier` label.                                                                                                                                                                                                                                                                               | `map(string)`                                | `{}`        |
| `taints`              | Taints for the node group(s). For ingress node groups the `ingress` taint should be set to `NO_SCHEDULE`.                                                                                                                                                                                                                                                               | `list(object)` ([Appendix B1](#appendix-b1)) | `[]`        |
| `tags`                | User defined component of the node group name.                                                                                                                                                                                                                                                                                                                          | `map(string)`                                | `{}`        |

### Appendix B1

Specification for the `node_groups.taints` object.

| **Variable** | **Description**                                                                           | **Type** | **Default** |
| :----------- | :---------------------------------------------------------------------------------------- | :------- | :---------- |
| `key`        | The key of the taint. Maximum length of 63.                                               | `string` |             |
| `value`      | The value of the taint. Maximum length of 63.                                             | `string` |             |
| `effect`     | The effect of the taint. Valid values: `NO_SCHEDULE`, `NO_EXECUTE`, `PREFER_NO_SCHEDULE`. | `string` |             |

### Appendix C

Specification for the `logging` object.

| **Variable**    | **Description**                      | **Type**                               | **Default** |
| :-------------- | :----------------------------------- | :------------------------------------- | :---------- |
| `control_plane` | Control plane logging configuration. | `object` ([Appendix C1](#appendix-c1)) | `{}`        |

### Appendix C1

Specification for the `logging.control_plane` object.

| **Variable**      | **Description**                                      | **Type**                               | **Default** |
| :---------------- | :--------------------------------------------------- | :------------------------------------- | :---------- |
| `log_analytics`   | Control plane logging log analytics configuration.   | `object` ([Appendix C2](#appendix-c2)) | `{}`        |
| `storage_account` | Control plane logging storage account configuration. | `object` ([Appendix C3](#appendix-c3)) | `{}`        |

### Appendix C2

Specification for the `logging.control_plane.log_analytics` object.

| **Variable**                    | **Description**                                                     | **Type**       | **Default** |
| :------------------------------ | :------------------------------------------------------------------ | :------------- | :---------- |
| `enabled`                       | If control plane logs should be sent to a Log Analytics Workspace.  | `bool`         | `false`     |
| `external_workspace`            | If the workspace has been created outside the module.               | `bool`         | `false`     |
| `workspace_id`                  | The workspace ID if `external_workspace` is `true`.                 | `string`       | `null`      |
| `profile`                       | The profile to use for the log category types.                      | `string`       | `null`      |
| `additional_log_category_types` | Additional log category types to collect.                           | `list(string)` | `[]`        |
| `retention_enabled`             | If retention should be configured per log category collected.       | `bool`         | `false`     |
| `retention_days`                | Number of days to retain the logs if `retention_enabled` is `true`. | `bool`         | `false`     |

### Appendix C3

Specification for the `logging.control_plane.storage_account` object.

| **Variable**                    | **Description**                                                     | **Type**       | **Default** |
| :------------------------------ | :------------------------------------------------------------------ | :------------- | :---------- |
| `enabled`                       | If control plane logs should be sent to a Log Analytics Workspace.  | `bool`         | `false`     |
| `id`                            | The Azure Storage Account ID.                                       | `string`       | `null`      |
| `profile`                       | The profile to use for the log category types.                      | `string`       | `null`      |
| `additional_log_category_types` | Additional log category types to collect.                           | `list(string)` | `[]`        |
| `retention_enabled`             | If retention should be configured per log category collected.       | `bool`         | `false`     |
| `retention_days`                | Number of days to retain the logs if `retention_enabled` is `true`. | `bool`         | `false`     |

### Appendix D

Specification for the `storage` object.

| **Variable** | **Description**                                              | **Type**                               | **Default** |
| :----------- | :----------------------------------------------------------- | :------------------------------------- | :---------- |
| `file`       | Azure File CSI configuration.                                | `object` ([Appendix D1](#appendix-d1)) | `{}`        |
| `blob`       | Azure Blob CSI configuration.                                | `object` ([Appendix D2](#appendix-d2)) | `{}`        |
| `nvme_pv`    | NVMe Local Volume Static Provisioner configuration.          | `object` ([Appendix D3](#appendix-d3)) | `{}`        |
| `host_path`  | NVMe & temp disk host path configuration (**EXPERIMENTAL**). | `object` ([Appendix D4](#appendix-d4)) | `{}`        |

### Appendix D1

Specification for the `storage.file` object.

| **Variable** | **Description**                          | **Type** | **Default** |
| :----------- | :--------------------------------------- | :------- | :---------- |
| `enabled`    | If the Azure File CSI should be enabled. | `bool`   | `false`     |

### Appendix D2

Specification for the `storage.blob` object.

| **Variable** | **Description**                          | **Type** | **Default** |
| :----------- | :--------------------------------------- | :------- | :---------- |
| `enabled`    | If the Azure Blob CSI should be enabled. | `bool`   | `false`     |

### Appendix D3

Specification for the `storage.nvme_pv` object.

| **Variable** | **Description**                                                                       | **Type** | **Default** |
| :----------- | :------------------------------------------------------------------------------------ | :------- | :---------- |
| `enabled`    | If the Local Volume Static Provisioner should be enabled to mount NVMe drives as PVs. | `bool`   | `false`     |

### Appendix D4

Specification for the `storage.host_path` object.

| **Variable** | **Description**                                               | **Type** | **Default** |
| :----------- | :------------------------------------------------------------ | :------- | :---------- |
| `enabled`    | If the NVMe or temp disk host path support should be enabled. | `bool`   | `false`     |

### Appendix E

Specification for the `core_services_config` object.

| **Variable**            | **Description**                         | **Type**                                 | **Default** |
| :---------------------- | :-------------------------------------- | :--------------------------------------- | :---------- |
| `alertmanager`          | Alertmanager configuration.             | `object` ([Appendix E1](#appendix-e1))   |             |
| `cert_manager`          | Cert Manager configuration.             | `object` ([Appendix E2](#appendix-e2))   | `{}`        |
| `coredns`               | CoreDNS configuration.                  | `object` ([Appendix E3](#appendix-e3))   | `{}`        |
| `external_dns`          | ExternalDNS configuration.              | `object` ([Appendix E4](#appendix-e4))   | `{}`        |
| `fluentd`               | Fluentd configuration.                  | `object` ([Appendix E5](#appendix-e5))   | `{}`        |
| `grafana`               | Grafana configuration.                  | `object` ([Appendix E7](#appendix-e7))   | `{}`        |
| `ingress_internal_core` | Ingress internal-core configuration.    | `object` ([Appendix E8](#appendix-e8))   |             |
| `prometheus`            | Prometheus configuration.               | `object` ([Appendix E9](#appendix-e9))   | `{}`        |
| `storage`               | **DEPRECATED** - Storage configuration. | `object` ([Appendix E10](#appendix-e10)) | `{}`        |

### Appendix E1

Specification for the `core_services_config.alertmanager` object.

| **Variable** | **Description**                                                                               | **Type**       | **Default** |
| :----------- | :-------------------------------------------------------------------------------------------- | :------------- | :---------- |
| `smtp_host`  | SMTP host to send alert emails.                                                               | `string`       |             |
| `smtp_from`  | SMTP from address for alert emails.                                                           | `string`       |             |
| `receivers`  | [Receiver configuration](https://prometheus.io/docs/alerting/latest/configuration/#receiver). | `list(object)` | `[]`        |
| `routes`     | [Route configuration](https://prometheus.io/docs/alerting/latest/configuration/#route).       | `list(object)` | `[]`        |

### Appendix E2

Specification for the `core_services_config.cert_manager` object.

| **Variable**          | **Description**                                                | **Type**       | **Default**             |
| :-------------------- | :------------------------------------------------------------- | :------------- | :---------------------- |
| `acme_dns_zones`      | DNS zones that _ACME_ issuers can manage certificates for.     | `list(string)` | `[]`                    |
| `additional_issuers`  | Additional issuers to install into the cluster.                | `map(object)`  | `{}`                    |
| `default_issuer_kind` | Kind of the default issuer.                                    | `string`       | `"ClusterIssuer"`       |
| `default_issuer_name` | Name of the default issuer , use `letsencrypt` for prod certs. | `string`       | `"letsencrypt-staging"` |

### Appendix E3

Specification for the `core_services_config.coredns` object.

| **Variable**    | **Description**                                                          | **Type**      | **Default** |
| :-------------- | :----------------------------------------------------------------------- | :------------ | :---------- |
| `forward_zones` | Map of DNS zones and DNS server IP addresses to forward DNS requests to. | `map(string)` | `{}`        |

### Appendix E4

Specification for the `core_services_config.external_dns` object.

| **Variable**             | **Description**                                                                                                 | **Type**       | **Default** |
| :----------------------- | :-------------------------------------------------------------------------------------------------------------- | :------------- | :---------- |
| `additional_sources`     | Additional _Kubernetes_ objects to be watched.                                                                  | `list(string)` | `[]`        |
| `private_domain_filters` | Domains that can have DNS records created for them, these must be set up in the VPC as private hosted zones.    | `list(string)` | `[]`        |
| `public_domain_filters`  | Domains that can have DNS records created for them, these must be set up in the account as public hosted zones. | `list(string)` | `[]`        |

### Appendix E5

Specification for the `core_services_config.fluentd` object.

| **Variable**       | **Description**                                                                                                                                                                    | **Type**                                     | **Default** |
| :----------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------- | :---------- |
| `image_repository` | Custom image repository to use for the _Fluentd_ image, `image_tag` must also be set.                                                                                              | `map(string)`                                | `null`      |
| `image_tag`        | Custom image tag to use for the _Fluentd_ image, `image_repository` must also be set.                                                                                              | `map(string)`                                | `null`      |
| `additional_env`   | Additional environment variables.                                                                                                                                                  | `map(string)`                                | `{}`        |
| `debug`            | If `true` all logs will be sent to stdout.                                                                                                                                         | `bool`                                       | `true`      |
| `filters`          | Global [Fluentd filter configuration](https://docs.fluentd.org/filter) which will be run before the route output. This can be multiple `<filter>` blocks as a single string value. | `string`                                     | `null`      |
| `route_config`     | Global [Fluentd filter configuration](https://docs.fluentd.org/filter) which will be run before the route output. This can be multiple `<filter>` blocks as a single string value. | `list(object)` ([Appendix E6](#appendix-e6)) | `[]`        |

### Appendix E6

Specification for the `core_services_config.fluentd.route_config` object.

| **Variable** | **Description**                                       | **Type** | **Default** |
| :----------- | :---------------------------------------------------- | :------- | :---------- |
| `match`      | The log tag match to use for this route.              | `string` |             |
| `label`      | The label to use for this route.                      | `string` |             |
| `copy`       | If the matched logs should be copied to later routes. | `bool`   | `false`     |
| `config`     | The output configuration to use for the route.        | `string` |             |

### Appendix E7

Specification for the `core_services_config.grafana` object.

| **Variable**              | **Description**                | **Type**       | **Default** |
| :------------------------ | :----------------------------- | :------------- | :---------- |
| `admin_password`          | Admin password.                | `string`       | `changeme`  |
| `additional_data_sources` | Additional data sources.       | `list(object)` | `[]`        |
| `additional_plugins`      | Additional plugins to install. | `list(string)` | `[]`        |

### Appendix E8

Specification for the `core_services_config.ingress_internal_core` object.

| **Variable**       | **Description**                                                                                                                                                        | **Type**       | **Default**                       |
| :----------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------- | :-------------------------------- |
| `domain`           | Internal ingress domain.                                                                                                                                               | `string`       |                                   |
| `subdomain_suffix` | Suffix to add to internal ingress subdomains, if not set cluster name will be used.                                                                                    | `string`       | _{CLUSTER_NAME}_                  |
| `lb_source_cidrs`  | CIDR blocks of the IPs allowed to connect to the internal ingress endpoints.                                                                                           | `list(string)` | `["10.0.0.0/8", "100.65.0.0/16"]` |
| `lb_subnet_name`   | Name of the subnet to create the load balancer in, if not set subnet where node groups reside will be auto selected. _Should not be set unless specifically required._ | `string`       |                                   |
| `public_dns`       | If the internal ingress DNS should be public or private.                                                                                                               | `bool`         | `false`                           |

### Appendix E9

Specification for the `core_services_config.prometheus` object.

| **Variable**   | **Description**                     | **Type**       | **Default** |
| :------------- | :---------------------------------- | :------------- | :---------- |
| `remote_write` | Remote write endpoints for metrics. | `list(object)` | `[]`        |

### Appendix E10

Specification for the **DEPRECATED** `core_services_config.storage` object.

| **Variable** | **Description**                                       | **Type** | **Default** |
| :----------- | :---------------------------------------------------- | :------- | :---------- |
| `file`       | If support for the file CSI driver should be enabled. | `bool`   | `false`     |
| `blob`       | If support for the blob CSI driver should be enabled. | `bool`   | `false`     |

### Appendix F

Specification for the `maintenance_window_not_allowed` object.

| **Variable** | **Description**                                                             | **Type** | **Default** |
| :----------- | :-------------------------------------------------------------------------- | :------- | :---------- |
| `start`      | Start time for the not allowed maintenance window block in RFC 3339 format. | `string` | No          |
| `end`        | End time for the not allowed maintenance window block in RFC 3339 format.   | `string` | No          |

---

## Outputs

| **Variable**                                 | **Description**                                                                                                                                                 | **Type**       |
| :------------------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------- |
| `cluster_id`                                 | Azure Kubernetes Service (AKS) managed cluster ID.                                                                                                              | `string`       |
| `cluster_fqdn`                               | FQDN of the Azure Kubernetes Service managed cluster.                                                                                                           | `string`       |
| `cluster_endpoint`                           | Endpoint for the Azure Kubernetes Service managed cluster API server.                                                                                           | `string`       |
| `cluster_certificate_authority_data`         | Base64 encoded certificate data for the Azure Kubernetes Service managed cluster API server.                                                                    | `string`       |
| `control_plane_log_analytics_workspace_id`   | ID of the default log analytics workspace used for control plane logs.                                                                                          | `string`       |
| `control_plane_log_analytics_workspace_name` | Name of the default log analytics workspace used for control plane logs, this will be empty if an external one is in use.                                       | `string`       |
| `node_resource_group_name`                   | Auto-generated resource group which contains the resources for this managed Kubernetes cluster.                                                                 | `string`       |
| `effective_outbound_ips`                     | Outbound IPs from the Azure Kubernetes Service cluster managed load balancer (this will be an empty array if the cluster is uisng a user-assigned NAT Gateway). | `list(string)` |
| `cluster_identity`                           | User assigned identity used by the cluster.                                                                                                                     | `object`       |
| `kubelet_identity`                           | Kubelet identity.                                                                                                                                               | `object`       |
| `cert_manager_identity`                      | Identity that Cert Manager uses.                                                                                                                                | `object`       |
| `coredns_custom_config_map_name`             | Name of the CoreDNS custom `ConfigMap`, if external config has been enabled.                                                                                    | `string`       |
| `coredns_custom_config_map_namespace`        | Namespace of the CoreDNS custom `ConfigMap`, if external config has been enabled.                                                                               | `object`       |
| `external_dns_private_identity`              | Identity that private ExternalDNS uses.                                                                                                                         | `object`       |
| `external_dns_public_identity`               | Identity that public ExternalDNS uses.                                                                                                                          | `object`       |
| `fluent_bit_aggregator_identity`             | Identity that Fluent Bit Aggregator uses.                                                                                                                       | `object`       |
| `fluentd_identity`                           | Identity that Fluentd uses.                                                                                                                                     | `object`       |
| `grafana_identity`                           | Identity that Grafana uses.                                                                                                                                     | `object`       |
| `oms_agent_identity`                         | Identity that the OMS agent uses.                                                                                                                               | `object`       |
| `windows_config`                             | Windows configuration.                                                                                                                                          | `object`       |
