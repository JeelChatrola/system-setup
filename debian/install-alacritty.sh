#!/bin/bash
# Install Alacritty terminal emulator on Debian-based systems

set -e

echo "[*] Installing Alacritty..."

# Check if running on Debian-based system
if ! command -v apt &> /dev/null; then
    echo "[ERROR] This script is for Debian-based systems only"
    exit 1
fi

# Check if Alacritty is already installed
if command -v alacritty &> /dev/null; then
    echo "[OK] Alacritty is already installed"
    alacritty --version
    exit 0
fi

# Install from PPA (required for Ubuntu 22.04)
echo "[*] Adding Alacritty PPA..."
sudo add-apt-repository -y ppa:aslatter/ppa
sudo apt update

echo "[*] Installing Alacritty..."
sudo apt install -y alacritty

# Verify installation
if command -v alacritty &> /dev/null; then
    echo "[OK] Alacritty installed successfully!"
    alacritty --version
else
    echo "[ERROR] Installation failed"
    exit 1
fi

