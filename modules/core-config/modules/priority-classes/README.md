# Priority classes submodule

## Description

A simple module that creates standard LNRS priority classes for our Kubernetes clusters.

This should be used on all LexisNexis RSG Kubernetes clusters.

For more information on Kubernetes priority classes, refer to the [Kubernetes documentation](https://kubernetes.io/docs/concepts/configuration/pod-priority-preemption/).

### Adding custom priority classes

You can use the `additional_priority_classes` input variable to create/manage extra classes. The same variable also exists as a top-level input in the AKS module (to which this is a submodule) so you can create your extra classes when creating your cluster, and manage them the same way on an ongoing basis.

```hcl
module "aks" {
  source = "github.com/LexisNexis-RBA/terraform-azurerm-aks.git"

  ...
  ...

  additional_priority_classes = {
    name-of-priority-class = {
      description = "A description for this priority class"
      value       = 1500 # lower number = lower priority
      labels      = {
        label1 = "foo"
        label2 = "bar"
      }
      annotations = {
        "lnrs.io/foo" = "bar"
        "lnrs.io/baz" = "qux"
      }
    }
    name-of-another-priority-class = {
      description = "A description for this priority class"
      value       = 200000
      labels = {
        label1 = "quux"
        label2 = "corge"
      }
      annotations = {}
    }
    and-another-priority-class = {
      ...
    }
  }
}
```

**Notes**: 

- The key of each map nested under your additional_priority_classes will be set as the name of the priority class.
- If you don't need to set labels or annotations in a priority class, you can set those as an empty map (`{}`), as shown in the example above.
- When creating a priority class, the Kubernetes API allows you to set it as the global default for the cluster. Because the default classes created by this module already set a global default, custom priority classes cannot be set as a global default.