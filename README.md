# Azure Kubernetes Service (AKS) Terraform Module

## Overview

This module is designed to provide a simple and opinionated way to build standard AKS clusters and is based on the open-source [terraform-azurerm-kubernetes](https://github.com/Azure-Terraform/terraform-azurerm-kubernetes) module. This module takes a set of configuration options and creates a fully functional Kubernetes cluster with a common set of services.

### Behavior

This module is designed to provide a standard set of defaults for all node pools and optimized instance type selection for a given size.

See [examples](/examples) for general usage and the [documentation index](/docs) for in-depth details for each subsystem or service.

---

## Terraform

| Version   |
|-----------|
| >= 0.14.8 |

## Providers

| Name       | Version   |
|------------|-----------|
| azurerm    | >= 2.65.0 |
| helm       | >= 2.1.1  |
| kubectl    | >= 1.10.0 |
| kubernetes | ~> 1.13   |
| time       | >= 0.7.1  |

## Inputs

| **Variable**                      | **Description**                                                                                            | **Type**                                 | **Default**       | **Required** | 
|:----------------------------------|:-----------------------------------------------------------------------------------------------------------|:-----------------------------------------|:------------------|:------------:|
| `api_server_authorized_ip_ranges` | Public IP or CIDR ranges to apply as a whitelist to the K8S API server, if not set defaults to `0.0.0.0/0`.| `map(string)`                            | `nil`             | `no`         |
| `azuread_clusterrole_map`         | Azure AD Users and Groups to assign to Kubernetes cluster roles.                                           | `object(map(string))` _(see appendix a)_ | `{}`              | `no`         |
| `cluster_name`                    | Name of the AKS cluster, also used as a prefix in names of related resources.                              | `string`                                 | `nil`             | `yes`        |
| `cluster_version`                 | The Kubernetes minor version. Versions `1.19` & `1.20` supported.                                          | `string`                                 | `"1.20"`          | `no`         |
| `configmaps`                      | Configmaps to apply to the cluster, the namespace must already exist or be in the namespaces variable.     | `map(object)` _(see appendix f)_         | `{}`              | `no`         |
| `core_services_config`            | Configuration options for core platform services                                                           | `any` _(see appendix h)_                 | `nil`             | `yes`        |
| `location`                        | Azure region in which to build resources.                                                                  | `string`                                 | `nil`             | `yes`        |
| `namespaces`                      | List of additional namespaces to create on the cluster.                                                    | `list(string)`                           | `[]`              | `no`         |
| `network_plugin`                  | Kubernetes Network Plugin (kubenet or azure)                                                               | `string`                                 | `"kubenet"`       | `no`         |
| `node_pool_defaults`              | Override default values for node pools, this will NOT override the values that the module sets directly.   | `any`                                    | `{}`              | `no`         |
| `node_pools`                      | Node pool definitions.                                                                                     | `list(object())` _(see appendix b)_      | `nil`             | `yes`        |
| `pod_cidr`                        | CIDR range for pod IP addresses when using the `kubenet` network plugin.                                   | `string`                                 | `"100.65.0.0/16"` | `no`         |
| `resource_group_name`             | Name of the Resource Group to deploy the AKS Kubernetes service into, must already exist.                  | `string`                                 | `nil`             | `yes`        |
| `secrets`                         | Map of secrets to apply to the cluster, the namespace must already exist or be in the namespaces variable. | `map(object)` _(see appendix g)_         | `nil`             | `no`         |
| `tags`                            | Tags to be applied to cloud resources.                                                                     | `map(string)`                            | `{}`              | `no`         |
| `virtual_network`                 | Virtual network configuration.                                                                             | `object(map)` _(see appendix d)_         | `nil`             | `yes`        |
| `vm_types`                        | Extend or overwrite the default vm types map.                                                              | `map(string)`                            | `nil`             | `no`         |

### Appendix A

`azuread_clusterrole_map` object specification.

| **Variable**           | **Description**                                                         | **Type** | **Default** |
| :--------------------- | :---------------------------------------------------------------------- | :------- | :---------- |
| `cluster_admin_users`  | A map of Azure AD Ids to be assigned full cluster admin permissions.    | `string` | `nil`       |
| `cluster_view_users`   | A map of Azure AD Ids to be assigned full cluster read permissions.     | `string` | `nil`       |
| `standard_view_users`  | A map of Azure AD Ids to be assigned basic cluster read permissions.    | `mapstring` | `nil`       |
| `standard_view_groups` | A map of Azure AD Ids to be assigned basic cluster read permissions.    | `string` | `nil`       |

> see [RBAC documentation](/modules/core-config/modules/rbac/README.md) for more details


### Appendix B

`node_pools` object specification.

| **Variable**  | **Description**                                                                                                                                     | **Type**                          | **Default** |
| :------------ | :-------------------------------------------------------------------------------------------------------------------------------------------------- | :-------------------------------- | :---------- |
| `name`        | Node pool name.                                                                                                                                     | `string`                          | `nil`       |
| `single_vmss` | `false` creates a single node pool across all zones, `true` creates node pools of the same specification in all zones to support stateful services. | `bool`                            | `nil`       |
| `public`      | Set to `true` to deploy the node pool in a public subnet.                                                                                           | `bool`                            | `nil`       |
| `vm_size`     | Virtual machine instance size, see [VM types](/modules/nodes/local.tf). The default classes can be extended via the `vm_types` variable.            | `string`                          | `nil`       |
| `os_type`     | Operating system type, `Linux` or `Windows`.                                                                                                        | `string`                          | `nil`       |
| `min_count`   | Minimum size of the node pool, starting from `0`.                                                                                                   | `number`                          | `nil`       |
| `max_count`   | Maximum size of the node pool, must be greater or equal to `min_count`.                                                                             | `number`                          | `nil`       |
| `labels   `   | Kubernetes node labels to apply to nodes in the pool.                                                                                               | `map(string)`                     | `nil`       |
| `taints   `   | Kubernetes taints to apply to nodes in the pool.                                                                                                    | `list(object)` _(see appendix c)_ | `nil`       |
| `tags    `    | Additional cloud tags to apply to the node pool.                                                                                                    | `map(string)`                     | `nil`       |

### Appendix C

`node_pools.taints` object specification.

| **Variable** | **Description**                                                                           | **Type** | **Default** |
| :----------- | :---------------------------------------------------------------------------------------- | :------- | :---------- |
| `key`        | The key of the taint. Maximum length of 63.                                               | `string` | `nil`       |
| `value`      | The value of the taint. Maximum length of 63.                                             | `string` | `nil`       |
| `effect`     | The effect of the taint. Valid values: `NO_SCHEDULE`, `NO_EXECUTE`, `PREFER_NO_SCHEDULE`. | `string` | `nil`       |


### Appendix D

`virtual_network` object specification.

| **Variable**     | **Description**                                        | **Type**                         | **Default** |
| :--------------- | :----------------------------------------------------- | :------------------------------- | :---------- |
| `subnets`        | Map of public and private subnet ids.                  | `object(map)` _(see appendix e)_ | `nil`       |
| `route_table_id` | Route table id attached to public and private subnets. | `string`                         | `nil`       |

### Appendix E

`virtual_network.subnets` object specification.

| **Variable** | **Description**      | **Type**      | **Default** |
| :----------- | :------------------- | :------------ | :-----------|
| `public`     | Public subnet id.    | `object(map)` | `nil`       |
| `private`    | Private subnet id.   | `object(map)` | `nil`       |


### Appendix F

`configmaps` object specification.

| **Variable**| **Description**           | **Type**      | **Default** |
| :---------- | :------------------------ | :------------ | :---------- |
| `name`      | Name of the configmap.    | `string`      | `nil`       |
| `namespace` | Namespace to apply to.    | `string`      | `nil`       |
| `data`      | Content.                  | `map(string)` | `nil`       |

### Appendix G

`secrets` object specification.

| **Variable**| **Description**           | **Type**      | **Default** |
| :---------- | :------------------------ | :------------ | :---------- |
| `name`      | Name of the secret.       | `string`      | `nil`       |
| `namespace` | Namespace to apply to.    | `string`      | `nil`       |
| `type`      | Type of secret.           | `string`      | `nil`       |
| `data`      | Content.                  | `map(string)` | `nil`       |

### Appendix H

`core_services_config` object specification.

| **Variable**            | **Description**                             | **Type**                 |
| :---------------------- | :------------------------------------------ | :----------------------- |
| `alertmanager`          | _Alert Manager_ configuration.              | `any` _(see appendix i)_ |
| `cert_manager`          | _Cert Manager_ configuration.               | `any` _(see appendix j)_ |
| `external_dns`          | _External DNS_ configuration.               | `any` _(see appendix k)_ |
| `fluentd`               | _Fluentd_ configuration.                    | `any` _(see appendix l)_ |
| `grafana`               | _Grafana_ configuration.                    | `any` _(see appendix m)_ |
| `ingress_core_internal` | Ingress configuration.                      | `any` _(see appendix n)_ |
| `prometheus`            | _Prometheus_ configuration.                 | `any` _(see appendix o)_ |

### Appendix I

`alertmanager` object specification.

| **Variable** | **Description**                                                                               | **Type** | **Required** |
| :----------- | :-------------------------------------------------------------------------------------------- | :------- | :----------- |
| `smtp_host`  | SMTP host to send alert emails.                                                               | `string` | **Yes**      |
| `smtp_from`  | SMTP from address for alert emails.                                                           | `string` | **Yes**      |
| `receivers`  | [Receiver configuration](https://prometheus.io/docs/alerting/latest/configuration/#receiver). | `any`    | No           |
| `routes`     | [Route configuration](https://prometheus.io/docs/alerting/latest/configuration/#route).       | `any`    | No           |

### Appendix J

`cert_manager` object specification.

| **Variable**              | **Description**                                                                                                               | **Type**       | **Required** |
| :------------------------ | :---------------------------------------------------------------------------------------------------------------------------- | :------------- | :----------- |
| `dns_zones`               | DNS zones that _Lets Encrypt_ can manage certificates for, must be set up as an _Azure DNS_ public zones in the subscription. | `list(string)` | No           |
| `letsencrypt_environment` | _Lets Encrypt_ environment, supported values `staging` or `production`.                                                       | `string`       | No           |
| `letsencrypt_email`       | Email address for certificate expiry notifications.                                                                           | `string`       | No           |
| `additional_issuers`      | Additional issuers to install into the cluster.                                                                               | `map(any)`     | No           |

### Appendix K

`external_dns` object specification.

| **Variable**          | **Description**                                                                                              | **Type**       | **Required** |
| :-------------------- | :----------------------------------------------------------------------------------------------------------- | :------------- | :----------- |
| `additional_sources`  | Additional _Kubernetes_ objects to be watched.                                                               | `list(string)` | No           |
| `resource_group_name` | Name of the Azure Resource Group hosting DNZ zones, zones managed by external-dns must be in the same group. | `string`       | No           |
| `zones`               | A list of DNS zones to be managed by external-dns, must be hosted within the resource group input.           | `list(string)` | No           |

### Appendix L

`fluentd` object specification.

| **Variable**     | **Description**                                                                      | **Type**      | **Required** |
| :--------------- | :----------------------------------------------------------------------------------- | :------------ | :----------- |
| `additional_env` | Additional environment variables.                                                    | `list(any)`   | No           |
| `debug`          | If `true` all logs are printed to stdout.                                            | `bool`        | No           |
| `pod_labels`     | Labels to add to fluentd pods, used for pod-identity or cloud storage integrations.  | `map(string)` | No           |
| `filter_config`  | _Fluentd_ filter configuration\_.                                                    | `string`      | No           |
| `route_config`   | _Fluentd_ route configuration\_.                                                     | `string`      | No           |
| `output_config`  | _Fluentd_ output configuration\_.                                                    | `string`      | No           |

### Appendix M

`grafana` object specification.

| **Variable**              | **Description**                | **Type**       | **Required** |
| :------------------------ | :----------------------------- | :------------- | :----------- |
| `admin_password`          | Admin password.                | `string`       | No           |
| `additional_data_sources` | Additional data sources.       | `list(any)`    | No           |
| `additional_plugins`      | Additional plugins to install. | `list(string)` | No           |

### Appendix N

`ingress_core_internal` object specification.

| **Variable**       | **Description**                                                                                                  | **Type**      | **Required** |
| :----------------- | :--------------------------------------------------------------------------------------------------------------- | :------------ | :----------- |
| `domain`           | Internal ingress domain.                                                                                         | `string`      | **Yes**      |
| `subdomain_suffix` | Suffix to add to internal ingress subdomains, if not set cluster name will be used.                              | `string`      | No           |
| `lb_source_cidrs`  | Source CIDR ranges accepted by the ingress load balancer, defaults to `10.0.0.0/8` & `100.65.0.0/16` (POD CIDR). | `list(string)`| No           |

### Appendix O

`prometheus` object specification.

| **Variable**   | **Description**                     | **Type**       | **Required** |
| :------------- | :---------------------------------- | :------------- | :----------- |
| `remote_write` | Remote write endpoints for metrics. | `list(string)` | No           |

---

## Outputs

| Name                                     | Description |
|------------------------------------------|-------------|
| `aks_cluster_effective_outbound_ips_ids` | n/a         |
| `aks_cluster_name`                       | n/a         |
| `kube_config`                            | n/a         |
| `kubelet_identity`                       | n/a         |
| `principal_id`                           | n/a         |
