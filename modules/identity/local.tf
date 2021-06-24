#locals {
#  apiVersion = "aadpodidentity.k8s.io/v1"
#  kind       = ""
#  metadata = {
#    name = "letsencrypt-issuer"
#  }
#  spec = {
#    acme = {
#      email  = var.letsencrypt_email
#      server = local.letsencrypt_endpoint[lower(var.letsencrypt_environment)]
#      privateKeySecretRef = {
#        name = "letsencrypt-issuer-privatekey"
#      }
#      solvers = {
#        selector = {
#          dnsNames = [ zone ]
#        }
#        dns01 = {
#          azureDNS = {
#            subscriptionID = var.azure_subscription_id
#            resourceGroupName = rg
#            hostedZoneName = zone 
#            environment: var.azure_environment
#          }
#        }
#
#      }}}}