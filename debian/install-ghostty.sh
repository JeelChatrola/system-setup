#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/platform.sh
source "$SCRIPT_DIR/../lib/platform.sh"

echo "[*] Ensuring Ghostty is installed..."
command -v apt-get >/dev/null 2>&1 || { echo "[ERROR] This script requires apt-get" >&2; exit 1; }

detect_platform
validate_platform "$PLATFORM_ID" "$PLATFORM_VERSION" "$PLATFORM_CODENAME" "$PLATFORM_ARCH" ghostty

if command -v ghostty >/dev/null 2>&1; then
    ghostty --version
    echo "[OK] Ghostty is already installed"
    exit 0
fi

sudo apt-get update
if apt-cache show ghostty >/dev/null 2>&1; then
    sudo apt-get install -y ghostty
elif [[ "$PLATFORM_ID" == ubuntu ]]; then
    echo "[*] Ghostty is unavailable in configured repositories; adding the supported Ubuntu noble PPA."
    sudo apt-get install -y software-properties-common
    sudo add-apt-repository -y ppa:mkasberg/ghostty-ubuntu
    sudo apt-get update
    sudo apt-get install -y ghostty
else
    echo "[ERROR] Ghostty is unavailable from the configured Debian 12 repositories." >&2
    echo "[ERROR] Enable a Debian repository that packages Ghostty or install it manually from https://ghostty.org/docs/install/binary." >&2
    echo "[ERROR] An Ubuntu PPA will not be added to Debian." >&2
    exit 1
fi

command -v ghostty >/dev/null 2>&1 || { echo "[ERROR] Ghostty installation did not provide a ghostty executable" >&2; exit 1; }
ghostty --version
echo "[OK] Ghostty installed"
