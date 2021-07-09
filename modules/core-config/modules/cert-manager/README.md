# cert-manager

[cert-manager](https://cert-manager.io/docs/) is an agent for Kubernetes that manages TLS certificates and certificate issuers. It's intended to facilitate and automate the creation and lifecycle of TLS certificates. Briefly, you configure an issuer against a provider with an API (such as [LetsEncrypt](letsencrypt.org/)), then request certificates through that issuer. cert-manager will then manage the certificate throughouts its life, including renewals.

We're implementing cert-manager as part of our Kubernetes core config so that TLS support is built in. By default, a cluster issuer called `letsencrypt-issuer` will always be created for LetsEncrypt and a list of domains that you must provide.

As there is abundant documentation online on how to use cert-manager, this README focuses only on the input variables you need to provide when setting up your Kubernetes cluster.

## Usage

The AKS module has an input variable called `config` through which you can pass bits of config to this submodule like so:

```
module "aks" {
  source = "github.com/LexisNexis-RBA/terraform-azurerm-aks.git"
  ...
  config = {
    cert_manager = {
      ...
    }
    ...
  }
}
```

The `cert_manager` block is just a key-value map that expects the following keys:

`letsencrypt_environment`: must be `staging` or `production`
`letsencrypt_email`: the email address set on the issuer, the issuer will send emails to that address, such as certificate expiration alerts
`dns_zones`: a map of domain names -> resource groups that your certificates will use
`additional_issuers`: a way to configure issuers in addition to the default

Concrete example:

```
module "aks" {
  source = "github.com/LexisNexis-RBA/terraform-azurerm-aks.git"
  ...
  config = {
    cert_manager = {
      letsencrypt_environment = "production"
      letsencrypt_email = "your.team@lexisnexisrisk.com"
      dns_zones = {
        "domain.lnrsg.io" = "azure-resource-group-name"
      }
    }
  }
}
```

For additional issuers, see the cert-manager documentation as the implementation will vary. See also [this chunk of code](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/blob/429f46386cbcf355e437aec74d234029e0ff1981/modules/core-config/modules/cert-manager/local.tf#L136-L164) showing how the default LetsEncrypt issuer is configured, you can use that as a base for configuring your own issuer if needed.