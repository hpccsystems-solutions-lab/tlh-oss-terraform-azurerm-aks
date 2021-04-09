#!/usr/bin/env bash
set -euo pipefail

while [ ! -f "${KUBECONFIG}" ]; do sleep 5; done

if [ -z "${APPLY_FILE}" ]
then
  manifest_file="$(mktemp -p /tmp)"
  trap '{ rm -f "${manifest_file}"; }' EXIT

  printf '%s' "${APPLY_CONTENT}" > "${manifest_file}"
else
  manifest_file="${APPLY_FILE}"
fi

${KUBECTL} apply --server-side --force-conflicts -f "${manifest_file}"