#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${AZURE_ENVIRONMENT:-}" ]]
then
  az cloud set --name "${AZURE_ENVIRONMENT}" > /dev/null 2>&1
fi

if [[ -n "${AZURE_TENANT_ID:-}" ]] && [[ -n "${AZURE_CLIENT_ID:-}" ]] && [[ -n "${AZURE_CLIENT_SECRET:-}" ]]
then
  az login --service-principal --user "${AZURE_CLIENT_ID}" --password "${AZURE_CLIENT_SECRET}" --tenant "${AZURE_TENANT_ID}" > /dev/null 2>&1
fi

az tag update \
  --subscription "${SUBSCRIPTION_ID}" \
  --resource-id "${RESOURCE_ID}" \
  --operation merge \
  --tags "${RESOURCE_TAGS}"

if [[ -n "${AZURE_TENANT_ID:-}" ]] && [[ -n "${AZURE_CLIENT_ID:-}" ]] && [[ -n "${AZURE_CLIENT_SECRET:-}" ]]
then
  az logout --username "${AZURE_CLIENT_ID}" > /dev/null 2>&1 || true
fi
