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

lookup="$(az aks nodepool list \
  --subscription "${SUBSCRIPTION_ID}" \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --cluster-name "${CLUSTER_NAME}" -o json \
  | jq -r --arg node_pool_name "${NODE_POOL_NAME}" '.[] | select(.name == $node_pool_name)')"

if [[ -n "${lookup}" ]]
then
  az aks nodepool delete \
    --subscription "${SUBSCRIPTION_ID}" \
    --resource-group "${RESOURCE_GROUP_NAME}" \
    --cluster-name "${CLUSTER_NAME}" \
    --name "${NODE_POOL_NAME}"
fi

if [[ -n "${AZURE_TENANT_ID:-}" ]] && [[ -n "${AZURE_CLIENT_ID:-}" ]] && [[ -n "${AZURE_CLIENT_SECRET:-}" ]]
then
  az logout --username "${AZURE_CLIENT_ID}" > /dev/null 2>&1 || true
fi
