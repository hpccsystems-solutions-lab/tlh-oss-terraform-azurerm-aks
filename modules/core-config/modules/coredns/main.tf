resource "kubectl_manifest" "configmap" {

  count = length(var.forward_zones) > 0 ? 1 : 0

  yaml_body = <<YAML
  apiVersion: v1
  kind: ConfigMap
  metadata:
    name: coredns-custom
    namespace: kube-system
  data:
    onpremzones.server: |
      %{ for zone, ip in var.forward_zones }
      ${zone}:53 {
          forward . ${ip}
      }
      %{ endfor }
  YAML
  
  server_side_apply = true
}

