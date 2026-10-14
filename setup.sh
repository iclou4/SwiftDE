#!/bin/bash
# ==============================================================================
# SwiftDE Universal Setup & Installer Script
# Automatically detects current user, home directory, and repository path.
# No manual path fixes or username replacements required.
# ==============================================================================

set -e

SWIFTDE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURRENT_USER="${SUDO_USER:-$USER}"
USER_HOME="$(getent passwd "$CURRENT_USER" | cut -d: -f6)"
if [ -z "$USER_HOME" ]; then
    USER_HOME="$HOME"
fi

echo "=========================================================="
echo "  Setting up SwiftDE macOS Sequoia Desktop Environment   "
echo "=========================================================="
echo "  Repository Path: $SWIFTDE_DIR"
echo "  Target User:     $CURRENT_USER"
echo "  Home Directory:  $USER_HOME"
echo "=========================================================="

# 1. Install Required Dependencies
echo "[1/4] Installing required build and runtime dependencies..."
sudo apt update
sudo apt install -y \
    build-essential \
    cmake \
    pkg-config \
    git \
    qt6-base-dev \
    qt6-declarative-dev \
    liblayershellqt-dev \
    qml6-module-qtquick \
    qml6-module-qtquick-shapes \
    qml6-module-qtquick-window \
    qml6-module-qtquick-controls \
    qml6-module-qtquick-layouts \
    qml6-module-qt5compat-graphicaleffects \
    ydotool \
    gsettings-desktop-schemas \
    network-manager \
    pulseaudio-utils || true

# 2. Build SwiftDE-RunQML
echo "[2/4] Building SwiftDE-RunQML binary..."
MACOS_DIR="$SWIFTDE_DIR/System/Library/CoreServices/Lockscreen.app/Contents/MacOS"
cd "$MACOS_DIR"
cmake -B build
cmake --build build -j"$(nproc)"
cp build/SwiftDE-RunQML "$SWIFTDE_DIR/SwiftDE-RunQML"
chmod +x "$SWIFTDE_DIR/SwiftDE-RunQML"

# 3. Setup Wayland Session
echo "[3/4] Configuring Wayland Session..."
SESSION_SCRIPT="$SWIFTDE_DIR/System/Library/CoreServices/swiftde-session"
chmod +x "$SESSION_SCRIPT"

sudo mkdir -p /usr/share/wayland-sessions
cat <<EOF | sudo tee /usr/share/wayland-sessions/swiftde.desktop > /dev/null
[Desktop Entry]
Name=SwiftDE
Comment=macOS Sequoia Desktop Environment for Linux
Exec=$SESSION_SCRIPT
Type=Application
DesktopNames=SwiftDE
EOF

# 4. User Configuration & Permissions
echo "[4/4] Setting up user configuration directories and permissions..."
mkdir -p "$USER_HOME/.config/swiftde"
chown -R "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.config/swiftde" 2>/dev/null || true

# Enable ydotool service if available
sudo systemctl enable --now ydotoold 2>/dev/null || true

echo "=========================================================="
echo "  SwiftDE setup completed successfully!                   "
echo "=========================================================="
echo "  You can now:"
echo "  1. Log out of your current session."
echo "  2. Click the gear icon on the login screen and choose 'SwiftDE'."
echo "  3. Log in to enjoy macOS Sequoia on Linux."
echo "=========================================================="
