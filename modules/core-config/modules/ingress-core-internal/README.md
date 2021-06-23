# Ingress

This guide describes how to deploy and use [ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) resources & controllers.

There are three types of ingress controllers typically deployed in a cluster.

* [Platform](#platform-ingress) - to serve internal platform services via an internal load balancer
* [Private](#private-ingress) - to serve private services via internal load balancer(s)
* [Public](#public-ingress) - to serve internet-facing services via public load balancer(s)

---

## Platform Ingress

The ingress for core platform services (*e.g. Prometheus, Grafana, Alertmanager*).

* Ingress Class: `core-internal`
* Namespace: `ingress-core-internal`

The ingress controller is hosted on the `system` nodepool to optimise resource usage, it is exposed via a private load balancer.

__`NOTE`__ this ingress class is not intended to serve non-platform components - use a separate ingress tier and controller

---

## Private Ingress

Deploy an ingress nodepool to host the ingress controller.

```yaml
  node_pools = [
    {
      name = "public"
      tier = "ingress"
      lifecycle = "normal"
      vm_size = "medium"
      os_type = "Linux"
      min_count = "3"
      max_count = "6"
      labels = {}
      tags = {}
    }
  ]
```

Deploy an ingress controller with a custom ingress class (*e.g. private-ingress*) and ensure it sets the following options.

* it tolerates the `ingress=true:NoSchedule` taint automatically applied to this tier
* it uses the `lnrs.io/tier=ingress` nodeselector via the label automatically applied to this tier

> the same nodepool can be used for both private and public ingress controllers

---

## Public Ingress

Deploy an ingress nodepool to host the ingress controller.

```yaml
  node_pools = [
    {
      name = "public"
      tier = "ingress"
      lifecycle = "normal"
      vm_size = "medium"
      os_type = "Linux"
      min_count = "3"
      max_count = "6"
      labels = {}
      tags = {}
    }
  ]
```

Deploy an ingress controller with a custom ingress class (*e.g. public-ingress*) and ensure it sets the following options.

* it tolerates the `ingress=true:NoSchedule` taint automatically applied to this tier
* it uses the `lnrs.io/tier=ingress` nodeselector via the label automatically applied to this tier

> the same nodepool can be used for both private and public ingress controllers

