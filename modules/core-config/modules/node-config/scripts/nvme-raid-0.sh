#!/usr/bin/env bash
set -euo pipefail

NAME_PATTERN="${NAME_PATTERN:-"nvme*n*"}"
MD_DEVICE="${MD_DEVICE:-/dev/md0}"
MOUNT_DIR="${MOUNT_DIR:-/mnt/scratch}"

# Check if running as root
if [[ "$(id -u)" != "0" ]]
then
  >&2 echo "This script must be run as root."
  exit 1
fi

# Check if RAID-0 array exists
if [[ -e "${MD_DEVICE}" ]]
then
  echo "RAID-0 array already exists as ${MD_DEVICE}."

  # Check if array is already mounted
  if grep -qs "${MD_DEVICE}" /proc/mounts
  then
    echo "RAID-0 array is already mounted on ${MOUNT_DIR}."
    exit 0
  fi

  mkfs.xfs -b size=4096 -l su=8b "${MD_DEVICE}" -f
  fstab_entry="UUID=$(blkid -s UUID -o value "${MD_DEVICE}")    ${MOUNT_DIR}    xfs    defaults,nofail    0    2"

  # Mount the array
  mkdir -p "${MOUNT_DIR}"
  if ! grep -q "${fstab_entry}" /etc/fstab
  then
    printf '%s\n' "${fstab_entry}" >> /etc/fstab
  fi
  mount -a
  echo "RAID-0 array mounted to ${MOUNT_DIR}."

else
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

  # Check if there are enough ephemeral disks
  if [[ "${nvme_drive_count}" -lt 2 ]]
  then
    >&2 echo "You need at least 2 NVMe devices for RAID-0."
    exit 1
  fi

  # Create the RAID-0 array
  # shellcheck disable=SC2086
  mdadm --create --force --verbose \
    "${MD_DEVICE}" \
    --level=0 \
    --raid-devices="${nvme_drive_count}" \
    ${nvme_drives}

  # Wait for resync to finish
  while mdadm --detail "${MD_DEVICE}" | grep -qE 'State :.*resyncing'
  do
    echo "Raid is resyncing..."
    sleep 1
  done

  # Format the array
  mkfs.xfs -b size=4096 -l su=8b "${MD_DEVICE}" -f
  fstab_entry="UUID=$(blkid -s UUID -o value "${MD_DEVICE}")    ${MOUNT_DIR}    xfs    defaults,nofail    0    2"
  mkdir -p "${MOUNT_DIR}"
  if ! grep -q "${fstab_entry}" /etc/fstab
  then
    printf '%s\n' "${fstab_entry}" >> /etc/fstab
  fi
  mount -a
  echo "RAID-0 array created and mounted to ${MOUNT_DIR}."
fi

# Check if array was added to /etc/fstab
if grep -qs "${fstab_entry}" /etc/fstab
then
  echo "RAID-0 array has been added to /etc/fstab."
else
  >&2 echo "Failed to add RAID-0 array to /etc/fstab."
  exit 1
fi

# Unused for now
# # Create a systemd service to mount the array on boot
# cat << EOF > /etc/systemd/system/mdadm.service
# [Unit]
# Description=Mount mdadm RAID-0 array
# After=local-fs.target
#
# [Service]
# Type=oneshot
# ExecStart=/bin/mount "$MD_DEVICE" "${MOUNT_DIR}"
# RemainAfterExit=yes
#
# [Install]
# WantedBy=multi-user.target
# EOF
#
# # Reload systemd config and enable the new service
# systemctl daemon-reload
# systemctl enable mdadm.service
# echo "Systemd service created to mount RAID-0 array on boot"

##
# Core Team Readme
#
# - Check Array Status
#   Command: cat /proc/mdstat
#
# - Array Info
#   Command: sudo mdadm --detail --scan --verbose
#
# - Kernel messages for mounting at startup
#   Command: dmesg | grep xfs
#
# - Detail on md device
#   Command: sudo mdadm --detail /dev/md0
#
# - Steps to Tear Down the RAID
#   1. Unmount the RAID array
#      Command: sudo umount /mnt/scratch
#   2. Stop the RAID array
#      Command: sudo mdadm --stop /dev/md0
#   3. Remove the RAID array
#      Command: sudo mdadm --remove /dev/md0
#   4. Remove the "scratch" entry from /etc/fstab
#      Command: sudo sed -i '/scratch/d' /etc/fstab
#   5. Remove filesystem signatures from underlying devices
#      Command: sudo wipefs -a /dev/nvme*n*
#   6. Remove the mdadm configuration file
#      Command: sudo rm /etc/mdadm/mdadm.conf
