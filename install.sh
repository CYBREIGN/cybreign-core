#!/usr/bin/env bash

echo "[CYBREIGN] Installing core..."

URL="https://raw.githubusercontent.com/cybreign/cybreign-core/main/cybreign"

curl -L $URL -o $PREFIX/usr/local/bin/cybreign

chmod +x $PREFIX/usr/local/bin/cybreign

echo
echo "CYBREIGN installed successfully."
echo "Run: cybreign help"
