#!/usr/bin/env bash

set -e

REPO="${CYBREIGN_REPO:-https://raw.githubusercontent.com/cybreign/cybreign-core/main}"

echo "[CYBREIGN] Installing..."

install_script() {
    INSTALL_DIR="/usr/local/bin"
    TMP="${TMPDIR:-/tmp}/cybreign"

    if [ ! -w "$INSTALL_DIR" ]; then
        SUDO="sudo"
    else
        SUDO=""
    fi

    curl -fsSL "$REPO/cybreign" -o "$TMP"

    $SUDO install -m 755 "$TMP" "$INSTALL_DIR/cybreign"

    rm -f "$TMP"
}

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
    PLATFORM="linux"
fi

echo "Detected platform: $PLATFORM"

################################
# TERMUX INSTALL
################################

if [ "$PLATFORM" = "termux" ]; then

    TMP="$HOME/cybreign.deb"

    curl -L "$REPO/packages/main/cybreign.deb" -o "$TMP"

    dpkg -i "$TMP"

################################
# DEBIAN BASED LINUX
################################

elif [[ "$PLATFORM" = "ubuntu" || "$PLATFORM" = "debian" || "$PLATFORM" = "kali" ]]; then

    install_script

################################
# OTHER LINUX + MACOS
################################

else

    install_script

fi

echo
echo "CYBREIGN installed successfully."
echo "Run: cybreign help"
