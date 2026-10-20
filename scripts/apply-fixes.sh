#!/bin/bash
# Post-patch fixes for native arm64 builds.
# Usage: sudo ./scripts/apply-fixes.sh /path/to/orangepi-build
set -e
SRC="${1:-$(pwd)}"
TOOLS="$SRC/external/packages/pack-uboot/tools"

echo "==> Wrapping vendor x86-64 pack tools with qemu (non-amd64 hosts)"
if [ -d "$TOOLS" ]; then
  for f in "$TOOLS"/*; do
    [ -f "$f" ] || continue
    case "$(basename "$f")" in *.x86) continue;; esac
    if file -b "$f" | grep -q "ELF 64-bit LSB.*x86-64"; then
      mv -f "$f" "$f.x86"
      cat > "$f" <<WRAP
#!/bin/sh
DIR="\$(cd "\$(dirname "\$0")" && pwd)"
if [ "\$(dpkg --print-architecture 2>/dev/null || uname -m)" = "amd64" ]; then
    exec "\$DIR/$(basename "$f").x86" "\$@"
fi
exec /usr/bin/qemu-x86_64-static -L /usr/x86_64-linux-gnu "\$DIR/$(basename "$f").x86" "\$@"
WRAP
      chmod 755 "$f"
      echo "    wrapped $(basename "$f")"
    fi
  done
fi

echo "==> Patching U-Boot source tree (gcc compatibility + prebuilt x86 dtc)"
UB="$SRC/u-boot/v2018.05-sun60iw2"
if [ -d "$UB" ]; then
  sed -i 's/ -Werror$/ -Wno-error/' "$UB/Makefile" 2>/dev/null || true
  rm -f "$UB/scripts/dtc/dtc" "$UB"/scripts/dtc/*.o "$UB"/scripts/dtc/*.d
  echo "    u-boot Makefile -Werror disabled; prebuilt dtc removed"
fi

echo "==> Skip git auto-update in extracted source tree"
: > "$SRC/.ignore_changes"

echo "==> Done."
