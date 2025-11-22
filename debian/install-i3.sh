#!/bin/bash
# Install i3 Window Manager on Debian-based systems

set -e

echo "[*] Installing i3 Window Manager..."

# Check if running on Debian-based system
if ! command -v apt &> /dev/null; then
    echo "[ERROR] This script is for Debian-based systems only"
    exit 1
fi

echo "[*] Installing i3 and utilities..."
sudo apt update
sudo apt install -y i3 i3-wm i3status i3lock dmenu suckless-tools feh picom nitrogen rofi polybar zenity fonts-font-awesome

echo "[*] Configuring i3 defaults..."
mkdir -p "$HOME/.config/i3"
mkdir -p "$HOME/.config/polybar"
mkdir -p "$HOME/.config/rofi"
mkdir -p "$HOME/Pictures"
mkdir -p "$HOME/.local/bin"

# Get Config Directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/configs"

# Download a nice default wallpaper
if [ ! -f "$HOME/Pictures/bg.jpg" ]; then
    echo "[*] Downloading default wallpaper..."
    wget -q -O "$HOME/Pictures/bg.jpg" "https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?q=80&w=1920&auto=format&fit=crop"
fi

# Install Help Script
cp "$CONFIG_DIR/i3-help.sh" "$HOME/.local/bin/i3-help"
chmod +x "$HOME/.local/bin/i3-help"

# Install Polybar Configs
cp "$CONFIG_DIR/polybar-launch.sh" "$HOME/.config/polybar/launch.sh"
chmod +x "$HOME/.config/polybar/launch.sh"
cp "$CONFIG_DIR/polybar-config.ini" "$HOME/.config/polybar/config.ini"

# Install Rofi Config
cp "$CONFIG_DIR/rofi-config.rasi" "$HOME/.config/rofi/config.rasi"

# Install i3 Config
# Only overwrite if it doesn't exist or force is requested (logic simplified for install script)
if [ ! -f "$HOME/.config/i3/config" ]; then
    cp "$CONFIG_DIR/i3-config" "$HOME/.config/i3/config"
    echo "[OK] Created default i3 config"
else
    echo "[INFO] i3 config already exists, backing up..."
    mv "$HOME/.config/i3/config" "$HOME/.config/i3/config.bak.$(date +%s)"
    cp "$CONFIG_DIR/i3-config" "$HOME/.config/i3/config"
    echo "[OK] Updated i3 config (old backed up)"
fi

echo "[OK] i3 Window Manager installed successfully!"
echo "   - Polybar (Top bar)"
echo "   - Nitrogen (Wallpaper)"
echo "   - Rofi (Launcher)"
echo "   - Help Shortcut (Win+Shift+?)"
echo ""
echo "[TIP] You must set the wallpaper once manually:"
echo "      Run: nitrogen --set-zoom-fill --save ~/Pictures/bg.jpg"
echo ""
