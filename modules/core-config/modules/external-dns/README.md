# external-dns

[external-dns](https://github.com/kubernetes-sigs/external-dns) is an agent for Kubernetes that detects Kubernetes resources such as services or ingresses in your cluster, and creates/manages DNS records for those resources in a publicly-accessible DNS provider (such as AWS Route 53, Azure DNS and others).

We're integrating it as part of our Kubernetes core config so that your Kubernetes resources become  accessible immediately via DNS.

In Azure, every Azure subscription should be pre-provisioned with an Azure DNS zone that you should use. You can request additional DNS zones to be created if needed.

## Usage

When creating your cluster, you'll have to use the `core_services_config` input variable to pass external-dns configuration down to the agent. Example:

```
module "aks" {
  source = "github.com/LexisNexis-RBA/terraform-azurerm-aks.git"
  ...
  core_services_config = {
    external_dns = {
      resource_group_name = "azure-resource-group-name"
      zones               = ["staging.app.lnrsg.io", "dev.app.lnrsg.io"]
    }
  }
}
```

The resource group name and list of zones are the only supported inputs.
