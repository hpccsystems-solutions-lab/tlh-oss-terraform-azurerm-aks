# Role Based Access Control (RBAC)

## Kubernetes RBAC

### Cluster Roles

To assign Kubernetes cluster roles to Azure AD users or groups, use the `azuread_k8s_role_map` as follows.

```yaml
  azuread_k8s_role_map = {
    cluster_admin_users  = {
      "murtaghj@b2b.regn.net" = "d76d0bbd-3243-47e2-bdff-b4a8d4f2b6c1"
    }
    cluster_view_users = {
      "IOB AKS-1 View MID"    = "ca55d5e2-99f6-4047-baef-333313edcf98"
    }
    standard_view_users  = {
      "longm@b2b.regn.net"    = "d64e3f6b-6b16-4235-b4ce-67baa24a593d"
      "patelp@b2b.regn.net"   = "60b29c0c-00bb-48b3-9b9a-cfc3213c5d7d"
    }
    standard_view_groups = {
      "IOB AKS Viewers"       = "3494a2b5-d6e5-49f2-9cf7-542004cbe44d"
    }
  }
```

> map keys (*e.g. IOB AKS Viewers*) are only implemented for audit & transparency purposes, they are not used within the code

#### Object Id Lookup

In the Azure Portal select Azure Active Directory then either *Users* or *Groups*, select the resource then copy the *Object Id* field.

To lookup via the `az` cli:

```bash
$ az ad user show --id murtaghj_b2b.regn.net#EXT#@RBAHosting.onmicrosoft.com --query objectId -o tsv
d76d0bbd-3243-47e2-bdff-b4a8d4f2b6c1
$ az ad group show --group "IOB AKS Viewers" --query objectId -o tsv
3494a2b5-d6e5-49f2-9cf7-542004cbe44d
```

#### Role Assignment

Only user based assignment is supported for privileged roles for the following reasons:

* To provide more transparency for cluster operators and InfoSec teams reviewing the Terraform code or Azure role assignments
* To ensure role assignments are managed in tandem with cluster lifecycle (*e.g. roles will be unassigned on cluster deletion*)

Azure AD Groups are not deployed via Terraform due to privileges required in the tenant, so groups must be managed independently.

> Group assignment is only supported for the standard view role for the use case of multi-cluster visibility

#### Role Mapping

`cluster_admin_users` is bound to the built-in _**cluster-admin**_ clusterrole, providing full access to the cluster.

`cluster_view_users` is bound to the `lnrs:cluster-view` role with full read access to the cluster, including secrets.

`standard_view_[users|groups]` is bound to the `lnrs:view` role, inherited from the built-in _**view**_ clusterrole with custom permissions.

<br>

## Azure RBAC

### AKS Cluster User Role

The [AKS Cluster User Role](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#azure-kubernetes-service-cluster-user-role) is required to [download a kubeconfig](https://docs.microsoft.com/en-us/azure/aks/control-kubeconfig-access) for Azure AD integrated clusters.

This is assigned to all AAD users or groups configured within `azuread_k8s_role_map`, directly on the AKS cluster resource.

### AKS Cluster Admin Role

The [AKS Cluster Admin Role](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#azure-kubernetes-service-cluster-admin-role) is required to retrive the cluster-admin credentials.

This role in avalable to subscription Contributors and must only be used in break-glass scenarios where Azure AD integration is broken. 

<br>

## Module Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
|cluster_id|AKS cluster resource Id|string|n/a|yes|
|azuread_k8s_role_map|Map of Kubernetes roles to AAD user or group Ids|<pre>object({<br>    cluster_admin_users  = map(string)<br>    cluster_view_users   = map(string)<br>    standard_view_users  = map(string)<br>    standard_view_groups = map(string)<br>})</pre>|null|no|
