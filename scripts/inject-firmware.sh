#!/bin/bash
# Inject missing WiFi/BT firmware into an already-built Orange Pi image.
#
# Why: upstream orangepi-build for sun60iw2/T736 (Zero 3W) ships an
# `orangepi-firmware` deb that does NOT include the aic8800 firmware, so on
# first boot the WiFi driver (aic8800_bsp/fdrv) loads but SDIO probe fails:
#   Direct firmware load for aic8800d80/fw_patch_table_8800d80_u02.bin failed (-2)
# and no wlan0 appears.
#
# Usage:
#   sudo ./scripts/inject-firmware.sh <image.img> [firmware-dir]
# Default firmware-dir: /lib/firmware/aic8800d80  (copy from a working Zero4
# image, an official Orange Pi image, or extract from the vendor package).
set -e
IMG="${1:?usage: $0 <image.img> [firmware-dir]}"
FW="${2:-/lib/firmware/aic8800d80}"
[ -f "$IMG" ] || { echo "no image: $IMG"; exit 1; }
[ -d "$FW" ] || { echo "no firmware dir: $FW"; exit 1; }
MNT=$(mktemp -d)
cleanup() { umount "$MNT" 2>/dev/null || true; rmdir "$MNT" 2>/dev/null || true; }
trap cleanup EXIT
mount -o loop,rw,offset=$((65536*512)) "$IMG" "$MNT"
install -d "$MNT/lib/firmware/aic8800d80"
cp -f "$FW"/* "$MNT/lib/firmware/aic8800d80/"
chown -R root:root "$MNT/lib/firmware/aic8800d80"
chmod 644 "$MNT"/lib/firmware/aic8800d80/*
sync
echo "==> Injected $(ls "$MNT/lib/firmware/aic8800d80" | wc -l) firmware files into $IMG"
