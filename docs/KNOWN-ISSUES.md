# Known issues (native arm64 build)

## 1. sun60iw2/T736 (Zero 3W): aic8800 WiFi firmware missing from image

**Symptom** (first boot, serial console or dmesg):

```
aicbsp: aicbsp_8800d80_fw_init ...
aic8800d80/fw_patch_table_8800d80_u02.bin failed with error -2
aicbsp: aicbsp_sdio_remove done
```

No `wlan0` interface; `ip addr` only shows `lo`.

**Cause**: the upstream `orangepi-firmware_*.deb` (built for `orangepizero3w`)
does not ship the aic8800 firmware files (`/lib/firmware/aic8800d80/*`),
while the kernel modules (`aic8800_bsp`, `aic8800_fdrv`, `aic8800_btlpm`)
are built and loaded correctly.

**Fix**: inject the firmware into the image after build:

```bash
# copy /lib/firmware/aic8800d80 from a working Zero4 image or official image
sudo ./scripts/inject-firmware.sh \
  output/images/Orangepizero3w_*/Orangepizero3w_*.img \
  /path/to/aic8800d80
```

Verified on real Zero 3W: after injection `wlan0` appears and the board
associates with WiFi normally.

**Optional**: also preconfigure WiFi via the vendor first-run mechanism:

```
/boot/orangepi_first_run.txt:
FR_net_change_defaults=1
FR_net_wifi_enabled=1
FR_net_wifi_ssid='...'
FR_net_wifi_key='...'
FR_net_wifi_countrycode='CN'
```
(or drop a NetworkManager keyfile in `/etc/NetworkManager/system-connections/`)

## 2. U-Boot autoboot can be interrupted by a serial-port writing daemon

If the host machine's serial port is opened by another program (e.g. an LED
daemon probing `/dev/ttyUSB*`/`/dev/ttyACM*`) and it writes characters while the
board is at the `Hit any key to stop autoboot` stage, the board stops at the
U-Boot prompt (`=>`). Workaround: restrict the CH340 to root only:

```
SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", MODE="0600", GROUP="root"
```
