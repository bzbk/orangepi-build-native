#!/bin/bash
# Native arm64 Orange Pi image build wrapper.
# Usage: ./native-build.sh BOARD=orangepizero3w BRANCH=current RELEASE=bookworm
set -e
cd "$(dirname "$0")"
ARGS=("$@")
if [ ${#ARGS[@]} -eq 0 ]; then
  ARGS=(BOARD=orangepizero3w BRANCH=current RELEASE=bookworm)
fi
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"
echo "==> Native build: ${ARGS[*]}"
exec ./build.sh "${ARGS[@]}" BUILD_OPT=image BUILD_DESKTOP=no BUILD_MINIMAL=no KERNEL_CONFIGURE=no
