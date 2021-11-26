# Azure - Kubernetes Pod Identity Module

## Introduction

This module creates an Azure Managed Identity, Azure Role Assignments for the managed identity and the Kubernetes Azure AD Pod Identity `AzureIdentity` and `AzureIdentyBinding` custom resources to bind to the Azure managed identity.
<br />

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `resource_group_name` | Resource Group name hosting the managed identity | `string` | n/a | yes |
| `location` | Azure region hosting the AKS service | `string` | n/a | yes |
| `cluster_name` | AKS cluster name | `string` | n/a | yes |
| `identity_name` | Name of the managed identity | `string` | n/a | yes |
| `namespace` | Kubernetes namespace in which to create identity | `string` | n/a | yes |
| `tags` | Tags to be applied to Azure resources | `map(string)` | n/a | yes |
| `roles` | Azure role definition id (or name) and scope to be applied to the managed identity | `list(object)` | n/a | yes |

`roles` object specification.

| **Variable** | **Description**                                                                           | **Type** | **Default** |
| :----------- | :---------------------------------------------------------------------------------------- | :------- | :---------- |
| `role_definition_resource_id`| The role definition resource id **OR** name of the role, supports both    | `string` | `nil`       |
| `scope`      | The scope of the resource to apply the role to                                            | `string` | `nil`       |

## Outputs

| Name | Description |
|------|-------------|
| `name` | name of the user assigned identity |
| `client_id` | client id of user assigned identity |
| `principal_id` | principal id of user assigned identity |
