#!/bin/bash
# SwiftDE / Wayfire 0.12 build script for Ubuntu 26.04 (run INSIDE the VM after Ubuntu install)
set -e
sudo apt update
sudo apt install -y git meson ninja-build gcc g++ pkg-config \
  libwayland-dev wayland-protocols libwlroots-dev \
  libcairo2-dev libpango1.0-dev libgdk-pixbuf-2.0-dev libxml2-dev \
  libjson-c-dev libevdev-dev libinput-dev libpixman-1-dev libglm-dev \
  libfmt-dev libspdlog-dev libglew-dev libeigen3-dev \
  wayland-utils wl-clipboard kitty weston \
  libxkbcommon-dev libseat-dev libdisplay-info-dev libliftoff-dev libtomlplusplus-dev \
  nlohmann-json3-dev doctest-dev

SWIFTDE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${SWIFTDE_DIR}"
cd "$SRC"
meson setup build --wipe || meson setup build
ninja -C build
echo "=== Build done. Test: ==="
echo "  ./build/src/wayfire -c ./wayfire.ini   (from TTY, or nested with WLR_BACKENDS=wayland)"
