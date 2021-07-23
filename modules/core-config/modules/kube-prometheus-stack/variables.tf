variable "cluster_name" {
  description = "The name of the cluster that has been created."
  type        = string
}

variable "cluster_version" {
  description = "The Kubernetes minor version of the cluster (e.g. x.y)"
  type        = string
}

variable "skip_crds" {
  description = "Skip installing the CRDs as part of the module."
  type        = bool
}

variable "prometheus_remote_write" {
  description = "Remote Prometheus endpoints to write metrics to."
  type        = list(any)
}

variable "alertmanager_smtp_host" {
  description = "The SMTP host to use for Alert Manager."
  type        = string
}

variable "alertmanager_smtp_from" {
  description = "The SMTP from address to use for Alert Manager."
  type        = string
}

variable "alertmanager_receivers" {
  description = "Alertmanager recievers to add to the default null."
  type        = list(any)
}

variable "alertmanager_routes" {
  description = "Alertmanager routes."
  type        = list(any)
}

variable "grafana_admin_password" {
  description = "The Grafana admin password."
  type        = string
}

variable "grafana_plugins" {
  description = "Grafana plugins to install."
  type        = list(string)
}

variable "grafana_additional_data_sources" {
  description = "Additional Grafana data sources to add.."
  type        = list(any)
}

variable "ingress_domain" {
  description = "The domain to use for ingress resources."
  type        = string
}

variable "ingress_subdomain_suffix" {
  description = "The suffix for the ingress subdomain."
  type        = string
}

variable "loki_enabled" {
  description = "If Loki is enabled in the cluster."
  type        = bool
}
