# Azure AKS Terraform Module Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## Upgrading From Pre v1.0.0-beta.10 Versions

All clusters created with a module version older than `v1.0.0-beta.10` need to be destroyed and re-created with the latest version of the module.

---

## Deprecations

- Legacy module `ConfigMap` is deprecated and will be removed in the `v1.11.0` release.
- The `control_plane_logging_external_workspace_different_resource_group` variable is deprecated as it's unused and will be removed in the `v1.12.0` release.
- AKS cluster version `v1.23` is deprecated and will be removed in the `v1.12.0` release.
- The `azure_env` variable is deprecated in favour of inferring the value from `location`, this will be removed in the `v1.12.0` release.
- The `paid` option for `sku_tier` is deprecated and will be removed in the `v1.13.0` release.

---

<!-- ## [vX.Y.Z] - UNRELEASED
### Highlights
### All Changes
- Added
- Updated
- Changed
- Fixed
- Deprecated
- Removed -->

## [v1.11.0] - UNRELEASED

### Highlights

### All Changes

- Updated full AKS versions which include patch versions for `v1.24` to `v1.24.10` & `v1.25` to `v1.25.6`. [@peterabarr](https://github.com/peterabarr)

## [v1.10.0] - 2023-04-12

### Highlights

#### Kubernetes v1.25 is now Generally Available

Great news! The _AKS_ module now supports the latest version of Kubernetes `v1.25`, which has just been released as GA. This update brings a range of new features and improvements to the Kubernetes platform, including enhanced security capabilities, improved scalability and stability, and better support for modern application architectures. By upgrading to Kubernetes `v1.25`, you can take advantage of these benefits.

#### Removals

- We removed the deprecated `docker_bridge_cidr` argument from the `azurerm_kubernetes_cluster` resource in `module.aks.module.cluster`. The argument is no longer supported by the API and will be removed in version 4.0 of the provider.
- The `sku_tier_paid` variable was also removed in favour of `sku_tier`.
- Removed the `network_plugin` variable because it was deprecated in favour of inferring the value from `experimental.windows_support`.
- Removed deprecated `node_os` value `windows` in favour for `windows2019`.

### All Changes

- Added `standard` option to `sku_tier` to replace `paid`. ([#1034](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/pull/1034)) [@stevehipwell](https://github.com/stevehipwell)
- Updated the minimum version of the `azurerm` Terraform provider to [v3.51.0](https://github.com/hashicorp/terraform-provider-azurerm/releases/tag/v3.51.0). ([#1032](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/pull/1032)) [@appkins](https://github.com/appkins)
- Updated support of Kubernetes v1.25 to GA. ([#1015](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/pull/1015)) [@aydosman](https://github.com/aydosman)
- Updated _External DNS_ chart to [v1.12.2](https://github.com/kubernetes-sigs/external-dns/releases/tag/external-dns-helm-chart-1.12.2) (contains _External DNS_ image update to [v0.13.4](https://github.com/kubernetes-sigs/external-dns/releases/tag/v0.13.4)). ([#1028](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/pull/1028)) [@hadeeds](https://github.com/hadeeds)
- Updated the Grafana additionalDataSources object properties. ([#1014](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/pull/1014)) [@aydosman](https://github.com/aydosman)
- Remapped `sku_tier = "paid"` to `Standard` in the `sku_tier_lookup` local to fix a bug introduced in the 2023-02-01 version of the AKS API. ([#1032](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/pull/1032)) [@appkins](https://github.com/appkins)
- Fixed Logging Dashboard Plan Error. ([#1017](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/pull/1017)) [@appkins](https://github.com/appkins)
- Fixed orchestrator version for node groups causing Azure API errors. ([#1034](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/pull/1034)) [@stevehipwell](https://github.com/stevehipwell)
- Deprecated `paid` option for `sku_tier`. ([#1034](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/pull/1034)) [@stevehipwell](https://github.com/stevehipwell)
- Removed the `sku_tier_paid` variable in favour of `sku_tier`. ([#1027](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/pull/1027)) [@peterabarr](https://github.com/peterabarr)
- Removed the `network_plugin` variable because it was deprecated in favour of inferring the value from `experimental.windows_support`. ([1002](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/pull/1002)) [@peterabarr](https://github.com/peterabarr)
- Removed deprecated `node_os` value `windows` in favour for `windows2019`. ([#999](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/pull/999)) [@peterabarr](https://github.com/peterabarr)
- Removed the deprecated `docker_bridge_cidr`. This argument is no longer needed or supported. ([#1023](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/pull/1023)) [@aydosman](https://github.com/aydosman)

## [v1.9.1] - 2023-04-04

### All Changes

- Fixed logging dashboard plan error. [@peterabarr](https://github.com/peterabarr)

## [v1.9.0] - 2023-03-27

> **Warning**
> As of 2023-04-04 module version `v1.9.0` is no longer supported and you should upgrade to `v1.9.1` or higher.

### Highlights

- **Deprecated Kubernetes v1.23**: We no longer support this version of Kubernetes.
- **`max_surge` input added to `node_groups` variable**: This allows you to specify the maximum number or percentage of nodes that will be added to the Node Pool size during an upgrade. [Learn how to set it here](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/blob/main/README.md#appendix-b).
- **Core service Helm chart updates**: We've updated multiple core service Helm charts.
- **ContainerLogV2 support for OMS experimental implementation**: This feature is now available. [Learn how to set it up here](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/blob/main/README.md#oms-agent-support).

### Deprecations

Please note that the `azure_env` input has been deprecated in favour of inferring the value from `location`.

### All Changes

- Deprecated `azure_env` variable is deprecated in favour of inferring the value from `location`. ([937](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/937)) [@appkins](https://github.com/appkins)
- Updated _Fluentd_ chart to [v3.7.0](https://github.com/stevehipwell/helm-charts/releases/tag/fluentd-aggregator-3.7.0) (contains _Fluentd Aggregator_ [v2.7.0](https://github.com/stevehipwell/fluentd-aggregator/releases/tag/v2.7.0)). ([985](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/985)) [@hadeeds](https://github.com/hadeeds)
- Changed _Fluentd_ image to use `glibc` variant to improve performance on ARM64 nodes. ([985](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/985)) [@hadeeds](https://github.com/hadeeds)
- Fixed Grafana Azure Monitor data source identity roles. [@stevehipwell](https://github.com/stevehipwell)
- Fixed `experimental.control_plane_logging_log_analytics_disabled` error in core config. [@stevehipwell](https://github.com/stevehipwell)
- Deprecated `control_plane_logging_external_workspace_different_resource_group` as it's no longer used. [@stevehipwell](https://github.com/stevehipwell)
- Added support for ContainerLogV2 in the OMS experimental implementation. [@stevehipwell](https://github.com/stevehipwell)
- Added `max_surge` input to `node_groups` variable. Allows specifying the maximum number or percentage of nodes which will be added to the Node Pool size during an upgrade. ([958](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/958)) [@appkins](https://github.com/appkins)
- Deprecated AKS cluster version `v1.23`. ([990](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/pull/990)) [@peterabarr](https://github.com/peterabarr)
- Updated _External DNS_ chart to [v1.12.1](https://github.com/kubernetes-sigs/external-dns/releases/tag/external-dns-helm-chart-1.12.1) which contains image update to [v0.13.2](https://github.com/kubernetes-sigs/external-dns/releases/tag/v0.13.2). ([#993](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/pull/993)) [@hadeeds](https://github.com/hadeeds)
- Updated _Fluent Bit_ chart to [v0.25.0](https://github.com/fluent/helm-charts/releases/tag/fluent-bit-0.25.0) (contains _Fluent Bit_ [v2.0.10](https://github.com/fluent/fluent-bit/releases/tag/v2.0.10)). ([1001](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/pull/1001)) [@peterabarr](https://github.com/peterabarr)
- Added `cluster_name` as an output. ([1003](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/pull/1003)) [@peterabarr](https://github.com/peterabarr)
- Fixed orchestrator version for node groups causing Azure API errors. [@stevehipwell](https://github.com/stevehipwell)

## [v1.8.0] - 2023-03-13

### Highlights

- The AzureRM Terraform Provider has been updated to `v3.47.0`.
- Multiple core service Helm charts have been updated.
- Added experimental support for disabling sending control plane logs to log analytics. [See how to set it here](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/tree/main#disable-log-analytics-for-control-plane-logs)

#### Deprecations

Please note that the `sku_tier_paid` input has been deprecated and has been replaced with `sku_tier`. This version will be removed in AKS module version `v1.10.0`.

### All Changes

- Updated the minimum version of the `azurerm` Terraform provider to [v3.47.0](https://github.com/hashicorp/terraform-provider-azurerm/releases/tag/v3.47.0). [@stevehipwell](https://github.com/stevehipwell)
- Added `sku_tier` input variable to support the new [AKS pricing tiers](https://learn.microsoft.com/en-us/azure/aks/free-standard-pricing-tiers). Cluster operators should read the docs to see if they need to pay for `standard` (currently set via `paid`). [@stevehipwell](https://github.com/stevehipwell)
- Deprecated `sku_tier_paid` in favour of `sku_tier`. [@stevehipwell](https://github.com/stevehipwell)
- Changed legacy module `ConfigMap` values to be empty and removed dependencies. [@stevehipwell](https://github.com/stevehipwell)
- Updated _Thanos_ chart to [v1.10.2](https://github.com/stevehipwell/helm-charts/releases/tag/thanos-1.10.2) (contains _Thanos_ [v0.30.2](https://github.com/thanos-io/thanos/releases/tag/v0.30.2)). ([#954](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/954)) [@hadeeds](https://github.com/hadeeds)
- Added experimental support for disabling sending control plane logs to log analytics. [@stevehipwell](https://github.com/stevehipwell)
- Updated _Ingress Ngninx_ chart to [4.5.2](https://github.com/kubernetes/ingress-nginx/releases/tag/helm-chart-4.5.2) (contains _Nginx Controller_ [v1.6.4](https://github.com/kubernetes/ingress-nginx/releases/tag/controller-v1.6.4)). ([#956](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/956)) [@hadeeds](https://github.com/hadeeds)
- Fixed explicit orchestrator version for bootstrap node pool causing Azure API errors. [@stevehipwell](https://github.com/stevehipwell)
- Fixed _Cert Manager_ resource ordering. [@stevehipwell](https://github.com/stevehipwell)

## [v1.7.1] - 2023-03-13

> **Important**
> As of 2023-04-12 version `1.7.1` and below is no longer supported. If you are still this version please update to the latest release.

- Fixed explicit orchestrator version for bootstrap node pool causing Azure API errors. [@stevehipwell](https://github.com/stevehipwell)

## [v1.7.0] - 2023-02-27

> **Warning**
**DO NOT USE THIS VERSION** - Please use `v1.7.1` instead.

### Highlights

#### Kubernetes 1.25 Support

We're looking to move 1.25 out of experimental in the near future. Any feedback around usage or issues with version 1.25 is greatly appreciated as we move towards this goal.

#### Node Type Variant

The `node_group` input now supports the optional `node_type_variant` parameter. This supports the option of `amd` as a value, but is only advised for power users at this time. Additional info available [here](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks#node-types).

#### Windows OS Node Group Type

Deprecated the node group `node_os` value of `windows` in favour of `windows2019` as we want the explicit Windows version as a module input.

#### Premium SSD v2 Storage Classes

Added support for Premium SSD v2 disks via additional `StorageClass` resources. The following storage classes are now available:

- `azure-disk-premium-ssd-v2-retain`
- `azure-disk-premium-ssd-v2-delete`
- `azure-disk-premium-ssd-v2-ephemeral`

### All Changes

- Updated _Fluentd_ chart to [v3.6.2](https://github.com/stevehipwell/helm-charts/releases/tag/fluentd-aggregator-3.6.2) (contains _Fluentd Aggregator_ [v2.6.2](https://github.com/stevehipwell/fluentd-aggregator/releases/tag/v2.6.2). ([#918](https://github.com/LexisNexis-RBA/rsg-terraform-aws-eks/issues/918)) [@hadeeds](https://github.com/hadeeds)
- Added support to be able to select K8s patch versions by their region. ([#903](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/903)) [@peterabarr](https://github.com/peterabarr))
- Added a patch release issue template to help with patch releases ([#921](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/921)) [@peterabarr](https://github.com/peterabarr))
- Updated _Fluent Bit_ chart to [v0.24.0](https://github.com/fluent/helm-charts/releases/tag/fluent-bit-0.24.0). ([#917](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/917)) [@hadeeds](https://github.com/hadeeds)
- Updated _Kube Prometheus Stack_ chart to [v45.1.1](https://github.com/prometheus-community/helm-charts/releases/tag/kube-prometheus-stack-45.1.1) (contains _Prometheus Operator_ [v0.63.0](https://github.com/prometheus-operator/prometheus-operator/releases/tag/v0.63.0) and _Prometheus_ [v2.42.0](https://github.com/prometheus/prometheus/releases/tag/v2.42.0)). ([#925](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/925)) [@appkins](https://github.com/appkins)
- Added support for Premium SSD v2 disks via additional `StorageClass` resources. ([#929](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/929)) [@stevehipwell](https://github.com/stevehipwell)
- Removed requirement to set an experimental flag to use an experimental cluster version, this added unnecessary additional complexity for a non-API change. [@stevehipwell](https://github.com/stevehipwell)
- Added support for explicitly specifying the Windows version in the node group `node_os` variable when using Windows nodes. [@stevehipwell](https://github.com/stevehipwell)
- Added **UNTESTED** experimental support for using Windows Server 2022. [@stevehipwell](https://github.com/stevehipwell)
- Deprecated the node group `node_os` value of `windows` in favour of `windows2019` as we want the explicit Windows version as a module input. [@stevehipwell](https://github.com/stevehipwell)
- Added support for node type variants via the optional `node_type_variant` node group input to allow for additional node options such as processor vendor. [@stevehipwell](https://github.com/stevehipwell)
- Added `amd` node type variants to the `v2` versions of the `amd64` arch `gp`, `gpd`, `mem`, `memd` & `stor` node types. ([#791](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/791)) [@stevehipwell](https://github.com/stevehipwell)
- Updated the minimum version of the `azurerm` Terraform provider to [v3.39.1](https://github.com/hashicorp/terraform-provider-azurerm/releases/tag/v3.39.1). [@stevehipwell](https://github.com/stevehipwell)
- Fixed churn and warning for`azurerm_monitor_diagnostic_setting` resource. [@stevehipwell](https://github.com/stevehipwell)
- Fixed warning about `api_server_authorized_ip_ranges`. [@stevehipwell](https://github.com/stevehipwell)
- Fixed cluster tagging bug. [@stevehipwell](https://github.com/stevehipwell)
- Updated _Cert Manager_ CRDs for release [v1.11.0](https://github.com/cert-manager/cert-manager/releases/tag/v1.11.0). ([#941](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/941)) [@aydosman](https://github.com/aydosman)

## [v1.6.3] - 2023-03-13

- Fixed explicit orchestrator version for bootstrap node pool causing Azure API errors. [@stevehipwell](https://github.com/stevehipwell)

## [v1.6.2] - 2023-02-27

> **Warning**
> **DO NOT USE THIS VERSION** - Please use `v1.6.3` instead.

- Updated _Cert Manager_ CRDs for release [v1.11.0](https://github.com/cert-manager/cert-manager/releases/tag/v1.11.0). ([#941](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/941)) [@OsmanA](https://github.com/OsmanA)

## [v1.6.1] - 2023-02-16

> **Warning**
> **DO NOT USE THIS VERSION** - Please use `v1.6.3` instead.
### All Changes

- Fixed Thanos endpoint for government cloud compatibility. ([#914](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/914)) [@appkins](https://github.com/appkins) & [@bachni01](https://github.com/bachni01)

## [v1.6.0] - 2023-02-13

> **Important**
> Previous _AKS_ versions no longer work on Kubernetes version `1.25`. If you wish to use `1.25`, please use _AKS_ version `v1.6.0`.

> **Important** The extended Christmas support windows has come to an end which means that we are back to only supporting the 3 latest minor version patches and that versions a, b, c are no longer supported. If you haven't already please make sure you update to a supported version ASAP.

### Highlights

In this revision to the _AKS_ module, we added support for use of the _Azure Blob CSI Driver_.

#### Azure Blob CSI Driver

Added configuration for `storage` under `core_services_config` which includes support for the built in _Azure Blob CSI Driver_.

#### Deprecations

Deprecates the `network_plugin variable`. Infers value from `var.experimental.windows_support`.

#### Updated AKS versions

The AKS version has been patched; `v1.25.2` to `1.25.5` and  `v1.24.6` to `1.24.9` These changes fix a number of CVEs & defects and keep the AKS version supported by Azure.

### All Changes

- Added `storage` input under `core_services_config` for configuring blob csi support. ([#832](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/832)) [@appkins](https://github.com/appkins)

## [v1.5.2] - 2023-02-27

- Updated _Cert Manager_ CRDs for release [v1.11.0](https://github.com/cert-manager/cert-manager/releases/tag/v1.11.0). ([#941](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/941)) [@aydosman](https://github.com/aydosman)

## [v1.5.1] - 2023-02-14

> **Warning**
> **DO NOT USE THIS VERSION** - Please use `v1.5.2` instead due to missing updated CRDs in the  _Cert Manager_ helm chart update.

### All Changes

- Updated full AKS versions which include patch versions for `1.23` to `1.23.15`, `v1.24` to `v1.24.9` & `v1.25` to `v1.25.5`. [@peterabarr](https://github.com/peterabarr)

## [v1.5.0] - 2023-01-30

### Highlights

In this revision to the AKS module, modifications were mostly focused on updating core services with Helm Chart upgrades. Additionally, the _Kube Prometheus Stack_ was updated to incorporate the latest CRDs. As a proactive measure, it has been determined that starting from version `v1.6.0`, core services will not be updated with every chart update unless it incorporates crucial modifications such as CVE patches or bug resolution. This decision has been made to minimize operational overhead and prioritize development efforts within the module.

### All Changes

- Updated _Ingress Ngninx_ chart to [4.4.2](https://github.com/kubernetes/ingress-nginx/releases/tag/helm-chart-4.4.2). ([#874](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/874)) [@hadeeds](https://github.com/hadeeds)
- Updated _Cert Manager_ chart to [1.11.0](https://github.com/cert-manager/cert-manager/releases/tag/v1.11.0). ([#867](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/867)) [@hadeeds](https://github.com/hadeeds)
- Updated _Kube Prometheus Stack_ chart to [v44.2.1](https://github.com/prometheus-community/helm-charts/releases/tag/kube-prometheus-stack-44.2.1) (contains _Prometheus Operator_ [v0.62.0](https://github.com/prometheus-operator/prometheus-operator/releases/tag/v0.62.0) and _Prometheus_ [v2.41.0](https://github.com/prometheus/prometheus/releases/tag/v2.41.0)). ([#866](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/866)) [@hadeeds](https://github.com/hadeeds)
- Updated _Fluent Bit_ chart to [v0.22.0](https://github.com/fluent/helm-charts/releases/tag/fluent-bit-0.22.0). ([#879](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/879)) [@hadeeds](https://github.com/hadeeds)

## [v1.4.1] - 2023-02-14

### All Changes

- Updated full AKS versions which include patch versions for `1.23` to `1.23.15`, `v1.24` to `v1.24.9` & `v1.25` to `v1.25.5`. [@peterabarr](https://github.com/peterabarr)

## [v1.4.0] - 2023-01-16

>**Warning**
> If you are encountering delays when creating AKS clusters in your subscriptions and have multiple AKS clusters within the same VNET that share the same route table, please exercise caution and refer to [this](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/870) issue.

### Highlights

In this update to the AKS module focused on enhancing logging capabilities. To achieve this, various configurations were modified to improve the performance of Fluent Bit and Fluentd, including updating to the latest version of their Helm Charts. Additionally, any core services that had available updates were also updated.

#### Security Fixes

- _Cert Manager_ Helm Chart `v1.10.2` update fixes the following CVEs.
  - [CVE-2022-23525](https://nvd.nist.gov/vuln/detail/CVE-2022-23525)
  - [CVE-2022-41717](https://nvd.nist.gov/vuln/detail/CVE-2022-41717)
  - [CVE-2022-41717](https://nvd.nist.gov/vuln/detail/CVE-2022-41717)

### All Changes

- Updated _Thanos_ chart to [v1.10.1](https://github.com/stevehipwell/helm-charts/releases/tag/thanos-1.10.1) (contains _Thanos_ [v0.30.1](https://github.com/thanos-io/thanos/releases/tag/v0.30.1)). ([#858](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/858)) [@peterabarr](https://github.com/peterabarr)
- Updated _Cert Manager_ chart to [1.10.2](https://github.com/cert-manager/cert-manager/releases/tag/v1.10.2). ([#863](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/863)) [@peterabarr](https://github.com/peterabarr)
- Updated _Fluent Bit_ chart to [v0.21.7](https://github.com/fluent/helm-charts/releases/tag/fluent-bit-0.21.7) (contains _Fluent Bit_ [v2.0.8](https://github.com/fluent/fluent-bit/releases/tag/v2.0.8)). ([#806](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/806)) [@aydosman](https://github.com/aydosman)
- Changed _Fluent Bit_ configuration to improve performance. [@aydosman](https://github.com/aydosman)
- Added _Fluent Bit_ forward output compatibility configuration for _Fluentd_. [@aydosman](https://github.com/aydosman)
- Removed experimental flag `fluent_bit_use_memory_buffer` as it no longer offers an performance benefits. [@aydosman](https://github.com/aydosman)
- Updated _Fluentd_ chart to [v3.6.0](https://github.com/aydosman/helm-charts/releases/tag/fluentd-aggregator-3.6.0) (contains _Fluentd Aggregator_ [v2.6.0](https://github.com/aydosman/fluentd-aggregator/releases/tag/v2.6.0)). [@aydosman](https://github.com/aydosman)
- Added topology aware routing for _Fluentd_ if using AKS `v1.24`. [@aydosman](https://github.com/aydosman)
- Changed _Fluentd_ behaviour when `debug` is set to use an output plugin instead of a filter for performance reasons. [@aydosman](https://github.com/aydosman)
- Deprecated _Fluentd_ `debug` defaulting to `true`. [@aydosman](https://github.com/aydosman)
- Changed the log processing to run in _Fluent Bit_ instead of _Fluentd_. [@aydosman](https://github.com/aydosman)

## [v1.3.0] - 2023-01-04

> **Important**
> As of 2023-02-13 version `1.3.0` is no longer supported. If you are still this version please update to the latest release.

### Highlights

During the holiday period, the development team made minimal changes to the module. Any necessary updates were applied to core services, and we revised the implementation of the module versioning mechanism by adding a shell script to apply the tag to the cluster. After positive feedback the FIPS experimental feature is now fully supported by the module. Additionally, we completed preparatory work on pod security admission for the core namespaces in anticipation of future projects.

### All Changes

- Added [Pod Security Admission](https://kubernetes.io/docs/concepts/security/pod-security-admission/) labels at `audit`/`warn` mode and `baseline` level for the core namespaces. ([#818](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/818)) [@prikesh-patel](https://github.com/prikesh-patel)
- Added shell script to apply module version tag to cluster. ([#682](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/682)) [@prikesh-patel](https://github.com/prikesh-patel)
- Updated _Kube Prometheus Stack_ chart to [v43.2.1](https://github.com/prometheus-community/helm-charts/releases/tag/kube-prometheus-stack-43.2.1) (contains _Alertmanager_ [v0.25.0](https://github.com/prometheus/alertmanager/releases/tag/v0.25.0). ([#839](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/839)) [@hadeeds](https://github.com/hadeeds)
- Added GA support for creating FIPS 140-2 clusters by setting `fips` to `true` when creating the cluster. ([#593](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/381)) [@aydosman](https://github.com/aydosman)

## [v1.2.0] - 2022-12-20

### Highlights

#### Holiday Period

We hope that all operators using the module are enjoying the holiday season. As we look ahead to the new year, we are excited to see what opportunities and challenges it brings for the module. In this release, we have primarily focused on maintaining and updating the core services. We hope that this focus on stability and reliability will continue to provide a strong foundation for the module in the coming year.

#### Security Fixes

- _Kube Prometheus Stack_ helm chart update contains _Prometheus Node Exporter_ `v1.5.0`, which fixes [CVE-2022-46146](https://nvd.nist.gov/vuln/detail/CVE-2022-46146) and _Prometheus_ `2.37.4`, which fixes [CVE-2022-46146](https://nvd.nist.gov/vuln/detail/CVE-2022-46146)

### All Changes

- Added experimental support for _AKS_ [v1.25](https://azure.microsoft.com/en-us/updates/public-preview-k8s-125-support/). ([#786](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/786)) [@prikesh-patel](https://github.com/prikesh-patel)
- Updated _External DNS_ chart to [v1.12.0](https://github.com/kubernetes-sigs/external-dns/releases/tag/external-dns-helm-chart-1.12.0) which contains image update to [v0.13.1](https://github.com/kubernetes-sigs/external-dns/releases/tag/v0.13.1). ([#819](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/819)) [@hadeeds](https://github.com/hadeeds)
- Updated _Kube Prometheus Stack_ chart to [v43.0.0](https://github.com/prometheus-community/helm-charts/releases/tag/kube-prometheus-stack-43.0.0) (contains _Kube State Metrics_ [v2.7.0](https://github.com/kubernetes/kube-state-metrics/releases/tag/v2.7.0), _Grafana_ [v9.3.1](https://github.com/grafana/grafana/releases/tag/v9.3.1), _Prometheus Operator_ [v0.61.1](https://github.com/prometheus-operator/prometheus-operator/releases/tag/v0.61.1), _Prometheus_ [v2.37.5](https://github.com/prometheus/prometheus/releases/tag/v2.37.5), _Prometheus Node Exporter_ [v1.5.0](https://github.com/prometheus/node_exporter/releases/tag/v1.5.0)). ([#810](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/810)) [@peterabarr](https://github.com/peterabarr)
- Updated _AAD Pod Identity_ chart to `4.1.15` (contains _AAD Pod Identity_ [v1.8.14](https://github.com/Azure/aad-pod-identity/releases/tag/v1.8.12)). ([#834](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/834)) [@hadeeds](https://github.com/hadeeds)
- Updated minimum version of the Helm provider to [v2.8.0](https://github.com/hashicorp/terraform-provider-helm/releases/tag/v2.8.0). ([#837](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/837)) [@aydosman](https://github.com/aydosman)
- Updated minimum version of the Kubernetes provider to [v2.15.0](https://github.com/hashicorp/terraform-provider-kubernetes/releases/tag/v2.15.0). ([#837](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/837)) [@aydosman](https://github.com/aydosman)
- Fixed bug to set the default value of the subdomain_suffix to the value of the cluster name. ([#830](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/830)) [@aydosman](https://github.com/aydosman)
- Updated _Thanos_ chart to [v1.9.1](https://github.com/stevehipwell/helm-charts/releases/tag/thanos-1.9.1). ([#843](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/843)) [@hadeeds](https://github.com/hadeeds)
  
## [v1.1.1] - 2022-12-20

### All Changes

- Fixed bug to set the default value of the subdomain_suffix to the value of the cluster name. ([#830](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/830)) [@aydosman](https://github.com/aydosman)

## [v1.1.0] - 2022-12-05

> **Warning**
> **DO NOT USE THIS VERSION** - Please use `v1.1.1` instead due to a bug in the subdomain where a default value wasn't set.

### Highlights

#### AKS v1.22 Removed

AKS cluster version `v1.22` has been removed as Azure is retiring it on December 4th 2022. Any clusters still running `v1.22` after this date, will be forced to upgrade their cluster to `v1.23` or above.

### All Changes

- Removed AKS cluster version `v1.22`. ([#773](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/773)) [@prikesh-patel](https://github.com/prikesh-patel)
- Updated _Fluent Bit_ chart to [v0.21.3](https://github.com/fluent/helm-charts/releases/tag/fluent-bit-0.21.3). ([#799](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/799)) [@peterabarr](https://github.com/peterabarr)
- Updated _Cert Manager_ chart to [1.10.1](https://github.com/cert-manager/cert-manager/releases/tag/v1.10.1). ([#796](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/796)) [@peterabarr](https://github.com/peterabarr)
- Updated _Kube Prometheus Stack_ chart to [v42.1.0](https://github.com/prometheus-community/helm-charts/releases/tag/kube-prometheus-stack-42.1.0) (contains _Kube State Metrics_ [v2.7.0](https://github.com/kubernetes/kube-state-metrics/releases/tag/v2.7.0). ([#789](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/789)) [@peterabarr](https://github.com/peterabarr)

## [v1.0.1] - 2022-12-20

### All Changes

- Fixed bug to set the default value of the subdomain_suffix to the value of the cluster name. ([#830](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/830)) [@aydosman](https://github.com/aydosman)

## [v1.0.0] - 2022-11-21

> **Warning**
> **DO NOT USE THIS VERSION** - Please use `v1.0.1` instead due to a bug in the subdomain where a default value wasn't set.

### Highlights

#### AKS v1.0.0 Release

The _AKS_ module has now transitioned from Beta to GA after a lot of hard work from the core team. More information can be found [here](https://start.emailopen.com/public1/viewlpauto.aspx?id1=cryptz2%3aEreYJizI7lk2IyXJspPRxA%3d%3d&id2=1048&id3=351289&id4=&id5=e3d4ff41ad3645c4874945f8ed844346ijsbGYJEujWKMNX.669160924%40emailopen.com).

#### AKS v1.24

Support for _AKS_ cluster version `v1.24` is now generally available.

#### Security Fixes

- The _Kube Prometheus Stack_ Helm chart update contains _Grafana_ [v9.2.4](https://github.com/grafana/grafana/releases/tag/v9.2.4) which fixes the following CVEs.
  - [CVE-2022-39328](https://nvd.nist.gov/vuln/detail/CVE-2022-39328)
  - [CVE-2022-39307](https://nvd.nist.gov/vuln/detail/CVE-2022-39307)
  - [CVE-2022-39306](https://nvd.nist.gov/vuln/detail/CVE-2022-39306)
- The _Ingress Nginx_ chart update contains the _Ingress Nginx Controller_ [v1.5.1](https://github.com/kubernetes/ingress-nginx/releases/tag/controller-v1.5.1) which fixes the following CVEs.
  - [CVE-2022-32149](https://github.com/advisories/GHSA-69ch-w2m2-3vjp)
  - [CVE-2022-27664](https://github.com/advisories/GHSA-69cg-p879-7622)
  - [CVE-2022-1996](https://github.com/advisories/GHSA-r48q-9g5r-8q2h)

#### Experimental Support

- [Azure AD Workload Identity](https://learn.microsoft.com/en-us/azure/aks/workload-identity-overview) has experimental support and can be enabled by setting the flag `experimental = { workload_identity = true }`, if you've opted in to the public preview.

### All Changes

- Fixed bug where the `terraform-modules` `ConfigMap` was being overwritten. [@stevehipwell](https://github.com/stevehipwell)
- Added experimental support for [Azure AD Workload identity](https://learn.microsoft.com/en-us/azure/aks/workload-identity-overview). ([#718](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/718)) [@stevehipwell](https://github.com/stevehipwell)
- Removed experimental support for AKS `v1.24`. ([#648](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/648)) [@prikesh-patel](https://github.com/prikesh-patel)
- Added GA support for AKS `v1.24`. ([#648](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/648)) [@prikesh-patel](https://github.com/prikesh-patel)
- Updated _Kube Prometheus Stack_ chart to [v41.7.4](https://github.com/prometheus-community/helm-charts/releases/tag/kube-prometheus-stack-41.7.4)(contains _Kube State Metrics_ [v4.22.3](https://github.com/prometheus-community/helm-charts/releases/tag/kube-state-metrics-4.22.3), _Grafana_ [v6.43.5](https://github.com/grafana/helm-charts/releases/tag/grafana-6.43.3)). ([#772](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/772)) [@peterabarr](https://github.com/peterabarr)
- Updated _Thanos_ chart to [v1.7.0](https://github.com/stevehipwell/helm-charts/releases/tag/thanos-1.7.0) (contains _Thanos_ [v0.29.0](https://github.com/thanos-io/thanos/releases/tag/v0.29.0)). ([#755](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/755)) [@peterabarr](https://github.com/peterabarr)
- Updated _Fluent Bit_ chart to [v0.21.0](https://github.com/fluent/helm-charts/releases/tag/fluent-bit-0.21.0) (contains _Fluent Bit_ [v2.0.4](https://github.com/fluent/fluent-bit/releases/tag/v2.0.4)). ([#771](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/771)) [@peterabarr](https://github.com/peterabarr)
- Updated _Ingress Nginx_ chart to [v4.4.0](https://github.com/kubernetes/ingress-nginx/releases/tag/helm-chart-4.4.0)(contains _Ingress Nginx Image_ [v1.21.6](https://github.com/kubernetes/ingress-nginx/releases/tag/controller-v1.21.6)). ([#770](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/770)) [@peterabarr](https://github.com/peterabarr)
- Added a script that fixes the Field Manager conflict error seen when building a cluster. ([#780](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/780)) [@peterabarr](https://github.com/peterabarr)
- Fixed bug for configuring _Grafana_ to use _Thanos Query Frontend_ as a datasource, instead of _Prometheus_. ([#787](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/787)) [@prikesh-patel](https://github.com/prikesh-patel)

## [v1.0.0-rc.2] - 2022-11-14

- Fix Alertmanager bug for routes config by removing `active_time_intervals`. ([#774](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/774)) [@peterabarr](https://github.com/peterabarr)

## [v1.0.0-rc.1] - 2022-11-07

> **Warning**
> **DO NOT USE THIS VERSION** - Please use `v1.0.0-rc.2` instead due to a bug in Alertmanager where the configuration cannot get updated.

> **Warning**
> The minimum Terraform version has been increased to `v1.3.3` to provide support for [optional object type attributes](https://developer.hashicorp.com/terraform/language/expressions/type-constraints#optional-object-type-attributes), please make sure that you update your Terraform versions to reflect this. Terraform `v1.3.4` is **NOT** supported due to a [bug](https://github.com/hashicorp/terraform/issues/32160) observed when working with complex optional object attributes.

> **Warning**
> According to the [AKS documentation](https://learn.microsoft.com/en-us/azure/aks/cluster-configuration#oidc-issuer) for the OIDC Issuer some pods might become stuck in a failed state after it has been enabled; you will need to manually re-start these.

### Highlights

#### AKS Module Release Candidate

This release is the first (and hopefully final) v1 release candidate and is a significant milestone in the journey to the GA `v1.0.0` release, which with all things going to plan should be released in 2 weeks time. Please could as many people as possible give this version a test as when we go to GA we're far more limited in the scope of the changes we can make to the module.

#### AKS Module Name Change

The AKS terraform module will be renamed to `rsg-terraform-azurerm-aks` to follow the correct naming standards before going GA. Any references to the old repository name should [continue to work](https://docs.github.com/en/repositories/creating-and-managing-repositories/renaming-a-repository) after this happens but end-users shouldn't rely on this assumption.

#### Terraform Optional Object Type Attributes

Terraform `v1.3` allows us to use [optional object type attributes](https://www.terraform.io/language/expressions/type-constraints#optional-object-type-attributes) for our complex input variables. This can simplify the code and allow end-users to pass in lists of maps of different types. The minimum terraform version has been set to `v1.3.3`. However, Terraform `v1.3.4` is **NOT** supported due to a [bug](https://github.com/hashicorp/terraform/issues/32160) observed when working with complex optional object attributes.

#### Security Fixes

The _Grafana_ `v9.2.0` image includes security fixes for [CVE-2022-39229](https://github.com/grafana/grafana/security/advisories/GHSA-gj7m-853r-289r), [CVE-2022-39201](https://github.com/grafana/grafana/security/advisories/GHSA-x744-mm8v-vpgr), [CVE-2022-31130](https://github.com/grafana/grafana/security/advisories/GHSA-jv32-5578-pxjc) & [CVE-2022-31123](https://github.com/grafana/grafana/security/advisories/GHSA-rhxj-gh46-jvw8).

#### Deprecated Attributes Removed

- Module input variable `node_group_templates`
- Module input variable `azuread_clusterrole_map`
- Module inputs `core_config.fluentd.routes` & `core_config.fluentd.outputs`

### All Changes

- Updated _Thanos_ chart to [v1.6.1](https://github.com/stevehipwell/helm-charts/releases/tag/thanos-1.6.2). ([#728](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/728)) [@hadeeds](https://github.com/hadeeds)
- Updated _Cert Manager_ chart to [1.10.0](https://github.com/cert-manager/cert-manager/releases/tag/v1.10.0). ([#732](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/732)) [@peterabarr](https://github.com/peterabarr)
- Fixed deprecation warning for `logs` attribute in `data.azurerm_monitor_diagnostic_categories.default.logs`. ([#649](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/649)) [@prikesh-patel](https://github.com/prikesh-patel)
- Fixed deprecation warning for `number` attribute in `random_password`. ([#646](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/646)) [@prikesh-patel](https://github.com/prikesh-patel)
- Updated minimum version of the Helm provider to [v2.6.0](https://github.com/hashicorp/terraform-provider-helm/releases/tag/v2.6.0). ([#730](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/730)) [@prikesh-patel](https://github.com/prikesh-patel)
- Updated minimum version of the Kubernetes provider to [v2.12.1](https://github.com/hashicorp/terraform-provider-kubernetes/releases/tag/v2.12.1). ([#730](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/730)) [@prikesh-patel](https://github.com/prikesh-patel)
- Removed module input variable `node_group_templates`. ([#741](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/741)) [@prikesh-patel](https://github.com/prikesh-patel)
- Removed module input variable `azuread_clusterrole_map`. ([#741](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/741)) [@prikesh-patel](https://github.com/prikesh-patel)
- Removed module inputs `core_config.fluentd.routes` & `core_config.fluentd.outputs`. ([#741](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/741)) [@prikesh-patel](https://github.com/prikesh-patel)
- Added the [AKS OIDC Issuer](https://learn.microsoft.com/en-us/azure/aks/cluster-configuration#oidc-issuer) in preparation for supporting [Azure AD Workload Identity](https://learn.microsoft.com/en-us/azure/aks/workload-identity-overview). ([#747](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/747)) [@stevehipwell](https://github.com/stevehipwell)
- Updated _Fluent Bit_ chart to [v0.20.10](https://github.com/fluent/helm-charts/releases/tag/fluent-bit-0.20.10). ([#744](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/744)) [@hadeeds](https://github.com/hadeeds)
- Updated _Kube Prometheus Stack_ chart to [v41.7.3](https://github.com/prometheus-community/helm-charts/releases/tag/kube-prometheus-stack-41.7.0)(contains _Kube State Metrics_ [v4.22.1](https://github.com/prometheus-community/helm-charts/releases/tag/kube-state-metrics-4.22.1), _Grafana_ [v6.43.3](https://github.com/grafana/helm-charts/releases/tag/grafana-6.43.3), _Prometheus Node Exporter_ [v4.4.2](https://github.com/prometheus-community/helm-charts/releases/tag/prometheus-node-exporter-4.4.2), _Prometheus Operator_ [v0.60.1](https://github.com/prometheus-operator/prometheus-operator/releases/tag/v0.60.1), _Prometheus_ [v2.39.1](https://github.com/prometheus/prometheus/releases/tag/v2.39.1)). ([#658](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/658)) [@peterabarr](https://github.com/peterabarr)
- Updated minimum Terraform version to [v1.3.3](https://github.com/hashicorp/terraform/releases/tag/v1.3.3) so we can support [optional object type attributes](https://developer.hashicorp.com/terraform/language/expressions/type-constraints#optional-object-type-attributes). ([#673](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/673)) [@prikesh-patel](https://github.com/prikesh-patel)
- Changed module input variables to not be nullable unless they explicitly can be. ([#673](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/673)) [@prikesh-patel](https://github.com/prikesh-patel)
- Changed `node_groups` module variable to strongly typed. ([#673](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/673)) [@prikesh-patel](https://github.com/prikesh-patel)
- Changed `core_services_config` module variable to strongly typed. ([#673](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/673)) [@prikesh-patel](https://github.com/prikesh-patel)
- Changed `experimental` module variable to strongly typed. ([#673](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/673)) [@prikesh-patel](https://github.com/prikesh-patel)
- Changed minimum value for `node_groups.max_pods` to `12`. [@prikesh-patel](https://github.com/prikesh-patel)
- Removed support for Terraform version [v1.3.4](https://github.com/hashicorp/terraform/releases/tag/v1.3.4) due to errors when working with complex optional object attributes. [@prikesh-patel](https://github.com/prikesh-patel)
- Deprecated AKS cluster version `v1.22`. ([#757](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/757)) [@prikesh-patel](https://github.com/prikesh-patel)

## [v1.0.0-beta.26] - 2022-11-04

> **Warning**
> Applying this module version may trigger a bug in the helm provider for the Kube Prometheus Stack helm release, due to its values being updated. To get around this, you can re-apply your terraform configuration.

### Highlights

The `v1.0.0-beta.26` release is a patch fix for a bug to make storage account names globally unique in Azure by adding a random string suffix to the storage account name.

### All Changes

- Fixed bug which caused potential duplicates of storage account names by adding a random string as a suffix to the storage account name. ([#749](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/749)) [@prikesh-patel](https://github.com/prikesh-patel)
- Fixed bug causing AzureCNI node groups to have an incorrect `max_pods` set unless actively using the `azure_cni_max_pods` experiment. ([#754](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/754)) [@stevehipwell](https://github.com/stevehipwell)

## [v1.0.0-beta.25] - 2022-10-28

> **Warning**
> **DO NOT USE THIS VERSION** - Please use `v1.0.0-beta.26` instead due to a bug with storage account name conflicting due to not being globally unique.

> **Warning**
> Applying this module version may trigger a bug in the helm provider for the Kube Prometheus Stack helm release, due to its values being updated. To get around this, you can re-apply your terraform configuration.

### Highlights

The `v1.0.0-beta.25` release is a patch fix for a bug where long cluster names can cause the storage account name to exceed its character limit of 25 characters. When upgrading from [v1.0.0-beta.24](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/releases/tag/v1.0.0-beta.24), the existing storage account will be deleted and replaced due to its name being shortened.

### All Changes

- Fixed bug with storage account names exceeding the character limit by shortening the storage account name. ([#735](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/735)) [@prikesh-patel](https://github.com/prikesh-patel)

## [v1.0.0-beta.24] - 2022-10-24

> **Warning**
> **DO NOT USE THIS VERSION** - Please use `v1.0.0-beta.26` instead due to a bug with storage account name exceeding the character limit for long cluster names, and storage account name conflicting due to not being globally unique.

> **Warning**
> A storage account is created with the Thanos deployment which has network rules set to deny by default. A [service endpoint](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview) will need to be added to your subnet [resource](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet#service_endpoints).globally unique.

> **Warning**
> Applying this module version may trigger a bug in the helm provider for the Kube Prometheus Stack helm release, due to its values being updated. To get around this, you can re-apply your terraform configuration.

> **Warning**
> Introducing Thanos allows the Prometheus volume to largely reduce its size. However, this large volume will remain unless the Kube Prometheus Stack chart is removed and the volume is deleted, before applying this module upgrade. Check the Azure disk also gets deleted after removing the volume claims. Alternatively, you can upgrade and reinstall the helm chart and volume in a maintenance window. This would mean the existing metrics will be kept with just an outage period for the reinstallation.
>
> ```shell
> # Remove helm release
> helm delete -n monitoring kube-prometheus-stack
>
> # Remove persistent volume claim
> kubectl delete pvc -n monitoring prometheus-kube-prometheus-stack-prometheus-db-prometheus-kube-prometheus-stack-prometheus-0
> ```

### Highlights

The `v1.0.0-beta.24` release is an incremented beta release. This includes adding support for _Thanos_, improvements to the _Fluentd_ route configuration, updated AKS versions, core service chart updates, and support for several experimental features.

Thanks to [@stevehipwell](https://github.com/stevehipwell) and the whole IOG Systems Engineering team for their hard work on this release.

#### Thanos Support

Thanos is now installed as a core service as the implementation for HA Prometheus. A service endpoint may need adding to the subnets, to enable connect to the storage account. The _Kube Prometheus Stack_ and its volumes will also need to be deleted, so a volume with a smaller size can be used for _Prometheus_ data.

#### Structured Fluentd Route Configuration

Configuring Fluentd with a structured route configuration makes it easier to route logs to the desired destination by removing the possibility of not having matching route and output configurations (it is also a prerequisite to updating to the latest Fluentd Aggregator Helm chart). Swapping to `route_config` from `routes` & `outputs` should be as simple as moving the configuration from the strings into a list of structured objects.

<details><summary>Comparison of a Fluentd configuration using the old routes & outputs, and a configuration using the new route_config.</summary>

```terraform
# Using routes & outputs
fluentd = {
  routes  = <<-EOT
    <route **>
      copy
      @label @example
    </route>
  EOT
  outputs = <<-EOT
    <label @example>
      <match **>
        @type null
      </match>
    </label>
  EOT
}
```

```terraform
# Using route_config
fluentd = {
  route_config = [{
    match = "**"
    label = "@example"
    copy = true
    config = <<-EOT
      <match **>
        @type null
      </match>
    EOT
  }]
}
```

</details>

#### Updated AKS versions

The AKS versions have been patched; `v1.24.3` to `1.24.6`, `v1.23.8` to `v1.23.12` & `v1.22.11` to `v1.22.15`. These changes fix a number of CVEs & defects and keep the AKS version supported by Azure.

#### Experimental ARM64 Support

The experimental ARM64 node support allows end-users to test running their workloads on [Ampere Altra](https://azure.microsoft.com/en-us/blog/azure-virtual-machines-with-ampere-altra-arm-based-processors-generally-available/) based ARM64 nodes.

#### Experimental Features

- Experimental support for Fluentd memory buffers can be enabled by setting `experimental = { fluent_bit_use_memory_buffer = true }`.
- Experimental support to increase resources for Fluentd and Prometheus can be through `experimental.fluentd_memory_override` and `experimental.prometheus_memory_override`.

### All Changes

- Added Thanos to support HA Prometheus in cluster. ([#160](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/160)) [@prikesh-patel](https://github.com/prikesh-patel)
- Updated full AKS versions which include patch versions for `1.24` to `1.24.6`, `v1.23` to `v1.23.12` & `v1.22` to `v1.22.15`. [@peterabarr](https://github.com/peterabarr)
- Changed _Ingress Internal Core_ admission webhook port to `10250`. [#697](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/697) [@prikesh-patel](https://github.com/prikesh-patel)
- Removed support for the Helm provider [v2.7.0](https://github.com/hashicorp/terraform-provider-helm/releases/tag/v2.7.0) and [v2.7.1](https://github.com/hashicorp/terraform-provider-helm/releases/tag/v2.7.1) due to it being buggy. ([#699](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/699)) [@prikesh-patel](https://github.com/prikesh-patel)
- Updated _Ingress Nginx_ chart to [v4.3.0](https://github.com/kubernetes/ingress-nginx/releases/tag/helm-chart-4.3.0)(contains _Ingress Nginx Image_ [v1.4.0](https://github.com/kubernetes/ingress-nginx/releases/tag/controller-v1.4.0)). ([#681](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/681)) [@peterabarr](https://github.com/peterabarr)
- Added experimental support for ARM64 nodes. ([#704](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/704)) [@stevehipwell](https://github.com/stevehipwell)
- Added Alertmanager data source to Grafana to allow the UI to show Prometheus alerts and the configuration (the Grafana pod needs starting to pick up the data source changes). ([#554](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/554)) [@stevehipwell](https://github.com/stevehipwell)
- Added experimental support to run Fluent Bit with memory buffers to work around a defect. [@aydosman](https://github.com/aydosman)
- Added experimental options to override service memory requests for specific services. ([#486](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/486)) [@aydosman](https://github.com/aydosman)
- Updated _AAD Pod Identity_ chart to [v4.1.14](https://artifacthub.io/packages/helm/aad-pod-identity/aad-pod-identity/4.1.14) (contains _AAD Pod Identity_ [v1.8.13](https://github.com/Azure/aad-pod-identity/releases/tag/v1.8.12)). ([#701](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/701)) [@peterabarr](https://github.com/peterabarr)
- Updated Fluentd metadata processing to better capture `app` (this was missed when the change was made to EKS). [@stevehipwell](https://github.com/stevehipwell)
- Added new `core_config.fluentd.route_config` module variable to enable strongly typed Fluentd output configuration. [@stevehipwell](https://github.com/stevehipwell)
- Deprecated `core_config.fluentd.routes` & `core_config.fluentd.outputs` module variables in favour of the new `core_config.fluentd.route_config` module variable. [@stevehipwell](https://github.com/stevehipwell)
- Added experimental support for defining a custom maximum number of pods per node group when using the Azure CNI. ([#712](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/712)) [@stevehipwell](https://github.com/stevehipwell)

## [v1.0.0-beta.18.1] - 2022-10-14

> **Warning**
> Once applying this patch version, you should upgrade directly to `v1.0.0-beta.23`. To avoid the AKS version being downgraded, the minimum version you can upgrade to is `v1.0.0-beta.20`.

### All Changes

- Updated AKS versions which include patch versions for `v1.23` to `v1.28.8` & `v1.22` to `v1.22.11`. [@prikesh-patel](https://github.com/prikesh-patel)

## [v1.0.0-beta.23] - 2022-10-10

### Highlights

_Fluent Bit_ Helm Chart was updated to `v0.20.9` which was the only core service updated in this release.

#### User Defined NAT Gateway

A user defined NAT gateway can now be configured with the `nat_gateway_id` module input. The two modes of network outbound traffic from the pods can be through a [load balancer](https://learn.microsoft.com/en-us/azure/load-balancer/load-balancer-overview) or a [managed NAT gateway](https://learn.microsoft.com/en-us/azure/aks/nat-gateway). The load balancer is configured by AKS within the module, while the NAT gateway needs to be configured externally.

#### Experimental Features

- Experimental support for [OS customization](https://learn.microsoft.com/en-us/azure/aks/custom-node-configuration#linux-os-custom-configuration) can be enabled by setting `experimental = { node_group_os_config = true }` and then an `os_config` block to applicable `node_groups`.

### All Changes

- Added support for user defined NAT gateway. ([#620](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/620), [#623](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/623)) [@prikesh-patel](https://github.com/prikesh-patel)
- Updated _Fluent Bit_ chart to [v0.20.9](https://github.com/fluent/helm-charts/releases/tag/fluent-bit-0.20.9) (contains _Fluent Bit_ [v1.9.9](https://github.com/fluent/fluent-bit/releases/tag/v1.9.9)). ([#683](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/683)) [@peterabarr](https://github.com/peterabarr)
- Added experimental support for [OS customization](https://learn.microsoft.com/en-us/azure/aks/custom-node-configuration#linux-os-custom-configuration), enabled by setting `experimental = { node_group_os_config = true }` and then an `os_config` block to applicable `node_groups`. ([667](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/667), [#686](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/686)) [@jamurtag](https://github.com/jamurtag)

## [v1.0.0-beta.22] - 2022-09-26

> **Warning**
> Terraform [v1.3.1](https://github.com/hashicorp/terraform/releases/tag/v1.3.1) was released shortly after `v1.0.0-beta.22` was released. It is recommended to use this Terraform version as it fixes issues mentioned below. When using Terraform `v1.3.1`, no cycle error occurs when carrying out the AKS module upgrade and no additional manual steps are required.

> **Warning**
> There is a bug in Terraform [v1.3.0](https://github.com/hashicorp/terraform/releases/tag/v1.3.0) which is likely to cause an [error](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/672) when applying the latest release, after running the manual deletions below. Pinning Terraform [v1.2.9](https://github.com/hashicorp/terraform/releases/tag/v1.2.9) should allow the upgrade to complete without any errors, or you can run TF apply a second time to get around the error.

> **Warning**
> The following cluster roles and cluster role bindings will need to be deleted before applying this release. You will need cluster admin access to do this.
>
> ```shell
> kubectl delete clusterrole 'lnrs:cluster-view' 'lnrs:node-view' 'lnrs:view'
> kubectl delete clusterrolebinding 'lnrs:cluster-view' 'lnrs:standard-view'
> ```

### Highlights

Fluent Bit and AAD Pod Identity helm charts were updated in this release.

#### RBAC

The RBAC binding logic has been updated to use the built in `view` `ClusterRole` and adds support to aggregate on top of the built in `ClusterRoles`. User access can be granted by passing the users and groups into the `rbac_bindings` module input variable.

#### Deprecations

- The `azuread_clusterrole_map` input variable has been deprecated in favour of the new `rbac_bindings` input variable.

### All Changes

- Updated the RBAC bindings to use the new `rbac_bindings` input variable. [@stevehipwell](https://github.com/stevehipwell)
- Changed all viewers specified via `azuread_clusterrole_map` to be bound to the `view` `ClusterRole` instead of our own custom `ClusterRoles`, this fixes a potential privilege escalation with the previous implementation. [@stevehipwell](https://github.com/stevehipwell)
- Deprecated the `azuread_clusterrole_map` input variable in favour of the new `rbac_bindings` input variable. [@stevehipwell](https://github.com/stevehipwell)
- Updated _AAD Pod Identity_ chart to `4.1.13` (contains _AAD Pod Identity_ [v1.8.12](https://github.com/Azure/aad-pod-identity/releases/tag/v1.8.12)). ([#654](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/654)) [@peterabarr](https://github.com/peterabarr)
- Updated _Fluent Bit_ chart to [v0.20.8](https://github.com/fluent/helm-charts/releases/tag/fluent-bit-0.20.8) (contains _Fluent Bit_ [v1.9.8](https://github.com/fluent/fluent-bit/releases/tag/v1.9.8)). ([#663](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/663)) [@peterabarr](https://github.com/peterabarr)

## [v1.0.0-beta.21] - 2022-09-12

> **Warning**
> If you're using the `lnrs.io_terraform-module-version` AKS cluster tag please be aware that the `v` prefix has been removed.

> **Warning**
> Updated the minimum version of the [AzureRM](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs) Terraform provider to `v3.21.1`.

### Highlights

The Kube Prometheus Stack and Ingress Nginx helm charts were updated in this release.

#### Experimental Features

- AKS `v1.24` (see [Kubernetes v1.24 release announcement](https://kubernetes.io/blog/2022/05/03/kubernetes-1-24-release-announcement/) for more details) is supported as an experimental feature and can be enabled by setting `experimental = { v1_24 = true }` and then setting `cluster_version` to `1.24`.

### All Changes

- Updated the `azurerm` Terraform provider to [v3.21.1](https://github.com/hashicorp/terraform-provider-azurerm/releases/tag/v3.21.1) to support AKS v1.24. [@stevehipwell](https://github.com/stevehipwell)
- Added experimental support for AKS v1.24; this can be enabled by setting `experimental = { v1_24 = true }` and then setting `cluster_version` to `"1.24"`. ([#599](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/599)) [@stevehipwell](https://github.com/stevehipwell)
- Updated _Kube Prometheus Stack_ chart to [v39.11.0](https://github.com/prometheus-community/helm-charts/releases/tag/kube-prometheus-stack-39.11.0). ([#641](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/641)) [@peterabarr](https://github.com/peterabarr)
- Updated the _Ingress Nginx_ chart to [v4.2.5](https://github.com/kubernetes/ingress-nginx/releases/tag/helm-chart-4.2.5) (contains _Ingress Nginx Image_ [v1.3.1](https://github.com/kubernetes/ingress-nginx/releases/tag/controller-v1.3.1)). ([#650](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/650)) [@peterabarr](https://github.com/peterabarr)
- Added creation metadata to help with cluster maintenance. [@stevehipwell](https://github.com/stevehipwell)
- Fixed module version syntax to remove erroneous `v` prefix. [@stevehipwell](https://github.com/stevehipwell)
- Added `terraform-modules` `ConfigMap` to the `default` namespace to register the installed module versions. [@stevehipwell](https://github.com/stevehipwell)

## [v1.0.0-beta.20] - 2022-08-31

### Highlights

#### Updated AKS Versions

The full AKS versions have been updated which include patch versions for `v1.23` to `v1.23.8` & `v1.22` to `v1.22.11`. This will trigger an automatic rollout of all nodes in the cluster.

#### CoreDNS Custom Config Map

Users have additional control over the CoreDNS custom confimap. The additional module outputs `coredns_custom_config_map_name` & `coredns_custom_config_map_namespace` can be exported and used to add data to the configmap outside the module by using one or more `kubernetes_config_map_v1_data` resources.

#### Internal Ingress Pod Scheduling

If you are provisioning any ingress nodes through the `node_groups` or `node_group_templates` variables, the core internal ingress pods will schedule onto these nodes automatically.

Any core internal ingress pods will now run on ingress nodes, if any have been provisioned in the cluster. This is done by detecting any ingress nodes being passed in through the `node_groups` input variable. If no ingress nodes are provisioned, the core internal ingress pods will continue to run on system nodes.

#### Experimental Features

- Using a user-assigned NAT Gateway for cluster egress is supported as an experimental feature. This can be enabled by setting `experimental = { nat_gateway_id = "<nat_gateway_id>" }`.
experimental support for using a user-assigned NAT Gateway for cluster egress traffic by setting `experimental = { nat_gateway_id = "<nat_gateway_id>" }`

### All Changes

- Added `lnrs.io/k8s-platform = true` common label to most k8s resources that allow custom labels via the Helm chart. ([#302](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/302)) [@prikesh-patel](https://github.com/prikesh-patel)
- Updated _Fluent Bit_ chart to [v0.20.6](https://github.com/fluent/helm-charts/releases/tag/fluent-bit-0.20.6) (contains _Fluent Bit_ [v1.9.7](https://github.com/fluent/fluent-bit/releases/tag/v1.9.7)). ([#607](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/607), [#625](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/625)) [@peterabarr](https://github.com/peterabarr) [@prikesh-patel](https://github.com/prikesh-patel)
- Updated _External DNS_ chart to [v1.11.0](https://github.com/kubernetes-sigs/external-dns/releases/tag/external-dns-helm-chart-1.11.0) (contains _External DNS_ [v0.12.2](https://github.com/kubernetes-sigs/external-dns/releases/tag/v0.12.2)). ([#608](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/issues/608)) [@prikesh-patel](https://github.com/prikesh-patel)
- Updated the _Ingress Nginx_ chart to [v4.2.3](https://github.com/kubernetes/ingress-nginx/releases/tag/helm-chart-4.2.3). ([#626](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/626)) [@prikesh-patel](https://github.com/prikesh-patel)
- Updated _Kube Prometheus Stack_ chart to [v39.9.0](https://github.com/prometheus-community/helm-charts/releases/tag/kube-prometheus-stack-39.9.0). ([#606](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/606)) [@prikesh-patel](https://github.com/prikesh-patel)
- Updated full AKS versions for `v1.23` to `v1.23.8` & `v1.22` to `v1.22.11`. ([#600](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/600)) [@stevehipwell](https://github.com/stevehipwell)
- Added `managed_outbound_ports_allocated` & `managed_outbound_idle_timeout` variables to enable further configuration of the cluster load balancer for egress. ([#618](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/618)) [@stevehipwell](https://github.com/stevehipwell)
- Changed default for cluster load balancer `outbound_idle_timeout` from `1800` to `240`. ([#618](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/618)) [@stevehipwell](https://github.com/stevehipwell)
- Added experimental support for using a user-assigned NAT Gateway for cluster egress traffic by setting `experimental = { nat_gateway_id = "<nat_gateway_id>" }`. ([#623](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/623)) [@stevehipwell](https://github.com/stevehipwell)
- Added support for running internal core ingress pods on ingress nodes. ([#567](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/567)) [@prikesh-patel](https://github.com/prikesh-patel)
- Added module outputs `coredns_custom_config_map_name` & `coredns_custom_config_map_namespace` to allow adding additional data to the CoreDNS custom `ConfigMap`. ([#581](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/581)) [@stevehipwell](https://github.com/stevehipwell)
- Fixed labels and taints for node group type `amd64-cpu`. ([#634](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/634)) [@prikesh-patel](https://github.com/prikesh-patel)

## [v1.0.0-beta.19] - 2022-08-15

### Highlights

The `v1.0.0-beta.19` release is a minor release of the Azure AKS Terraform Module. FIPS experimental support and Azure ultra disk support has been added. Several core service charts and images have been updated.

To discuss any topics regarding this release, please refer to the [AKS Release v1.0.0-beta.19 Discussion](https://github.com/LexisNexis-RBA/rsg-kubernetes/discussions/22).

#### FIPS

Experimental support for FIPS 140-2 has been added. This can be enabled by setting the `experimental = { fips = true }` module input.

#### Azure Ultra Disks

Azure ultra disks can be enabled on a node group by setting `ultra_ssd` to `true`, within the `node_groups` variable.

#### Latest Chart versions

The `v1.0.0-beta.19` release brings chart and image updates to _AAD Pod Identity_, _Ingress Nginx_ & _Kube Prometheus Stack_.

Thank you to [@stevehipwell](https://github.com/stevehipwell) and [@peterabarr](https://github.com/peterabarr) for their contributions.

### All Changes

- Added experimental support for FIPS 140-2 via the `experimental = { fips = true }` module input. ([#593](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/593)) [@stevehipwell](https://github.com/stevehipwell)
- Added support for enabling [Azure ultra disks](https://docs.microsoft.com/en-gb/azure/aks/use-ultra-disks) on a node group by setting `ultra_ssd` to `true`. ([#382](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/382)) [@stevehipwell](https://github.com/stevehipwell)
- Updated _AAD Pod Identity_ chart to `4.1.12` (contains _AAD Pod Identity_ [v1.8.11](https://github.com/Azure/aad-pod-identity/releases/tag/v1.8.11)). ([#591](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/591)) [@peterabarr](https://github.com/peterabarr)
- Updated _Ingress Nginx_ chart to [v4.2.1](https://github.com/kubernetes/ingress-nginx/releases/tag/helm-chart-4.2.1)(contains _Ingress Nginx Image_ [v1.3.0](https://github.com/kubernetes/ingress-nginx/releases/tag/controller-v1.3.0)). ([#597](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/597)) [@peterabarr](https://github.com/peterabarr)
- Updated _Kube Prometheus Stack_ chart to [v39.5.0](https://github.com/prometheus-community/helm-charts/releases/tag/kube-prometheus-stack-39.5.0) (contains _Grafana_ [v9.0.5](https://github.com/grafana/grafana/releases/tag/v9.0.5) & _Prometheus Operator_ [v0.58.0](https://github.com/prometheus-operator/prometheus-operator/releases/tag/v0.58.0). ([#582](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/582)) [@peterabarr](https://github.com/peterabarr)

## [v1.0.0-beta.18] - 2022-08-01

### Highlights

The 'v1.0.0-beta.18' release is a minor release of the Azure AKS Terraform Module. Support for Kubernetes v1.21 has been removed. Deprecated `node_group_templates` in favour of `node_groups`. The core services were updated to their latest chart versions.

### Latest Chart versions

The v1.0.0-beta.18 release includes the following chart version updates: _Fluent Bit_, _Kube Prometheus Stack_ and _Cert Manager_.

Thank you to [@stevehipwell](https://github.com/stevehipwell), [@prikesh-patel](https://github.com/prikesh-patel), [@james1miller93](https://github.com/james1miller93) and [@peterabarr](https://github.com/peterabarr) for their contributions.

### All Changes

> **Important**
> Ingress internal core load balancer configuration was previously incorrect. This may require manually deleting the `core-internal` helm release before reinstating via the module. If it's not safe to do this immediately, we advise setting the load balancer subnet name manually using the `core_services_config.ingress_internal_core.lb_subnet_name` input until the loadbalancer can be recreated safely. See [issue 499](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/499) for more detail.

#### Added

- Added new `node_groups` input variable to replace `node_group_templates`; this variable is a map and supports default values for simplicity. (#511) [@stevehipwell](https://github.com/stevehipwell)
- Add support for the [Lsv3](https://docs.microsoft.com/en-us/azure/virtual-machines/lsv3-series) series for storage optimised VMs. (#465) [@prikesh-patel](https://github.com/prikesh-patel)

#### Changed

- Changed the README to show all default values for variables. [@stevehipwell](https://github.com/stevehipwell)
- Changed the README to show no value in the default column in the variable grids if a user defined value is required. [@stevehipwell](https://github.com/stevehipwell)
- Revert change from `beta.10` where subnet annotation was added to `ingress-internal-core` loadbalancer configuration, creating undesirable behaviour. [@james1miller93](https://github.com/james1miller93)

#### Updated

- Update _Fluent Bit_ chart to [v0.20.4](https://github.com/fluent/helm-charts/releases/tag/fluent-bit-0.20.4) (contains _Fluent Bit_ [v1.9.6](https://github.com/fluent/fluent-bit/releases/tag/v1.9.6)). ([#559](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/559)) [@peterabarr](https://github.com/peterabarr)
- Update _Kube Prometheus Stack_ chart to [v38.0.2](https://github.com/prometheus-community/helm-charts/releases/tag/kube-prometheus-stack-38.0.2)(contains _Grafana_ [v6.32.7](https://github.com/grafana/helm-charts/releases/tag/grafana-6.32.7))). ([#564](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/564)) [@peterabarr](https://github.com/peterabarr)
- Update _Cert Manager_ chart to [1.9.1](https://github.com/cert-manager/cert-manager/releases/tag/v1.9.1). ([#571](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/571)) [@peterabarr](https://github.com/peterabarr)

#### Fixed

- Fixed OMS Agent config namespaces. ([#577](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/577)) [@stevehipwell](https://github.com/stevehipwell)

#### Deprecated

- Deprecated `node_group_templates` in favour of `node_groups`. Switching to the new variable is as simple as creating a map with the name of the old object as the key and the rest of the object as the body, many of the fields can be omitted if you're using the defaults. ([#511](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/511)) [@stevehipwell](https://github.com/stevehipwell)

#### Removed

- Dropped support for Kubernetes version v1.21 following recent [announcement](https://github.com/Azure/AKS/releases/tag/2022-06-26.1). (#519) [@sossickd](https://github.com/sossickd)

## [v1.0.0-beta.17] - 2022-07-18

### Added

- Add ability to create custom folders in Grafana. (#357) [@sossickd](https://github.com/sossickd)

### Updated

- Update _Kube Prometheus Stack_ chart to [v37.2.0](https://github.com/prometheus-community/helm-charts/releases/tag/kube-prometheus-stack-37.2.0)(contains _Kube State Metrics_ [v4.13.0](https://github.com/prometheus-community/helm-charts/releases/tag/kube-state-metrics-4.13.0), _Grafana_ [v6.32.2](https://github.com/grafana/helm-charts/releases/tag/grafana-6.32.2)). (#515) [@peterabarr](https://github.com/peterabarr)
- Update _Fluent Bit_ chart to [v0.20.3](https://github.com/fluent/helm-charts/releases/tag/fluent-bit-0.20.3) (contains _Fluent Bit_ [v1.9.5](https://github.com/fluent/fluent-bit/releases/tag/v1.9.5)). (#506) [@peterabarr](https://github.com/peterabarr)
- Update _External DNS_ chart to [v1.10.1](https://github.com/kubernetes-sigs/external-dns/releases/tag/external-dns-helm-chart-1.10.1) (contains _External DNS_ [v0.12.0](https://github.com/kubernetes-sigs/external-dns/releases/tag/v0.12.0)). (#543) [@peterabarr](https://github.com/peterabarr)

### Fixed

- Fixed `ingress-nginx-core-internal` grafana dashboard (#541) [@james1miller93](https://github.com/james1miller93)

## [v1.0.0-beta.16] - 2022-07-07

### Added

- Added support for [AKS v1.22](https://docs.microsoft.com/en-us/azure/aks/supported-kubernetes-versions?tabs=azure-cli). (#518) [@sossickd](https://github.com/sossickd)
- New variable `managed_outbound_ip_count`. [@prikesh-patel](https://github.com/prikesh-patel)

### Changed

- Increase _Cert Manager_ `startupapicheck` timeout. [@prikesh-patel](https://github.com/prikesh-patel)

### Updated

- The _AAD Pod Identity_ chart has been upgraded to `4.1.11` (contains [v1.8.10](https://github.com/Azure/aad-pod-identity/releases/tag/v1.8.10) of the aad-pod-identity image). [@peterabarr](https://github.com/peterabarr)

### Fixed

- Fixed `kube-audit-admin` and `AllMetrics` being incorrectly re-enabled in external storage account. [@prikesh-patel](https://github.com/prikesh-patel)
- Fixed a bug introduced in v1.0.0-beta.15 where operators could not create a cluster from scratch. (#525) [@prikesh-patel](https://github.com/prikesh-patel)

## [v1.0.0-beta.15] - 2022-07-05

> **IMPORTANT**
> Control plane logging has been made fully configurable in this release so if you're currently overriding the defaults you will need to use the new variables to continue to do this (the behaviour is consistent). The main changes have been to allow control plane logs to be sent to a custom log analytics workspace, and to enable custom retention to be specified alongside the log categories to collect.

### Added

- Added CIDR validation to `var.cluster_endpoint_access_cidrs`. [@james1miller93](https://github.com/james1miller93)
- Added [ZeroSSL](https://zerossl.com/features/acme/) cluster issuer. (#365) [@sossickd](https://github.com/sossickd)
- Added control plane logging customisation via the `control_plane_logging_external_workspace`, `control_plane_logging_external_workspace_id`, `control_plane_logging_external_workspace_different_resource_group`, `control_plane_logging_workspace_categories`, `control_plane_logging_workspace_retention_enabled`, `control_plane_logging_workspace_retention_days`, `control_plane_logging_storage_account_enabled`, `control_plane_logging_storage_account_id`, `control_plane_logging_storage_account_categories`, `control_plane_logging_storage_account_retention_enabled` & `control_plane_logging_storage_account_retention_days` input variables. (#474) [@stevehipwell](https://github.com/stevehipwell)

### Changed

- Changed default retention for control plane logs sent to a storage account from 7 days to 30 days. (#474) [@stevehipwell](https://github.com/stevehipwell)
- Increased the _Grafana_ memory request/limit to support more intensive dashboards. (#516) [@prikesh-patel](https://github.com/prikesh-patel)
- Improved the _AKS Control Plane Logs_ _Grafana_ dashboard. [@prikesh-patel](https://github.com/prikesh-patel)

### Updated

- Update _Cert Manager_ chart to [1.8.2](https://github.com/cert-manager/cert-manager/releases/tag/v1.8.2). (#504) [@sossickd](https://github.com/sossickd)
- Updated _Kube Prometheus Stack_ chart to [v36.2.0](https://github.com/prometheus-community/helm-charts/releases/tag/kube-prometheus-stack-36.2.0) (contains _Grafana_ [v9.0.1](https://github.com/grafana/grafana/releases/tag/v9.0.1)). (#498) [@peterabarr](https://github.com/peterabarr)

### Fixed

- Fixed output `effective_outbound_ips` to provide correct value. [@prikesh-patel](https://github.com/prikesh-patel)

## Deprecated

- Deprecated Kubernetes version v1.21 following recent [announcement](https://github.com/Azure/AKS/releases/tag/2022-06-26.1). (#519) [@sossickd](https://github.com/sossickd)

## Removed

- Removed `logging_storage_account_enabled` & `logging_storage_account_id` input variables in favour of the new `control_plane_logging_storage_account_enabled` & `control_plane_logging_storage_account_id` input variables. (#474) [@stevehipwell](https://github.com/stevehipwell)
- Removed experimental `workspace_log_categories` & `storage_log_categories` settings in favour of the new control plane logging input variables. (#474) [@stevehipwell](https://github.com/stevehipwell)

## [v1.0.0-beta.14] - 2022-06-20

### Added

- Added `azure-disk-standard-ssd-ephemeral` and `azure-disk-premium-ssd-ephemeral` storage classes to support generic ephemeral volumes. [@james1miller93](https://github.com/james1miller93)
- Set `kube_token_ttl` to 600 in `Fluent-bit` configuration. [@peterabarr](https://github.com/peterabarr)
- Added default OMS agent configuration to block it capturing logs from core namespaces, this can be overridden by setting the `oms_agent_create_configmap` experimental argument to `false`. [@stevehipwell](https://github.com/stevehipwell)

### Changed

- Changed the `systemd` configuration paramater from `db_sync` to `db.sync`. [@peterabarr](https://github.com/peterabarr)
- Increase resources for _Kube Prometheus Stack/Kube State Metrics_. [@aydosman](https://github.com/aydosman)

### Updated

- Updated _Kube Prometheus Stack_ chart to [v36.0.2](https://github.com/prometheus-community/helm-charts/releases/tag/kube-prometheus-stack-36.0.2)(contains _Kube State Metrics_ [v4.9.0](https://github.com/prometheus-community/helm-charts/releases/tag/kube-state-metrics-4.9.0), _Grafana_ [v6.29.6](https://github.com/grafana/helm-charts/releases/tag/grafana-6.29.6), _Prometheus Node Exporter_ [v3.3.0](https://github.com/prometheus-community/helm-charts/releases/tag/prometheus-node-exporter-3.3.0), _Prometheus Operator_ [v0.57.0](https://github.com/prometheus-operator/prometheus-operator/releases/tag/v0.57.0), _Prometheus_ [v2.36.1](https://github.com/prometheus/prometheus/releases/tag/v2.36.1)). (#458) [@peterabarr](https://github.com/peterabarr)
- Updated _Fluent Bit_ chart to [v0.20.2](https://github.com/fluent/helm-charts/releases/tag/fluent-bit-0.20.2) (contains _Fluent Bit_ [v1.9.4](https://github.com/fluent/fluent-bit/releases/tag/v1.9.4)). (#461) [@peterabarr](https://github.com/peterabarr)
- The _Ingress Nginx_ chart has been upgraded to [v4.1.1](https://github.com/kubernetes/ingress-nginx/releases/tag/helm-chart-4.1.1)(contains _Ingress Nginx Image_ [v1.2.1](https://github.com/kubernetes/ingress-nginx/releases/tag/controller-v1.2.1)). (#459) [@peterabarr](https://github.com/peterabarr)

## [v1.0.0-beta.13] - 2022-06-09

> **IMPORTANT**
> `logging_storage_account_enabled` must be set to `true` when passing `logging_storage_account_id` as an input.

### Changed

- Fixed bug where count cannot be determined until apply when `logging_storage_account_id` is input and storage account is created alongside cluster. [@james1miller93](https://github.com/james1miller93)

## [v1.0.0-beta.12] - 2022-06-06

### Added

- Added experimental support to specify the set of control plane log categories via the `workspace_log_categories` & `storage_log_categories` experimental arguments. [@stevehipwell](https://github.com/stevehipwell)
- Added version tag to cluster resource. [@james1miller93](https://github.com/james1miller93)

### Changed

- Fixed indentation on `node-exporter` Prometheus rule. [@prikesh-patel](https://github.com/prikesh-patel)
- Changed the default control plane log categories to use `kube-audit-admin` instead of `kube-audit`. [@stevehipwell](https://github.com/stevehipwell)
- Fixed bug where count cannot be determined until apply when resource group is created and `experimental.oms_agent` is enabled in same workspace. [@james1miller93](https://github.com/james1miller93)

### Updated

- Updated _Kube Prometheus Stack_ chart to [v35.4.2](https://github.com/prometheus-community/helm-charts/releases/tag/kube-prometheus-stack-35.4.2). (#455) [@james1miller93](https://github.com/james1miller93)

### Removed

- Removed experimental `kube_audit_object_store_only` variable and replaced it with the new `workspace_log_categories` & `storage_log_categories` experiments. [@stevehipwell](https://github.com/stevehipwell)

## [v1.0.0-beta.11] - 2022-05-23

### Added

- Added support for [AKS v1.22](https://docs.microsoft.com/en-us/azure/aks/supported-kubernetes-versions?tabs=azure-cli). [@stevehipwell](https://github.com/stevehipwell)
- Added experimental support for excluding `kube-audit` logs from Log Analytics via the `kube_audit_object_store_only` experimental flag; this should only be used for cost concerns and isn't recommended from a Kubernetes perspective. [@stevehipwell](https://github.com/stevehipwell)

### Updated

- The _AAD Pod Identity_ chart has been upgraded to `4.1.10` (contains [v1.8.9](https://github.com/Azure/aad-pod-identity/releases/tag/v1.8.9) of the aad-pod-identity image). [@james1miller93](https://github.com/james1miller93)
- The _Fluent Bit_ chart has been upgraded to [v0.20.1](https://github.com/fluent/helm-charts/releases/tag/fluent-bit-0.20.1) (contains _Fluent Bit_ [v1.9.3](https://github.com/fluent/fluent-bit/releases/tag/v1.9.3)). [@prikesh-patel](https://github.com/prikesh-patel)
- The _Kube Prometheus Stack_ chart has been upgraded to [v35.2.0](https://github.com/prometheus-community/helm-charts/releases/tag/kube-prometheus-stack-35.2.0). [@prikesh-patel](https://github.com/prikesh-patel)
- The _Ingress Nginx_ chart has been upgraded to [v4.1.1](https://github.com/kubernetes/ingress-nginx/releases/tag/helm-chart-4.1.1). [@prikesh-patel](https://github.com/prikesh-patel)

## [v1.0.0-beta.10] - 2022-05-09

> **Important**
> This release is a significant breaking change and intended to be the last in the `beta` series with a stable `rc` being planned for the next release.

### Added

- Added experimental support for [AKS v1.22](https://docs.microsoft.com/en-us/azure/aks/supported-kubernetes-versions?tabs=azure-cli). [@stevehipwell](https://github.com/stevehipwell)
- Support for `cpu` node types. [@stevehipwell](https://github.com/stevehipwell)
- Support for `gp`, `gpd`, `mem` & `memd` `v2` node types. [@stevehipwell](https://github.com/stevehipwell)
- Node type & size documentation has been added to the module README. [@stevehipwell](https://github.com/stevehipwell)

### Changed

- The system node pools can now be upgraded automatically by the module. [@stevehipwell](https://github.com/stevehipwell)
- The node image versions should be automatically upgraded. [@stevehipwell](https://github.com/stevehipwell)
- The AKS cluster now only uses a single subnet with isolation expected to be clontrolled by node taints and network restrictions provided by `NetworkPolicies`. [@stevehipwell](https://github.com/stevehipwell)
- Control plane logging has been turned on for all types. [@stevehipwell](https://github.com/stevehipwell)
- Cert manager now has multiple ACME issuers installed so you can use the right one for each certificate. [@stevehipwell](https://github.com/stevehipwell)
- The internal ingress certificate is now created in the ingress namespace. [@stevehipwell](https://github.com/stevehipwell)
- Module variables have been changed, check the README for more details. [@stevehipwell](https://github.com/stevehipwell)
- Kubernetes based providers must be configured to use the `exec` plugin pattern. [@stevehipwell](https://github.com/stevehipwell)
- The module architecture has been flattened and simplified. [@stevehipwell](https://github.com/stevehipwell)
- This module can be used in a new Terraform workspace first apply as no `data` lookups are used that aren't known at plan. [@stevehipwell](https://github.com/stevehipwell)
- Unsupported features, Windows nodes and OMS Agent, have been moved behind the `experimental` variable. [@stevehipwell](https://github.com/stevehipwell)
- Terraform dependency graph has been updated to make sure that create and destroy steps happen in the correct order. [@stevehipwell](https://github.com/stevehipwell)

### Updated

- The `azurerm` Terraform provider has been updated to `v3`, this means all modules and resources in your workspace will need updating to support this. [@stevehipwell](https://github.com/stevehipwell)
- All core services have been aligned to the versions used in the EKS module. [@stevehipwell](https://github.com/stevehipwell)

### Removed

- The community module dependency has been removed. [@stevehipwell](https://github.com/stevehipwell)
- The module no longer exposes Kubernetes credentials, you need to use `az` and `kubelogin` to connect to the cluster. [@stevehipwell](https://github.com/stevehipwell)

## [v1.0.0-beta.9] - 2022-03-14

### Updated

- `fluent-bit` upgrade chart to [0.19.20](https://github.com/fluent/helm-charts/releases/tag/fluent-bit-0.19.20) ([#353](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/353)) [@james1miller93](https://github.com/james1miller93)
- `ingress-nginx` upgrade chart to [4.0.18](https://github.com/kubernetes/ingress-nginx/releases/tag/helm-chart-4.0.18) ([#358](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/358)) [@james1miller93](https://github.com/james1miller93)
- `kube-prometheus-stack` upgrade chart to [33.2.0](https://github.com/prometheus-community/helm-charts/releases/tag/kube-prometheus-stack-33.2.0) ([#354](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/354)) [@james1miller93](https://github.com/james1miller93)

## [v1.0.0-beta.8] - 2022-02-28

### Added

- `module` - added **sku_tier** variable to set [control plane SLA](https://docs.microsoft.com/en-us/azure/aks/uptime-sla) level [@dutsmiller](url) [@jamurtag](url)
- **BREAKING** - Added support for setting node pool [proximity placement group](https://docs.microsoft.com/en-us/azure/aks/reduce-latency-ppg#:~:text=A%20proximity%20placement%20group%20is,and%20tasks%20that%20complete%20quickly.) via the `placement_group_key` variable. [@stevehipwell](https://github.com/stevehipwell)

### Changed

- `aad-pod-identity` - updated chart to 4.1.8 ([#329](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/329)) [@james1miller93](https://github.com/james1miller93)
- `cert-manager` - replaced custom roles with builtin roles ([#236](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/236)) [@james1miller93](https://github.com/james1miller93)
- `cert-manager` - updated chart to 1.7.1 ([#330](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/330)) [@james1miller93](https://github.com/james1miller93)
- `external-dns` - replaced custom roles with builtin roles ([#236](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/236)) [@james1miller93](https://github.com/james1miller93)
- `fluent-bit` - updated chart to 0.19.19 ([#331](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/331)) [@james1miller93](https://github.com/james1miller93)
- `fluentd` - updated chart to 2.6.9 ([#332](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/332)) [@james1miller93](https://github.com/james1miller93)
- `ingress-nginx` - updated chart to 4.0.17 ([#334](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/3349)) [@james1miller93](https://github.com/james1miller93)
- `kube-prometheus-stack` - updated chart to [32.2.1](https://github.com/prometheus-community/helm-charts/releases/tag/kube-prometheus-stack-32.2.1) and CRDs to 0.54.0 (includes Grafana [v8.3.5](https://github.com/grafana/grafana/releases/tag/v8.3.5)) [@james1miller93](https://github.com/james1miller93)
- `provider-azurerm` - restrict azurerm terraform provider to v2 [prikesh-patel](https://github.com/prikesh-patel)
- Updated documentation. [@stevehipwell](https://github.com/stevehipwell)
- Update version of upstream AKS module. [@dutsmiller](url)

> **IMPORTANT** - As part of the `cert-manager` upgrade, all of the cert manager crds need to be patched manually `prior` to upgrading to the `v1.0.0-beta.8` tag. An [issue](https://github.com/cert-manager/cert-manager/issues/4831) has been raised against the upstream repository to track this. Please see [UPGRADE.md](/UPGRADE.md#from-v100-beta7-to-v100-beta8) for details.
> **IMPORTANT** - The _Cert Manager_ API versions `v1alpha2`, `v1alpha3`, and `v1beta1` have been removed. All _Cert Manager_ custom resources must only use `v1` before upgrading to this release. All certificates are already stored as `v1`, after this release you can only access deprecated API resources through the _Cert Manager_ API.

## [v1.0.0-beta.7] - 2022-02-08

### Added

- `documentation` - added [documentation](/UPGRADE.md) for module & AKS version upgrades [@sossickd](url)

### Changed

- `aad-pod-identity` - updated chart to 4.1.7 [@sossickd](url)
- `cert-manager` - added toleration and node selector for startupapicheck [@sossickd](url)
- `cluster-autoscaler` - disabled autoscaling for node pools when min/max settings are the same [@dutsmiller](url)
- `ingress_internal_core` updated chart to 4.0.16 [@sossickd](url)
- `ingress_internal_core` replace dashboard with Grafana dashboard [14314](https://grafana.com/grafana/dashboards/14314) [@sossickd](url)
- `kubectl provider` - enabled server-side-apply aad-pod-identity [@sossickd](url)
- `kube-prometheus-stack` - updated chart to 30.1.0 and CRDs to 0.53.1 (see **IMPORTANT** note below) [@sossickd](url)
- `kube-prometheus-stack` - added resource limits for prometheusConfigReloader [@sossickd](url)
- `kube-prometheus-stack` - enabled update strategy for node-exporter daemonset [@sossickd](url)
- `kube-prometheus-stack` - enabled service monitor for kube-state-metrics, node-exporter [@sossickd](url)
- `kubectl provider` - enabled server-side-apply aad-pod-identity, kube-promethues-stack, ingress_internal_core, rbac, identity [@sossickd](url)
- `grafana` - updated container image to 8.3.3, removed temporary fix to mitigate [CVE-2021-43798](https://nvd.nist.gov/vuln/detail/CVE-2021-43798) & [CVE-2021-43813](https://grafana.com/blog/2021/12/10/grafana-8.3.2-and-7.5.12-released-with-moderate-severity-security-fix/) [@sossickd](url)
- `module` - Kubernetes patch versions updated for 1.20 and 1.21 (see **IMPORTANT** note below) [@dutsmiller](url)
- `storage-classes` - migrate storage classes created by the module to [CSI drivers](https://docs.microsoft.com/en-us/azure/aks/csi-storage-drivers) for 1.21.x clusters (see IMPORTANT note below)[@sossickd](url)

### Removed

- `module` - dropped support for Kubernetes version 1.19 (see **IMPORTANT** note below) [@dutsmiller](url)

> **IMPORTANT** - Dropped support for Kubernetes version 1.19, patch versions updated for 1.20 and 1.21. This will instigate a cluster upgrade, refer to [UPGRADE.md](/UPGRADE.md) for module and Kubernetes version upgrade instructions and troubleshooting steps.
> **IMPORTANT** - Due to an upgrade of the `kube-state-metrics` chart as part of the `kube-prometheus-stack` upgrade, removal of its deployment needs to done manually `prior` to upgrading to the `v1.0.0-beta.7` tag. Please see [UPGRADE.md](/UPGRADE.md#from-v100-beta6-to-v100-beta7) for details.
> **IMPORTANT** - The following storage classes have been migrated to CSI drivers in the 1.21 release - `azure-disk-standard-ssd-retain`, `azure-disk-premium-ssd-retain`, `azure-disk-standard-ssd-delete` and `azure-disk-premium-ssd-delete`. If you created custom storage classes using the kubernetes.io/azure-disk or kubernetes.io/azure-file provisioners they will need to be [migrated to CSI drivers](https://docs.microsoft.com/en-us/azure/aks/csi-storage-drivers#migrating-custom-in-tree-storage-classes-to-csi). Please use `v1.0.0-beta.7` or above to create new 1.21 clusters.

## [v1.0.0-beta.6] - 2022-01-14

> **IMPORTANT** - This pre-release isn't guaranteed to be stable and should not be used in production.

### Added

- `coredns` - added corends module to support on-premise name resolution [@sossickd](url)
- `module` - added required core_services_config parameters to examples [@sossickd](url)

### Changed

- `fluent-bit` - updated chart to 0.19.16 [@sossickd](url)
- `fluent-bit` - revert cri multi-line parser back to the standard parser until upstream [issue](https://github.com/fluent/fluent-bit/issues/4377) has been fixed [@sossickd](url)
- `fluentd` - updated chart to 2.6.7 [@sossickd](url)
- `fluentd` - fix image tag and repository override [@sossickd](url)
- `external-dns` - updated chart to 1.7.1 [@sossickd](url)
- `local_storage` - added dependency on kube-prometheus-stack CRDs [@sossickd](url)
- `module` - removed providers from module and version constraints from sub-modules (see IMPORTANT note below) [@sossickd](url)
- `cert-manager` - updated chart and CRDs to 1.6.1 [@sossickd](url)
- `kubectl provider` - enabled server-side-apply for fluent-bit, cert-manager [@sossickd](url)

> **IMPORTANT** - Providers have now been removed from the module which requires changes to the Terraform workspace. All providers **must** be declared and configuration for the `kubernetes`, `kubectl` & `helm` providers **must** be set. See [examples](/examples) for valid configuration and review the [CHANGELOG](/CHANGELOG.md) on each release.

## [v1.0.0-beta.5] - 2021-12-14

> **IMPORTANT** - This pre-release isn't guaranteed to be stable and should not be used in production.

### Added

- `CSI` - added local volume provisioner for local nvme & ssd disks [@dutsmiller](url)
- `Diagnostics` - AKS control plane logs written to log analytics workspace in cluster resource group [@sossickd](url)

### Changed

- `API` - added version field to node_types (see **IMPORTANT** note below) [@dutsmiller](url)
- `AzureUSGovernmentCloud` - added `azure_environment` variable to set cloud environment [@dutsmiller](url)
- `AzureUSGovernmentCloud` - added support for AAD member users [@dutsmiller](url) [@jamurtag](url)
- `AzureUSGovernmentCloud` - added support in external-dns & cert-manager [@sossickd](url)
- `Documentation` - clarification of Windows node pool support [@jamurtag](url)
- `external-dns` - changed logging format to json [@sossickd](url)
- `fluent-bit` - updated chart to 0.19.5 [@sossickd](url)
- `fluent-bit` - added update strategy & [multiline](https://docs.fluentbit.io/manual/administration/configuring-fluent-bit/multiline-parsing) support [@sossickd](url)
- `fluentd` - updated chart to 2.6.5 [@sossickd](url)
- `fluentd` - changed filter_config, route_config & output_config variables to filters, routes & outputs [@sossickd](url)
- `fluentd` - support for custom image repository and tag via image_repository & image_tag variables [@sossickd](url)
- `fluentd` - add extra fields to logs including cluster_name, subscription_id and location [@sossickd](url)
- `kube-prometheus-stack` - updated chart to 19.3.0 & CRDs to 0.50.0 [@sossickd](url)
- `kubectl provider` - updated version to 1.12.1 [@dutsmiller](url)
- `kubectl provider` - enabled server-side-apply for fluentd, kube-prometheus-stack, external-dns [@sossickd](url)
- `Grafana` - updated container image to 8.3.2 to mitigate [CVE-2021-43798](https://nvd.nist.gov/vuln/detail/CVE-2021-43798) & [CVE-2021-43813](https://grafana.com/blog/2021/12/10/grafana-8.3.2-and-7.5.12-released-with-moderate-severity-security-fix/) [@jamurtag](url)
- `Grafana` - managed identity support & Azure role assignment for access to managed resources [@jamurtag](url)
- `Grafana` - added grafana_identity output for custom Azure role assignments [@jamurtag](url)
- `Grafana` - added Azure Monitor data source for access to Azure resources [@sossickd](url)
- `Grafana` - added dashboard to view control plane diagnostics logs [@sossickd](url)
- `Tags` - added cloud tags to all provisioned resources [@prikesh-patel](url)
- `VM Types` - added gpd, mem, memd, and stor vm types (see [matrix](./modules/nodes/matrix.md) for node types) [@dutsmiller](url)

> **IMPORTANT** - Existing node types must have "-v1" appended to be compatible with beta.5.  Example:  The beta.4 node type of "x64-gp" would need to be changed to "x64-gp-v1" to maintain compatibility .  All future node types will be versioned.  See [matrix](./modules/nodes/matrix.md) for node types and details.
> **IMPORTANT** - If you are currently using `filter_config`, `route_config` or `output_config` in the fluentd section of the core_services_config these will need to be renamed accordingly.

## [v1.0.0-beta.4] - 2021-11-02

> **IMPORTANT** - This pre-release isn't guaranteed to be stable and should not be used in production.

### Changed

- ingress-nginx chart updated to version 4.0.6 [@jamurtag](url)
- aad-pod-identity chart updated to version 4.1.5 [@jamurtag](url)
- aad-pod-identity requests and limits lowered for both NMI and MIC pods [@jamurtag](url)
- Default to AzurePublicCloud in cert-manager config [@jamurtag](url)
- Minor formatting change to cert-manager cluster-issuer config [@sossickd](url)
- Reduced ingress-nginx cpu / memory requests to 50m / 128MB (from 200m / 256MB) [@jamurtag](url)
- Changed prometheus-operator memory requests / limits to 128MB / 512 MB (from 256MB / 256MB) [@jamurtag](url)
- Changed kube-state-metrics memory requests / limits to 128MB / 1024MB (from 256MB / 512MB) [@jamurtag](url)
- Added documentation for system node pool service resource tracking and reporting [@jamurtag](url)
- Explicitly set Azure Policy and Dashboard add-on status to avoid noise in plans [@dutsmiller](url)
- Improve Virtual Network documentation [@dutsmiller](url)
- Explicitly set max_pods for kubenet/AzureCNI [@dutsmiller](url)
- Set `allowSnippetAnnotations` to `false` on ingress-nginx chart to mitigate [security vulnerability](https://www.armosec.io/blog/new-kubernetes-high-severity-vulnerability-alert-cve-2021-25742) [@prikesh-patel](url)
- Updated support policy regarding Windows node pools and nested Terraform modules [@jamurtag](url)

## [v1.0.0-beta.3] - 2021-09-29

> **IMPORTANT** - This pre-release isn't guaranteed to be stable and should not be used in production.

### Added

- AzureUSGovernmentCloud support in cert-manager [@jhisc](url)
- Helm chart for external-dns to create dns records in Azure private dns-zones [@sossickd](url)
- Grafana dashboard for external-dns [@sossickd](url)
- Grafana dashboard for ingress_internal_core [@sossickd](url)

### Changed

- Helm chart renamed from external-dns to external-dns-public [@sossickd](url)
- External dns helm chart moved from [bitnami external-dns](https://github.com/bitnami/charts/tree/master/bitnami/external-dns) to [kubernetes-sigs external-dns](https://github.com/kubernetes-sigs/external-dns/tree/master/charts/external-dns) [@sossickd](url)
- Updated ingress_internal_core to helm version 4.0.2 [@sossickd](url)
- Updated kubernetes provder to v2.5 [@fabiendelpierre](url)

> **IMPORTANT** - Please change the core_services_config input for external_dns.

## [v1.0.0-beta.2] - 2021-09-10

> **IMPORTANT** - This pre-release isn't guaranteed to be stable and should not be used in production.

### Added

- Cluster ID output [@dutsmiller](url)

### Changed

- Set ingress-nginx & PrometheusOperator adminissionWebhook to run on system nodepool [@jamurtag](url)
- Output changed:  aks_cluster_name -> cluster_name [@dutsmiller](url)

## [v1.0.0-beta.1] - 2021-08-20

> **IMPORTANT** - This pre-release isn't guaranteed to be stable and should not be used in production.

### Added

- Azure Log Analytics support [@appkins](url)
- Ingress node pool [@dutsmiller](url)

### Changed

- Fix default-ssl-certificate in ingress_internal_core module [@sossickd](url)
- User guide updates [@jamurtag](url)

## [v0.12.0] - 2021-08-11

> **IMPORTANT** - This pre-release isn't guaranteed to be stable and should not be used in production.

### Added

- Support for k8s 1.21 [@dutsmiller](url)

### Changed

- Node pool variable changes [@dutsmiller](url)
- Change pod_cidr variable to podnet_cidr [@dutsmiller](url)
- Change core_services_config ingress_core_internal to ingress_internal_core [@dutsmiller](url)
- Change multi-vmss node pool capacity format [@dutsmiller](url)

### Removed

- Remove configmaps, secrets and namespaces variables [@dutsmiller](url)
- Remove assignment of public IPs for nodes in public subnet [@dutsmiller](url)

## [v0.11.0] - 2021-07-27

> **IMPORTANT** - This pre-release isn't guaranteed to be stable and should not be used in production.

### Added

- Calico network policy support [@jamurtag](url)
- AKS API firewall support [@dutsmiller](url)

### Changed

- Update README and simplify core_services_config variable input [@jamurtag](url)
- Update upstream AKS module version [@dutsmiller](url)
- Change name of UAI for AKS [@dutsmiller](url)
- Force host encryption to true [@dutsmiller](url)

### Removed

- Remove additional_priority_classes and additional_storage_classes api options [@jamurtag](url)
- Remove autodoc from repo [@dutsmiller](url)

## [v0.10.0] - 2021-07-19

> **IMPORTANT** - This pre-release isn't guaranteed to be stable and should not be used in production.

### Changed

- Tolerate stateful services on system nodepools [@jamurtag](url)
- Rename config variable to core_services_config [@jamurtag](url)

## [v0.9.0] - 2021-07-14

> **IMPORTANT** - This pre-release isn't guaranteed to be stable and should not be used in production.

### Added

- Added wildcard certificate for core services [@sossickd](url)
- Documentation for cert-manager, external-dns, priority classes and storage claasses [@fabiendelpierre](url)

### Changed

- Node pool format to match EKS [@dutsmiller](url)
