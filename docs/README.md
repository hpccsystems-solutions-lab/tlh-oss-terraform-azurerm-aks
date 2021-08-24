# AKS Documentation

* [Architecture](#Architecture)
  * [Prerequisites](#prerequisites)
  * [CNI Options](#cni-options)
* [Module User Guide](#module-user-guide)
  * [Kubernetes RBAC](#kubernetes-rbac)
  * [DNS, TLS Certificates & Ingress](#dns-tls-certificates-ingress)
  * [ACR Access](#acr-access)
  * [Multiple Clusters per Subnet](#multiple-clusters-per-subnet)
* [Service User Guide](#services)
  * [Azure AD Pod Identity](#azure-ad-pod-identity)
  * [Ingress](#ingress)
  * [External DNS](#external-dns)
  * [TLS Certificates](#tls-certificates)
  * [Network Policy](#network-policy)
  * [Metrics & Alerts](#metrics-alerts)
  * [Azure Monitor Container Insights](#azure-monitor-container-insights)

<br>

## Architecture

The following diagram shows the standard network topology and resource group layout for an AKS cluster.

![AKS Network Architecture](/docs/images/aks_network_architecture.png)

---

### Prerequisites 

The following prerequisites must be met in advance of deploying an AKS cluster.

* `Subscription` - activation of the [encryption at host](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/disks-enable-host-based-encryption-cli#prerequisites) feature on subscriptions which host AKS clusters
* `Resource Groups` - to host VNet, DNS and AKS resources
* `VNet` - a set of dedicated subnets & associated route table for each AKS cluster
* `DNS`  - at least one public zone to host ingress / service records

A [default subscription DNS public zone](https://reedelsevier.sharepoint.com/sites/OG-CoP-Cloud/SitePages/DNS-Zone-Naming-Conventions.aspx) (and Resource Group) may have been created as part of the subscription deployment process. If additional public zones are required they **must** be deployed to the same resource group for `external-dns` to access them.

To enable the [encryption at host](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/disks-enable-host-based-encryption-cli#prerequisites) feature, a user with subscription Contributor permissions must execute the following commands:

```bash
$ az account set --subscription <subscription_name>
$ az feature register --namespace Microsoft.Compute --name EncryptionAtHost
```

A VNet could be shared with non-AKS resources, however there **must** be a pair of dedicated public and private subnets and route table for each AKS cluster (use the [terraform-azure-virtual-network](https://github.com/Azure-Terraform/terraform-azurerm-virtual-network) module `aks_subnets` variable to meet this requirement, see [examples](/examples) for usage). While it is technically possible to host multiple AKS cluster node pools in a subnet, see [guidance](#multiple-clusters-per-subnet) on why this is not recommended.

Node pools are split into 3 classifications; the `system node pools` hosts cluster services and is completely managed by the module; `user node pools` host user workloads, multiple pools can be deployed and then targeted or isolated using node labels and taints respectively; `ingress node pools` are used to route external traffic into the cluster and are the only pool to be deployed into a public subnet. NSG rules prohibit routing of internet traffic directly to private subnets.

Subnet configuration, in particular sizing, will largely depend on the network plugin (CNI) used, see [CNI Options](#cni-options) below.

The module `resource_group_name` variable specifies the resource group to deploy the `AKS service` into. This could share the VNet resource group  or be deployed into a dedicated pool. Consideration should be given if multiple VNets and clusters are to be deployed to a subscription and hence Azure RBAC isolation between teams. 

> in addition, Azure creates a fully managed `MC_<cluster-name>` resource group to host AKS managed resources

---

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

Also see the [official comparison table](https://docs.microsoft.com/en-us/azure/aks/concepts-network#compare-network-models) for more information.

Subnets must be sized to accommodate node pool upgrade and scaling events.

It is recommended to use the `kubenet` plugin unless Windows node pools are required or the application has extremely low latency requirements (where sub-millisecond latency is a significant factor).

<br>
---
<br>

## Module User Guide

How to interact with the Terraform module to deploy an AKS cluster.

### Kubernetes RBAC

[Cluster authentication](https://docs.microsoft.com/en-us/azure/aks/azure-ad-integration-cli#access-cluster-with-azure-ad) is managed via Azure AD (SSO) in the `RBAHosting` tenant.

Azure AD users or services accounts (managed identities) will need some level of administrative access to the cluster, either for general maintenance and visibility or to hand off to automation platforms to deploy user services. A basic set of Kubernetes administrative and viewer roles are provided via the `azuread_clusterrole_map` variable.

```yaml
  azuread_clusterrole_map = {
    cluster_admin_users  = {
      "bloggsj@risk.regn.net"    = "d76d0bbd-3243-47e2-bdff-b4a8d4f2b6c1"
    }
    cluster_view_users = {
      "Accurint CDB MID"         = "ca55d5e2-99f6-4047-baef-333313edcf98"
    }
    standard_view_users  = {}
    standard_view_groups = {
      "Accurint AKS View Access" = "3494a2b5-d6e5-49f2-9cf7-542004cbe44d"
    }
  }
```

After handover it's possible for teams to create additional roles and bindings for Azure AD users, however this **must not** include the `cluster-admin` role - this high priviliged role must be fully managed by this variable for transparency and auditing by InfoSec and SRE teams. See the [RBAC](/modules/core-config/modules/rbac/README.md) documentation for full implementation details.

For service accounts, a managed identity can be configured for non-interactive `kubectl` access, see [kubelogin](https://docs.microsoft.com/en-us/azure/aks/managed-aad#non-interactive-sign-in-with-kubelogin) for details.

---

### DNS, TLS Certificates & Ingress

Configuration for these areas is closely aligned and configured via inputs in the `core_services_config` variable.

For example, the module exposes ingress endpoints for core services such as Prometheus, Grafana and AlertManager UIs. The endpoints must be secured via TLS and DNS records must be published to Azure DNS for clients to resolve.


```yaml
  core_services_config = {
    cert_manager = {
      dns_zones  = {
        "us-accurint-prod.azure.lnrsg.io" = "us-accurint-prod-dns-rg"
      }
    }

    external_dns= {
      resource_group_name = "us-accurint-prod-dns-rg"
      zones = [ "us-accurint-prod.azure.lnrsg.io" ]
    }

    ingress_internal_core = {
      domain    = "us-accurint-prod.azure.lnrsg.io"
    }
  }
```

The `cert-manager` block specifies the public zone Let's Encrypt will use to validate the domain and its resource group. 

The `external-dns` block specifies domain(s) that user services can expose DNS records through and their resource group - all zones managed by `external-dns` **must** be in a single resource group. 

The `ingress_internal_core` block specifies the domain to expose ingress resources to, consuming DNS/TLS services above. 

It's very likely the same primary domain will be configured for all services, perhaps with `external-dns` managing some additional domains. The resource group is a required input so the module can assign appropriate Azure role bindings. It is expected that in most cases all DNS domains will be hosted in a single resource group.

See the [Ingress](/modules/core-config/modules/ingress_internal_core/README.md) documentation for implementation details.

---

### ACR Access

To support pulling images from a private Azure Container Registry (ACR), add an Azure role assignment for the VMSS node (`kubelet`) identity to the appropriate ACR.

```yaml
resource "azurerm_role_assignment" "accurint_acr" {
  scope                = azurerm_container_registry.accurintacr.id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.kubelet_identity.object_id
}
```

The code above requires the ACR and AKS resources be deployed in the same project/subscription and the Terraform user has access to modify them. In many cases, an ACR could be shared by many clusters and deployed in a central subscription, hence the role assignment would need to happen there (this is the reason ACR access is not supported by the module directly).

---

### Multiple Clusters per Subnet

As documented in [CNI Options](#cni-options), the `Azure CNI` plugin officially supports multiple clusters in a subnet while `kubenet` does not.

However, given the IP requirements for Azure CNI (see [IP address availability and exhaustion](https://docs.microsoft.com/en-us/azure/aks/configure-kubenet#ip-address-availability-and-exhaustion)) it isn't really feasible to host more than one cluster in a subnet - unless it has a very large CIDR range **or** the clusters are very small (consider that even a 6 node cluster will exhaust a /24 subnet after consideration for node pool upgrades).

Also, while `kubenet` doesn't officially support it, testing hasn't yet highlighted any issues. Each cluster **must** have a unique `podnet_cidr` range so route table rules don't clash (increment the second octet for each cluster, e.g. `100.65.0.0/16`, `100.66.0.0/16` ...). However this **must not** be used in production given the current Azure support policy.

<br>
---
<br>

## Service User Guide

How to interact with core services deployed by the module to support user services.

### Azure AD Pod Identity

Should a Kubernetes pod need to access the Azure API it will need appropriate authn/authz access.

The module deploys the `aad-pod-identity` service to support this via the following process:

* Create an Azure AD managed identity
* Assign the managed identity appropriate Azure RBAC permissions
* Configure `AzureIdentity` and `AzureIdentityBindings` resources to reference the managed identity

See the [Pod Identity walkthrough](https://azure.github.io/aad-pod-identity/docs/demo/standard_walkthrough/#2-create-an-identity-on-azure) from step 2 for implementation details.

> the `AzureIdentity` resource **must** be created in the same namespace as the pod

### Ingress

Ingress resources and controllers are used to route traffic into a cluster.

In early versions of Kubernetes the only way to achieve this was though a service of [type LoadBalancer](https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer), in some clouds this requires a discrete load balancer be deployed for each service which has significant cost implications. This doesn't apply to Azure, it adds a new IP for each service to an existing load balancer - however Ingress is still the most effective route to expose services for the following reasons.

* It integrates with `cert-manager` to automate [TLS Certificate](#tls-certificates) generation and renewals
* It integrates with `external-dns` to automate [DNS](#external-dns) record management
* It supports L7 routing based on host or paths (load balancers are L4 only)
* Some ingress controllers (*e.g. nginx*) also offer L4 support

By default the platform deploys an internal ingress class (`core-internal`) to expose services such as Prometheus and Grafana UIs. This shouldn't be used for user services unless there is only minimal internal ingress requirements, instead deploy a dedicated ingress tier and ingress controller.

See the [Ingress](/modules/core-config/modules/ingress_internal_core/README.md) documentation for implementation details.

---

### External DNS

The `external-dns` service will look for annotations on `service` resources or host definitions on `ingress` resources and update Azure DNS records accordingly. The most common use case will be ingress resources, the following ingress resource will create a `management-ui` DNS record in the `us-accurint-prod.azure.lnrsg.io` public zone.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: accurint-management-ui
  namespace: management-ui
spec:
  ingressClassName: public
  rules:
  - host: management-ui.us-accurint-prod.azure.lnrsg.io
    http:
      paths:
      - backend:
          service:
            name: management-ui
            port:
              number: 9001
        path: /
        pathType: Prefix
  tls:
  - hosts:
    - management-ui.us-accurint-prod.azure.lnrsg.io
```

See [external-dns documentation](https://github.com/kubernetes-sigs/external-dns/blob/master/docs/faq.md#how-do-i-specify-a-dns-name-for-my-kubernetes-objects) for more details.

---

### TLS Certificates

The `cert-manager` service automates issuance and renewal of TLS certificates, the primary use case is for [ingress resources](https://cert-manager.io/docs/usage/ingress/).

The module implements a default `ClusterIssuer` (*letsencrypt-issuer*), which issues certificates from Let's Encrypt Production or Staging CAs. Ingress resource without the [cert-manager.io/cluster-issuer](https://cert-manager.io/docs/usage/ingress/) annotaion will be issued from the default issuer. In addition it implements a wildcard certificate, used by any ingress resource without a `secretName` in the `tls` configuration. This was implemented to mitigate [Let's Encrypt rate limits](https://letsencrypt.org/docs/rate-limits/) (50 certificates per week) against the top level domain.

The `external-dns` example above uses the default issuer and wildcard due to the absense of cert-manager annotation and `secretName` tls configuration respectively. If `secretName` is defined, a custom certificate will be issued to the service, however this counts against the top level domain (TLD) rate limits (in this case *lnrsg.io*) for the Let's Encrypt production CA.

Additional issuers can be added using module inputs, see the [cert-manager documentation](https://cert-manager.io/docs/) for more details.

> Let's Encrypt issuers **must not** be used for customer services, only internal services

---

### Network Policy

Kubenetes network policy is used to control traffic flow to and from pods in a cluster, internally and externally.

The module enables the Calico CNI plugin which supports [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/).

Both native Kubernetes Network Policies and extended [Calico Network Policies](https://docs.projectcalico.org/security/calico-network-policy) are supported. The service provides a Kubernetes Operator, which enables Calico Network Policies to be deployed natively through Kubernetes resources without requiring use of an external tool (`calicoctl`).

> be extrememly careful if deploying Calico [Global Network Policy](https://docs.projectcalico.org/reference/resources/globalnetworkpolicy) as this could render a cluster unusable

---

### Metrics & Alerts

The module deploys a Prometheus and Grafana stack which can be used to manage metrics and alerts.

The Prometheus, Grafana and AlertManager UIs are reachable via a built-in `core-internal` ingress class, see the [Ingress](/modules/core-config/modules/ingress_internal_core/README.md) documentation for implementation details and how to determine the URLs to access them.

The Prometheus Operator [supports integration](https://github.com/prometheus-operator/prometheus-operator#customresourcedefinitions) of ServiceMonitor, PodMonitor and PrometheusRule (and other) configuration via Custom Resource Definitions (CRDs), which provide a method to translate native Kubernetes manifests to Prometehus configuration and support dynamic updates. 

The core Prometheus service provides an opt-in approach for user services, should teams wish to use the core service to scrape their services or use custom rules. This is enabled by adding the `lnrs.io/monitoring-platform = core-prometheus` label to CRD resources.

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: example-app
  labels:
    lnrs.io/monitoring-platform: core-prometheus
spec:
  selector:
    matchLabels:
      app: example-app
  endpoints:
  - targetPort: 9198
    interval: 10s
```

The module provides a set of [built-in PrometheusRules](modules/core-config/modules/kube-prometheus-stack/resources) to alert on common issues with the cluster and resources.

See the [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator) documentation for more details.

---

### Azure Monitor Container Insights

The module can be configured to send logs and metrics to Log Analytics via the [Container Insights](https://docs.microsoft.com/en-us/azure/aks/monitor-aks#container-insights) add-on.

This is enabled by setting the `log_analytics_workspace_id` variable to a valid workspace which must already exist and be provisioned outwith the module. Note by setting this option you are consenting for Azure to deploy and fully manage a set of pods on the cluster to provide this integration, any issues must be raised directly with Azure support.

This integration duplicates some functionality that already exists within the module, for example the agents deploy another set of `fluent-bit` pods which will double IO load for log scraping. To avoid sending unnecessary data to Log Analytics (which could have a significant cost impact), carefully eview and configure [agent settings](https://docs.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-agent-config).