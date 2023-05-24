#!/usr/bin/env bash
set -euo pipefail

# Copy scripts to host
cp -f /opt/node-config.sh /opt/nvme-raid-0.sh /opt/scratch-storage.sh /host-scripts
chmod +x /host-scripts/*.sh

# Execute from the host namespace
err=0
nsenter -t 1 -m -u -i -n -p -- bash -c /opt/lnrs-scripts/node-config.sh bash && err=0 || err=$?
if [[ "${err}" != 0 ]]
then
  1>&2 echo "Exec failed."
  exit 1
fi
