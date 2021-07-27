# AKS Documentation

* [Architecture](#Architecture)
  * [Resource Groups](#resource-groups)
  * [Vnet](#vnet)
  * [CNI Options](#cni-options)
  * [Node Pools](#node-pools)
  * [DNS](#dns)
* [Kubernetes](#kubernetes)
  * [RBAC](/modules/core-config/modules/rbac/README.md)
  * [Storage Classes](/modules/core-config/modules/storage-classes/README.md)
  * [Ingress](/modules/core-config/modules/ingress-core-internal/README.md)
* [Services](#services)
  * [aad-pod-identity](/modules/core-config/modules/pod-identity/README.md)
  * [cert-manager](/modules/core-config/modules/cert-manager/README.md)
  * [external-dns](/modules/core-config/modules/external-dns/README.md)

## Architecture

The following diagram shows the standard network topology and resource group layout for an AKS cluster.

![AKS Network Architecture](/docs/images/aks_network_architecture.png)

### Resource Groups

The following resources must be created in advanced of deploying an AKS cluster.

* Azure Vnet - (Subnets & Route Table)
* Azure DNS  - (public and private zones)

These could be deployed into a single resource group, or a dedicated resource group each.

The module `resource_group_name` variable specifies the resource group to deploy the `AKS service` into. This could share the Vnet/DNS resource group above or be deployed into a dedicated pool. Consideration should be given if multiple Vnets and clusters are to be deployed to a subscription and hence Azure RBAC isolation bteween teams. DNS zones will likely be a shared resource for many teams & services.

> in addition, Azure creates a `MC_<cluster-name>` resource group to host managed resources

---

### Vnet

AKS resources **must** be deployed into **dedicated** subnets.

* AKS-Private - hosts [System Node Pools](#system-node-pools) and most [User Node Pools](#user-node-pools)
* AKS-Public - hosts [Ingress Node Pools](#ingress-node-pools)

Subnet configuration, in particular sizing, will largely depend on the CNI used, see [CNI Options](#cni-options) below.

> see [examples](/examples) for how to integrate AKS using the official Vnet module

### CNI Options

The following table lists properties and considerations when choosing the CNI plugin.

| **Description**                              | **kubenet**      | **Azure CNI** |
| :------------------------------------------- | :--------------- | :------------ |
| The default network plugin.                  | `true`           | `false`       |
| Subnet sized based on number of...           | `hosts`          | `pods`        |
| Default pods supported per node (`max_pods`).| `110`            | `30`          |
| Nodes (and pods) supported on a /24 network. | `251` (`27,610`) | `8` (`240`)   |
| Support for Windows node pools.              | `false`          | `true`        |
| Support for multiple clusters in a subnet.   | `false`          | `true`        |

Subnets must be sized to accommodate node pool upgrades and scaling events.

It is recommended to use the `kubenet` plugin unless Windows node pools are required or the application has extremely low latency requirements (where sub-millisecond latency is a significant factor).

---

### Node Pools

There are three standard classes of node pool, as described below.

#### System Node Pools

System node pools host all AKS core cluster services, AKS add-ons and all platform services - aside from daemonsets which run all all nodes.

SRE teams need only consider platform `daemonset` resources requirements when scheduling user services.

#### User Node Pools

User node pools will host most user workloads, aside from custom ingress services.

Deploy user node pools via the `node_pools` variable, use node labels and taints to control pod placement and scheduling.

#### Ingress Node Pools

Public facing services **must** first terminate connections in an ingress node pool in a public subnet.

This will require deployment of an ingress controller, see [Ingress](/modules/core-config/modules/ingress-core-internal/README.md) documentation for more details.

---

### DNS

Some platform services (*e.g. Prometheus & Grafana*) have dashboards which are exposed via an internal load balancer.

DNS records are hosted in a private zone configured via the `external-dns.zones` configuration parameter within the `core_services_config` variable. This zone must be resolvable from internal Active Directory DNS servers, plus be routable via direct peering (VPN or Direct Connect). 

Work with your IOG teams to ensure these prerequisites are met.

> a temporary workaround is to use [kubectl port-forwarding](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/) to get access to the service from a local workstation

