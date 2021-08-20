# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.0.0-beta.1 - 2021-08-20

> **IMPORTANT** - This pre-release isn't guaranteed to be stable and should not be used in production.

### Added
- Azure Log Analytics support [@appkins](url)
- Ingress node pool [@dutsmiller](url)

### Changed
- Fix default-ssl-certificate in ingress_internal_core module [@sossickd](url)
- User guide updates [@jamurtag](url)

## v0.12.0 - 2021-08-11

> **IMPORTANT** - This pre-release isn't guaranteed to be stable and should not be used in production.

### Added
- Support for k8s 1.21 [@dutsmiller](url)

### Changed
- Node pool variable changes [@dutsmiller](url)
- Change pod_cidr variable to podnet_cidr [@dutsmiller](url) 
- Change core_services_config ingress_core_internal to ingress_internal_core [@dutsmiller](url)
- Change multi-vmss node pool capacity format [@dutsmiller](url)

### Removed
- Remove configmaps, secrets and namespaces variables [@dutsmiller](url)
- Remove assignment of public IPs for nodes in public subnet [@dutsmiller](url)

## v0.11.0 - 2021-07-27

> **IMPORTANT** - This pre-release isn't guaranteed to be stable and should not be used in production.

### Added
- Calico network policy support [@jamurtag](url)
- AKS API firewall support [@dutsmiller](url)

### Changed
- Update README and simplify core_services_config variable input [@jamurtag](url)
- Update upstream AKS module version [@dutsmiller](url)
- Change name of UAI for AKS [@dutsmiller](url)
- Force host encryption to true [@dutsmiller](url)
 
 ### Removed
- Remove additional_priority_classes and additional_storage_classes api options [@jamurtag](url)
- Remove autodoc from repo [@dutsmiller](url)

## v0.10.0 - 2021-07-19

> **IMPORTANT** - This pre-release isn't guaranteed to be stable and should not be used in production.

### Changed
- Tolerate stateful services on system nodepools [@jamurtag](url)
- Rename config variable to core_services_config [@jamurtag](url)

## v0.9.0 - 2021-07-14

> **IMPORTANT** - This pre-release isn't guaranteed to be stable and should not be used in production.

### Added
- Added wildcard certificate for core services [@sossickd](url)
- Documentation for cert-manager, external-dns, priority classes and storage claasses [@fabiendelpierre](url)

### Changed
- Node pool format to match EKS [@dutsmiller](url)