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

az tag list \
  --subscription "${SUBSCRIPTION_ID}" \
  --resource-id "${RESOURCE_ID}"

if [[ -n "${AZURE_TENANT_ID:-}" ]] && [[ -n "${AZURE_CLIENT_ID:-}" ]] && [[ -n "${AZURE_CLIENT_SECRET:-}" ]]
then
  az logout --username "${AZURE_CLIENT_ID}" > /dev/null 2>&1 || true
fi
