#!/bin/bash
# Ultra-Compatible Industrial USB Auto-Mount Helper for Siemens IOT2050
LOG=/tmp/usb-mount.log
echo "--- Mount attempt at $(date) ---" > "$LOG"

mkdir -p /media/usb
chmod 777 /media/usb 2>/dev/null || true

# 1. Check if already mounted
if grep -qs '/media/usb ' /proc/mounts; then
  echo "ALREADY_MOUNTED" >> "$LOG"
  echo "SUCCESS"
  exit 0
fi

# 2. Prioritize PARTITIONS first (/dev/sda1, /dev/sdb1, etc.)
TARGETS=""
for p in /dev/sda1 /dev/sda2 /dev/sda3 /dev/sdb1 /dev/sdb2 /dev/sdc1 /dev/sda /dev/sdb; do
  if [ -b "$p" ]; then
    TARGETS="$TARGETS $p"
  fi
done

echo "Found candidate block devices: $TARGETS" >> "$LOG"

if [ -z "$TARGETS" ]; then
  echo "ERROR: No USB Flash Drive detected. Please insert USB."
  exit 1
fi

MOUNTED=0

for dev in $TARGETS; do
  # Detect filesystem type using blkid if available
  FSTYPE=$(blkid -s TYPE -o value "$dev" 2>/dev/null)
  echo "Testing device: $dev (Detected Type: $FSTYPE)" >> "$LOG"

  # Strategy 1: If filesystem is specifically identified
  if [ "$FSTYPE" = "vfat" ] || [ "$FSTYPE" = "fat" ]; then
    mount -t vfat -o rw,umask=000,utf8 "$dev" /media/usb >> "$LOG" 2>&1
    if grep -qs '/media/usb ' /proc/mounts; then MOUNTED=1; break; fi
    mount -t vfat -o rw,umask=000 "$dev" /media/usb >> "$LOG" 2>&1
    if grep -qs '/media/usb ' /proc/mounts; then MOUNTED=1; break; fi
  elif [ "$FSTYPE" = "ntfs" ]; then
    mount -t ntfs-3g -o force,rw,umask=000 "$dev" /media/usb >> "$LOG" 2>&1
    if grep -qs '/media/usb ' /proc/mounts; then MOUNTED=1; break; fi
    mount -t ntfs -o rw,umask=000 "$dev" /media/usb >> "$LOG" 2>&1
    if grep -qs '/media/usb ' /proc/mounts; then MOUNTED=1; break; fi
    mount "$dev" /media/usb >> "$LOG" 2>&1
    if grep -qs '/media/usb ' /proc/mounts; then MOUNTED=1; break; fi
  elif [ "$FSTYPE" = "exfat" ]; then
    # Try all known exfat drivers
    mount.exfat-fuse -o umask=000 "$dev" /media/usb >> "$LOG" 2>&1
    if grep -qs '/media/usb ' /proc/mounts; then MOUNTED=1; break; fi
    mount.exfat -o umask=000 "$dev" /media/usb >> "$LOG" 2>&1
    if grep -qs '/media/usb ' /proc/mounts; then MOUNTED=1; break; fi
    mount -t exfat -o rw,umask=000 "$dev" /media/usb >> "$LOG" 2>&1
    if grep -qs '/media/usb ' /proc/mounts; then MOUNTED=1; break; fi
  fi

  # Strategy 2: Universal Fallbacks
  mount -o rw,umask=000 "$dev" /media/usb >> "$LOG" 2>&1
  if grep -qs '/media/usb ' /proc/mounts; then MOUNTED=1; break; fi

  mount -t vfat -o rw,umask=000 "$dev" /media/usb >> "$LOG" 2>&1
  if grep -qs '/media/usb ' /proc/mounts; then MOUNTED=1; break; fi

  mount -t ntfs-3g -o force,rw "$dev" /media/usb >> "$LOG" 2>&1
  if grep -qs '/media/usb ' /proc/mounts; then MOUNTED=1; break; fi

  mount -t ntfs -o rw "$dev" /media/usb >> "$LOG" 2>&1
  if grep -qs '/media/usb ' /proc/mounts; then MOUNTED=1; break; fi

  mount -o ro "$dev" /media/usb >> "$LOG" 2>&1
  if grep -qs '/media/usb ' /proc/mounts; then MOUNTED=1; break; fi

  mount "$dev" /media/usb >> "$LOG" 2>&1
  if grep -qs '/media/usb ' /proc/mounts; then MOUNTED=1; break; fi
done

if grep -qs '/media/usb ' /proc/mounts; then
  echo "SUCCESS: Mounted to /media/usb" >> "$LOG"
  echo "SUCCESS"
  exit 0
else
  DETECTED_FS=$(blkid -s TYPE -o value /dev/sda1 2>/dev/null || echo "unknown")
  if [ "$DETECTED_FS" = "exfat" ]; then
    echo "ERROR: USB format is exFAT (not supported by Debian). Please format USB to FAT32 or NTFS."
  else
    echo "ERROR: Cannot mount USB ($DETECTED_FS). Please format USB as FAT32 or NTFS."
  fi
  exit 1
fi
