#!/usr/bin/env bash
set -euo pipefail

NAME_PATTERN="${NAME_PATTERN:-"nvme*n*"}"
MD_DEVICE="${MD_DEVICE:-/dev/md0}"
MOUNT_DIR="${MOUNT_DIR:-/mnt/scratch}"

echo "[INFO] Initializing RAID-0 setup process..."

if [[ "$(id -u)" != "0" ]]
then
  >&2 echo "[ERROR] This script must be executed with root privileges."
  exit 1
fi

echo "[INFO] Checking if RAID-0 array exists..."
if [[ -e "${MD_DEVICE}" ]]
then
  echo "[INFO] Detected existing RAID-0 array at ${MD_DEVICE}."

  echo "[INFO] Checking if array is already mounted..."
  if grep -qs "${MD_DEVICE}" /proc/mounts
  then
    echo "[INFO] The RAID-0 array is already mounted at ${MOUNT_DIR}. No further action required."
    exit 0
  fi

  echo "[INFO] Preparing to format the existing RAID-0 array..."
  mkfs.xfs -b size=4096 -l su=8b "${MD_DEVICE}" -f

  echo "[INFO] Setting up the RAID-0 array for mounting..."
  fstab_entry="UUID=$(blkid -s UUID -o value "${MD_DEVICE}")    ${MOUNT_DIR}    xfs    defaults,nofail    0    2"

  echo "[INFO] Creating directory for mounting at ${MOUNT_DIR}..."
  mkdir -p "${MOUNT_DIR}"

  echo "[INFO] Adding RAID-0 array to /etc/fstab if not already present..."
  if ! grep -q "${fstab_entry}" /etc/fstab
  then
    printf '%s\n' "${fstab_entry}" >> /etc/fstab
  fi
  mount -a
  echo "[SUCCESS] RAID-0 array successfully mounted at ${MOUNT_DIR}."

  echo "[INFO] Creating marker file on the filesystem..."
  touch "${MOUNT_DIR}/marker.file"
  if [[ -e "${MOUNT_DIR}/marker.file" ]]; then
    echo "[SUCCESS] Marker file created at ${MOUNT_DIR}/marker.file."
  else
    >&2 echo "[ERROR] Failed to create marker file!"
    exit 1
  fi
else
  echo "[INFO] Searching for NVMe drives..."
  nvme_drive_count=0
  nvme_drives=""

  for nvme_drive in /dev/${NAME_PATTERN}
  do
    if [[ -e "${nvme_drive}" ]]
    then
      nvme_drive_count=$(( nvme_drive_count + 1 ))
      echo "[INFO] Found NVMe drive: ${nvme_drive}"

      if [[ -z "${nvme_drives}" ]]
      then
        nvme_drives="${nvme_drive}"
      else
        nvme_drives="${nvme_drives} ${nvme_drive}"
      fi
    fi
  done

  echo "[INFO] Checking if there are enough NVMe devices for RAID-0..."
  if [[ "${nvme_drive_count}" -lt 2 ]]
  then
    >&2 echo "[ERROR] Minimum 2 NVMe devices are required for RAID-0 configuration."
    exit 1
  fi

  echo "[INFO] Creating the RAID-0 array..."
  # shellcheck disable=SC2086
  mdadm --create --force --verbose "${MD_DEVICE}" --level=0 --raid-devices="${nvme_drive_count}" ${nvme_drives}

  echo "[INFO] Awaiting RAID resynchronization..."
  while mdadm --detail "${MD_DEVICE}" | grep -qE 'State :.*resyncing'
  do
    echo "[INFO] RAID resyncing in progress. Please wait..."
    sleep 1
  done

  echo "[INFO] Formatting the newly created RAID-0 array..."
  mkfs.xfs -b size=4096 -l su=8b "${MD_DEVICE}" -f

  echo "[INFO] Creating directory for mounting at ${MOUNT_DIR}..."
  mkdir -p "${MOUNT_DIR}"

  echo "[INFO] Adding RAID-0 array to /etc/fstab..."
  fstab_entry="UUID=$(blkid -s UUID -o value "${MD_DEVICE}")    ${MOUNT_DIR}    xfs    defaults,nofail    0    2"
  if ! grep -q "${fstab_entry}" /etc/fstab
  then
    printf '%s\n' "${fstab_entry}" >> /etc/fstab
  fi
  mount -a
  echo "[SUCCESS] RAID-0 array successfully created and mounted at ${MOUNT_DIR}."

  echo "[INFO] Creating marker file on the filesystem..."
  touch "${MOUNT_DIR}/marker.file"
  if [[ -e "${MOUNT_DIR}/marker.file" ]]; then
    echo "[SUCCESS] Marker file created at ${MOUNT_DIR}/marker.file."
  else
    >&2 echo "[ERROR] Failed to create marker file!"
    exit 1
  fi
fi

echo "[INFO] Verifying the RAID-0 array in /etc/fstab..."
if grep -qs "${fstab_entry}" /etc/fstab
then
  echo "[INFO] RAID-0 array entry confirmed in /etc/fstab."
else
  >&2 echo "[ERROR] RAID-0 array entry is missing from /etc/fstab!"
  exit 1
fi

echo "[SUCCESS] RAID-0 setup process has been completed!"

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
