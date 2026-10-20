# Build log: Orange Pi Zero 3W built natively on Orange Pi Zero 4

Date: 2026-10-20
Host: Orange Pi Zero 4 (Allwinner A733, 8 cores, 3.8 GiB RAM + 8 GiB swap, SD 118 GiB)
Target: Orange Pi Zero 3W (T736 / sun60iw2), Debian bookworm server
Upstream: orangepi-build @ a05b3b4d5fc0dd4eb859f64c8a60f9b2c9e33cb1

## Environment

- Native Ubuntu 20.04 (focal) arm64 chroot on the board (created with ubuntu-base)
- `arm-linux-gnueabi-gcc` (apt arm64 package) for 32-bit vendor U-Boot
- native `aarch64-linux-gnu-gcc` (via `ccache`) for kernel — no x86_64 cross toolchain
- `qemu-x86_64-static -L /usr/x86_64-linux-gnu` for vendor pack tools
- `OFFLINE_WORK=yes` with pre-seeded u-boot + kernel sources (GitHub fetch was unreliable from the board)

## Results

- U-Boot v2018.05-sun60iw2 built natively and packed (boot0_sdcard.fex + boot_package.fex)
- Linux 6.6.98-sun60iw2 built natively (`Image`, modules, dtbs)
- Debian bookworm rootfs + image assembled
- Image: `Orangepizero3w_1.0.2_debian_bookworm_server_linux6.6.98.img` (3.2 GiB)
- SHA256: `dfb27109504ef42d8ff2c983c1a161d15e6bd801a9ae2f6b4330d1856c5724b1`
- Verified: partition starts at LBA 65536, ext4 mounts, `/boot` contains
  `Image/uImage/boot.scr/orangepiEnv.txt/dtb-6.6.98-sun60iw2`, hostname `orangepizero3w`,
  `/etc/os-release` = "Orange Pi 1.0.2 Bookworm", boot0 magic `eGON.BT0` at offset 8 KiB.

## Timeline (approx.)

- 12:30 setup chroot + sources
- 12:40–15:40 iterations: 9 upstream x86/gcc/network issues (see README table)
- 15:40 first "successful" build (image had empty rootfs partition — silent failure)
- 17:40 loop-device fix → clean rebuild
- 18:05 final image done (17 min with warm ccache), verified
