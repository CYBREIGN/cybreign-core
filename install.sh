#!/usr/bin/env bash

set -e

REPO="https://raw.githubusercontent.com/cybreign/cybreign-core/main"

echo "[CYBREIGN] Installing..."

################################
# Detect platform
################################

if [ -n "$PREFIX" ] && [ -d "$PREFIX/bin" ]; then
    PLATFORM="termux"

elif [ "$(uname)" = "Darwin" ]; then
    PLATFORM="macos"

elif grep -qi microsoft /proc/version 2>/dev/null; then
    PLATFORM="wsl"

elif [ -f /etc/os-release ]; then
    . /etc/os-release
    PLATFORM="$ID"

else
    PLATFORM="unknown"
fi

echo "Detected platform: $PLATFORM"

################################
# Termux install
################################

if [ "$PLATFORM" = "termux" ]; then

    TMP="$HOME/cybreign.deb"

    curl -L "$REPO/packages/cybreign.deb" -o "$TMP"

    dpkg -i "$TMP"

################################
# Debian based systems
################################

elif [[ "$PLATFORM" = "ubuntu" || "$PLATFORM" = "debian" || "$PLATFORM" = "kali" ]]; then

    TMP="/tmp/cybreign.deb"

    curl -L "$REPO/packages/cybreign.deb" -o "$TMP"

    sudo dpkg -i "$TMP"

################################
# macOS / fallback
################################

else

    INSTALL_DIR="/usr/local/bin"

    if [ ! -w "$INSTALL_DIR" ]; then
        echo "Using sudo to install..."
        SUDO="sudo"
    fi

    $SUDO curl -L "$REPO/cybreign" -o "$INSTALL_DIR/cybreign"

    $SUDO chmod +x "$INSTALL_DIR/cybreign"

fi

echo
echo "CYBREIGN installed successfully."
echo "Run: cybreign help"
