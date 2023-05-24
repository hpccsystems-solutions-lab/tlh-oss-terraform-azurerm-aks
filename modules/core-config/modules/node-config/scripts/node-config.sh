#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" != "0" ]]
then
  >&2 echo "This script must be run as root."
  exit 1
fi

# Currently this is the only use so call explicitly
/opt/lnrs-scripts/scratch-storage.sh
