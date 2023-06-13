variable "subscription_id" {
  description = "ID of the subscription."
  type        = string
  nullable    = false
}

variable "location" {
  description = "Azure region in which the AKS cluster is located."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group containing the AKS cluster."
  type        = string
  nullable    = false
}

variable "cluster_name" {
  description = "Name of the Azure Kubernetes managed cluster."
  type        = string
  nullable    = false
}

variable "cluster_oidc_issuer_url" {
  description = "The URL of the cluster OIDC issuer."
  type        = string
}

variable "namespace" {
  description = "Namespace to install the Kubernetes resources into."
  type        = string
  nullable    = false
}

variable "labels" {
  description = "Labels to be applied to all Kubernetes resources."
  type        = map(string)
  nullable    = false
}

variable "log_level" {
  description = "Log level."
  type        = string
  nullable    = false
}

variable "subnet_id" {
  description = "ID of the subnet."
  type        = string
  nullable    = false
}

variable "zones" {
  description = "The number of zones this chart should be run on."
  type        = number
  nullable    = false
}

variable "prometheus_remote_write" {
  description = "Remote Prometheus endpoints to write metrics to."
  type        = any
  nullable    = false
}

variable "alertmanager_smtp_host" {
  description = "The SMTP host to use for Alert Manager."
  type        = string
  nullable    = true
}

variable "alertmanager_smtp_from" {
  description = "The SMTP from address to use for Alert Manager."
  type        = string
  nullable    = true
}

variable "alertmanager_receivers" {
  description = "Alertmanager recievers to add to the default null, will always be a list."
  type = list(object({
    name              = string
    email_configs     = any
    opsgenie_configs  = any
    pagerduty_configs = any
    pushover_configs  = any
    slack_configs     = any
    sns_configs       = any
    victorops_configs = any
    webhook_configs   = any
    wechat_configs    = any
    telegram_configs  = any
  }))
  nullable = false
}

variable "alertmanager_routes" {
  description = "Alertmanager routes, will always be a list."
  type = list(object({
    receiver            = string
    group_by            = list(string)
    continue            = bool
    matchers            = list(string)
    group_wait          = string
    group_interval      = string
    repeat_interval     = string
    mute_time_intervals = list(string)
    # active_time_intervals = list(string)
  }))
  nullable = false
}

variable "grafana_admin_password" {
  description = "The Grafana admin password."
  type        = string
  nullable    = false
}

variable "grafana_additional_plugins" {
  description = "Additional Grafana plugins to install."
  type        = list(string)
  nullable    = false
}

variable "grafana_additional_data_sources" {
  description = "Additional Grafana data sources to add, will always be a list."
  type        = any
  nullable    = false
}

variable "control_plane_log_analytics_enabled" {
  description = "If log analytics should be enabled for the AKS cluster control plane."
  type        = bool
  nullable    = false
}

variable "control_plane_log_analytics_workspace_id" {
  description = "ID of the log analytics workspace for the AKS cluster control plane."
  type        = string
  nullable    = true
}

variable "oms_agent_enabled" {
  description = "If the OMS Agent is enabled."
  type        = bool
  nullable    = false
}

variable "oms_agent_log_analytics_workspace_id" {
  description = "ID of the log analytics workspace for the OMS Agent."
  type        = string
  nullable    = true
}

variable "ingress_class_name" {
  description = "The ingress class for ingress resources."
  type        = string
  nullable    = false
}

variable "ingress_domain" {
  description = "The domain to use for ingress resources."
  type        = string
  nullable    = false
}

variable "ingress_subdomain_suffix" {
  description = "The suffix for the ingress subdomain."
  type        = string
  nullable    = false
}

variable "ingress_annotations" {
  description = "The annotations for ingress resources."
  type        = map(string)
  nullable    = false
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  nullable    = false
}

variable "timeouts" {
  description = "Timeout configuration."
  type = object({
    helm_modify = number
  })
  nullable = false
}

variable "experimental_prometheus_memory_override" {
  description = "Provide experimental feature flag configuration."
  type        = string
  nullable    = true
}
