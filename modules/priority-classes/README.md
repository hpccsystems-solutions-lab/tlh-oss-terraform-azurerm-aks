# terraform-kubernetes-priority-class

## Description

A simple module that creates standard LNRS priority classes for our Kubernetes clusters.

This should be used on all LexisNexis RSG Kubernetes clusters.

For more information on Kubernetes priority classes, refer to the [Kubernetes documentation](https://kubernetes.io/docs/concepts/configuration/pod-priority-preemption/).

## Configuration

You'll need to configure an instance of Terraform's Kubernetes provider so this module will work. 

Read the Kubernetes provider's [documentation](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs#in-cluster-config) to learn how to configure it and use this module.

A simple example using data from an AWS EKS cluster also managed by Terraform would look like this:

```hcl
resource "aws_eks_cluster" "example" {
  ...
}

provider "kubernetes" {
  host = aws_eks_cluster.example.endpoint

  client_certificate     = aws_eks_cluster.example.client_certificate
  client_key             = aws_eks_cluster.example.client_key
  cluster_ca_certificate = aws_eks_cluster.example.cluster_ca_certificate
}
```

Another example using a local kubeconfig file would look like this:

```hcl
provider "kubernetes" {
  config_path = "~/.kube/config"
}
```

## Usage

This module only has a single, optional input, `additional_priority_classes`. You can set it to create any number of priority classes on top of the ones provided by default.

### Standard usage

If you don't need to create additional priority classes, you can call the module simply like this:

```hcl
module "priority_classes" {
  source = "git::https://gitlab.b2b.regn.net/terraform/modules/kubernetes/terraform-kubernetes-priority-class.git"
}
```

### Usage with additional priority classes

If you want custom priority classes, you can invoke the module like this:

```hcl
module "priority_classes" {
  source = "git::https://gitlab.b2b.regn.net/terraform/modules/kubernetes/terraform-kubernetes-priority-class.git"

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

## Contributing

This module's primary repository is on B2B GitLab here: https://gitlab.b2b.regn.net/terraform/modules/kubernetes/terraform-kubernetes-priority-class

Changes made in GitLab are replicated to GitHub automatically here: https://github.com/LexisNexis-RBA/terraform-kubernetes-priority-class

Issues, pull requests, etc. should all be submitted in GitLab using the link above. The copy of the repo in GitHub should never be touched, except by the automated process that synchronizes the repo from GitLab to GitHub.
