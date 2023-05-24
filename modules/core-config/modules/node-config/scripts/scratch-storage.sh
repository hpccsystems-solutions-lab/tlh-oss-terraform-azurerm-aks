#!/usr/bin/env bash
set -euo pipefail

export MOUNT_DIR="/mnt/scratch"

NAME_PATTERN="${NAME_PATTERN:-"nvme*n*"}"
MD_DEVICE="${MD_DEVICE:-/dev/md0}"
MOUNT_DIR="${MOUNT_DIR:-/mnt/scratch}"
TMP_DRIVE="/dev/sdb1"

# Check if running as root
if [[ "$(id -u)" != "0" ]]
then
  >&2 echo "This script must be run as root."
  exit 1
fi

nvme_drive_count=0
nvme_drives=""

# Lookup drives
for nvme_drive in /dev/${NAME_PATTERN}
do
  if [[ -e "${nvme_drive}" ]]
  then
    nvme_drive_count=$(( nvme_drive_count + 1 ))

    if [[ -z "${nvme_drives}" ]]
    then
      nvme_drives="${nvme_drive}"
    else
      nvme_drives="${nvme_drives} ${nvme_drive}"
    fi
  fi
done

if [[ "${nvme_drive_count}" -gt 1 ]]
then
  /opt/lnrs-scripts/nvme-raid-0.sh
elif [[ "${nvme_drive_count}" -eq 1 ]]
then
  drive="${nvme_drives}"
  if ! mount | grep -q "${drive}"
  then
    mkfs.xfs -b size=4096 -l su=8b "${drive}" -f
    fstab_entry="UUID=$(blkid -s UUID -o value "${drive}")    ${MOUNT_DIR}    xfs    defaults,nofail    0    2"
    mkdir -p "${MOUNT_DIR}"
    if ! grep -q "${fstab_entry}" /etc/fstab
    then
      printf '%s\n' "${fstab_entry}" >> /etc/fstab
    fi
    mount -a
    echo "Single NVMe drive mounted to ${MOUNT_DIR}."

    # Check if drive was added to /etc/fstab
    if grep -q "${fstab_entry}" /etc/fstab
    then
      echo "Drive has been added to /etc/fstab."
    else
      echo "No new drive added to /etc/fstab."
    fi
  else
    echo "The drive ${drive} is already mounted. No action taken."
  fi
elif [[ -e "${TMP_DRIVE}" ]]
then
  mkdir -p "${MOUNT_DIR}"
  echo "Temp disk ${TMP_DRIVE} is already mounted. Directory ${MOUNT_DIR} created."
else
  >&2 echo "No NVMe drives or temp disk ${TMP_DRIVE} detected."
  exit 1
fi

