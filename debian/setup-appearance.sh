#!/bin/bash
# Install Themes and Fonts (Universal)
# Installs to ~/.themes, ~/.icons, and ~/.local/share/fonts
# Works for GNOME, i3, or any other WM

set -euo pipefail

TEMP_DIR=""

cleanup() {
    [[ -n "$TEMP_DIR" ]] && rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo "[*] Setting up universal appearance (themes & fonts)..."

if ! command -v apt &> /dev/null; then
    echo "[ERROR] This script is for Debian-based systems only" >&2
    exit 1
fi

echo "[*] Installing appearance dependencies..."
sudo apt update
sudo apt install -y wget unzip git fontconfig ca-certificates papirus-icon-theme

# Create directories
mkdir -p "$HOME/.themes"
mkdir -p "$HOME/.icons"
mkdir -p "$HOME/.local/share/fonts"

# 1. Install Fonts (Nerd Fonts)
echo "[*] Installing JetBrainsMono Nerd Font..."
TEMP_DIR="$(mktemp -d)"
wget -q -O "$TEMP_DIR/JetBrainsMono.zip" https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip
unzip -q "$TEMP_DIR/JetBrainsMono.zip" -d "$TEMP_DIR/JetBrainsMono"
cp "$TEMP_DIR"/JetBrainsMono/*.ttf "$HOME/.local/share/fonts/"
rm -rf "$TEMP_DIR"
TEMP_DIR=""

# Update font cache
if command -v fc-cache &> /dev/null; then
    fc-cache -f -v > /dev/null 2>&1
    echo "[OK] Fonts installed"
fi

# 2. Install Gruvbox Theme
echo "[*] Installing Gruvbox GTK Theme..."
if [ -d "$HOME/.themes/Gruvbox-Dark-BL" ]; then
    echo "[OK] Gruvbox theme already installed"
else
    TEMP_DIR="$(mktemp -d)"
    git clone --depth 1 https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme.git "$TEMP_DIR/Gruvbox-GTK-Theme"
    # Create directory if not exists (the repo structure might vary, so we find the theme dir)
    # Usually it's in themes/ inside the repo
    if [ -d "$TEMP_DIR/Gruvbox-GTK-Theme/themes" ]; then
        cp -r "$TEMP_DIR"/Gruvbox-GTK-Theme/themes/* "$HOME/.themes/"
        echo "[OK] Gruvbox theme installed to ~/.themes"
    else
        echo "[WARN] Could not find theme directory in cloned repo"
    fi
    rm -rf "$TEMP_DIR"
    TEMP_DIR=""
fi

# 3. Install Icons (Papirus)
echo "[OK] Icons installed"

echo ""
echo "[OK] Appearance assets installed!"
echo "Themes: ~/.themes/"
echo "Icons:  /usr/share/icons/ (Papirus)"
echo "Fonts:  ~/.local/share/fonts/"
echo ""
echo "[TIP] Use 'lxappearance' or 'gnome-tweaks' to select them."
