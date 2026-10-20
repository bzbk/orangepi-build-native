#!/bin/bash
# Create a native arm64 Ubuntu/Debian chroot on an ARM64 host (no qemu needed).
# Usage: sudo ./scripts/setup-chroot.sh /opt/opi-build/rootfs-focal focal
set -e
TARGET="${1:?usage: $0 <target-dir> [release]}"
RELEASE="${2:-focal}"
[ "$(uname -m)" = "aarch64" ] || { echo "This script is for ARM64 hosts"; exit 1; }
BASE_URL="https://mirrors.tuna.tsinghua.edu.cn/ubuntu-cdimage/ubuntu-base/releases"
case "$RELEASE" in
  focal) VER=20.04.5 ;;
  jammy) VER=22.04.5 ;;
  noble) VER=24.04.3 ;;
  *) echo "unsupported release: $RELEASE"; exit 1 ;;
esac
mkdir -p "$TARGET"
if [ ! -e "$TARGET/bin/bash" ]; then
  echo "==> Downloading ubuntu-base $VER arm64"
  curl -fsSL "$BASE_URL/$RELEASE/release/ubuntu-base-$VER-base-arm64.tar.gz" | tar -xz -C "$TARGET"
fi
cp -f /etc/resolv.conf "$TARGET/etc/resolv.conf"
case "$RELEASE" in
  focal) SUITE=focal ;;
  jammy) SUITE=jammy ;;
  noble) SUITE=noble ;;
esac
mkdir -p "$TARGET/etc/apt/sources.list.d"
rm -f "$TARGET"/etc/apt/sources.list.d/*.sources 2>/dev/null || true
cat > "$TARGET/etc/apt/sources.list" <<LIST
deb [trusted=yes] http://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ $SUITE main restricted universe multiverse
deb [trusted=yes] http://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ $SUITE-updates main restricted universe multiverse
deb [trusted=yes] http://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ $SUITE-security main restricted universe multiverse
LIST
for d in proc dev sys; do mkdir -p "$TARGET/$d"; mountpoint -q "$TARGET/$d" || mount --bind "/$d" "$TARGET/$d"; done
chroot "$TARGET" /bin/bash -c "apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends sudo git ca-certificates curl debootstrap xxd dos2unix busybox qemu-user-static libc6-amd64-cross device-tree-compiler bc bison flex make gcc g++ zstd"
ln -sf /usr/sbin/debootstrap "$TARGET/usr/bin/debootstrap"
echo "==> chroot ready at $TARGET"
echo "    sudo chroot $TARGET /bin/bash"
