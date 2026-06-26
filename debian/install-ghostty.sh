#!/bin/bash
# Install Ghostty terminal on Debian-based systems (apt / PPA only — no Nix).

set -e

echo "[*] Installing Ghostty..."

if ! command -v apt &>/dev/null; then
  echo "[ERROR] This script is for Debian-based systems only"
  exit 1
fi

if command -v ghostty &>/dev/null; then
  echo "[OK] Ghostty is already installed"
  ghostty --version
  exit 0
fi

sudo apt update

if apt-cache show ghostty &>/dev/null; then
  echo "[*] Installing Ghostty from apt repositories..."
  sudo apt install -y ghostty
else
  echo "[*] Ghostty not in default apt repos; adding community PPA..."
  sudo apt install -y software-properties-common
  sudo add-apt-repository -y ppa:mkasberg/ghostty-ubuntu
  sudo apt update
  sudo apt install -y ghostty
fi

if command -v ghostty &>/dev/null; then
  echo "[OK] Ghostty installed successfully!"
  ghostty --version
else
  echo "[ERROR] Installation failed"
  echo "[TIP] See https://ghostty.org/docs/install/binary"
  exit 1
fi
