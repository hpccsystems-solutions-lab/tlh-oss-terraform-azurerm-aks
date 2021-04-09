#!/usr/bin/env bash
set -euo pipefail

while [ ! -f "${KUBECONFIG}" ]; do sleep 5; done

printf '%s' "${DELETE_CONTENT}" | ${KUBECTL} delete -f -