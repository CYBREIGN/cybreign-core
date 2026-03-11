#!/usr/bin/env bash

echo "[CYBREIGN] Installing core..."

INSTALL_DIR="${PREFIX:-/usr/local}/bin"

URL="https://raw.githubusercontent.com/cybreign/cybreign-core/main/cybreign"

curl -L "$URL" -o "$INSTALL_DIR/cybreign"

chmod +x "$INSTALL_DIR/cybreign"

echo
echo "CYBREIGN installed successfully!"
echo "Run: cybreign help"
