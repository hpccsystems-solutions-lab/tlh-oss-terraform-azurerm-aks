resource "helm_release" "main" {
  name  = "le-cluster-issuer"
  chart = "${path.module}/chart"

  namespace = var.namespace

  values = [<<-EOT
    name: "letsentrypt-${var.name}"
    namespace: "${var.namespace}"
    email: "${var.letsencrypt_email}"
    server: "${var.letsencrypt_endpoint}"
    subscriptionID: "${var.azure_subscription_id}"
    resourceGroupName: "${var.dns_zone.resource_group_name}"
    hostedZoneName: "${var.dns_zone.name}"
    environment: "${var.azure_environment}"
  EOT
  ]
}
