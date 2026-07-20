#!/bin/bash
# Install i3 Window Manager on Debian-based systems

set -euo pipefail

echo "[*] Installing i3 Window Manager..."

# Check if running on Debian-based system
if ! command -v apt &> /dev/null; then
    echo "[ERROR] This script is for Debian-based systems only"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../lib/supply-chain.sh
source "$REPO_ROOT/lib/supply-chain.sh"
WALLPAPER_URL='https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?q=80&w=1920&auto=format&fit=crop'
WALLPAPER_SHA256=77cd9dc55b0fe199cab2810f89e6d058c2d6c44eaf0ef93bb5dd8bb74f42a157
if ! command -v rofi >/dev/null 2>&1; then
    echo "[ERROR] i3 requires Rofi for its configured launcher shortcut. Apply the launcher component first." >&2
    exit 1
fi
if ! "$REPO_ROOT/scripts/open-terminal.sh" --check >/dev/null 2>&1; then
    echo "[ERROR] i3 shortcuts require a usable terminal. Install Ghostty first or set TERMINAL." >&2
    exit 1
fi

echo "[*] Installing i3 and utilities..."
sudo apt update
sudo apt install -y i3 i3-wm i3status i3lock dmenu suckless-tools feh picom nitrogen polybar zenity fonts-font-awesome curl ca-certificates

echo "[*] Configuring i3 defaults..."
mkdir -p "$HOME/.config/i3"
mkdir -p "$HOME/.config/polybar"
mkdir -p "$HOME/Pictures"
mkdir -p "$HOME/.local/bin"

# Get Config Directory
CONFIG_DIR="$REPO_ROOT/configs"
OPEN_TERMINAL_SOURCE="$REPO_ROOT/scripts/open-terminal.sh"
OPEN_TERMINAL_DESTINATION="$HOME/.local/bin/open-terminal"

install_atomic() {
    local source="$1" destination="$2" mode="$3" temporary
    temporary="$(mktemp "$(dirname "$destination")/.install.XXXXXX")"
    install -m "$mode" "$source" "$temporary"
    mv "$temporary" "$destination"
}

if [[ ! -f "$OPEN_TERMINAL_SOURCE" ]]; then
    echo "[ERROR] Missing terminal helper: $OPEN_TERMINAL_SOURCE" >&2
    exit 1
fi

mkdir -p "$(dirname "$OPEN_TERMINAL_DESTINATION")"
install_atomic "$OPEN_TERMINAL_SOURCE" "$OPEN_TERMINAL_DESTINATION" 0755

# Download a nice default wallpaper
if [ ! -f "$HOME/Pictures/bg.jpg" ]; then
    echo "[*] Downloading default wallpaper..."
    download_verified_file "$WALLPAPER_URL" "$WALLPAPER_SHA256" "$HOME/Pictures/bg.jpg"
fi

# Install Help Script
install_atomic "$CONFIG_DIR/i3-help.sh" "$HOME/.local/bin/i3-help" 0755

# Install Polybar Configs
install_atomic "$CONFIG_DIR/polybar-launch.sh" "$HOME/.config/polybar/launch.sh" 0755
install_atomic "$CONFIG_DIR/polybar-config.ini" "$HOME/.config/polybar/config.ini" 0644

# Install i3 Config
# Only overwrite if it doesn't exist or force is requested (logic simplified for install script)
if [[ ! -f "$HOME/.config/i3/config" ]]; then
    install_atomic "$CONFIG_DIR/i3-config" "$HOME/.config/i3/config" 0644
    echo "[OK] Created default i3 config"
elif cmp -s "$CONFIG_DIR/i3-config" "$HOME/.config/i3/config"; then
    echo "[OK] i3 config is already current"
else
    echo "[INFO] i3 config already exists, backing up..."
    cp "$HOME/.config/i3/config" "$HOME/.config/i3/config.bak.$(date +%s)"
    install_atomic "$CONFIG_DIR/i3-config" "$HOME/.config/i3/config" 0644
    echo "[OK] Updated i3 config (old backed up)"
fi

echo "[OK] i3 Window Manager installed successfully!"
echo "   - Polybar (Top bar)"
echo "   - Nitrogen (Wallpaper)"
echo "   - Rofi integration (installed by the launcher component)"
echo "   - Help Shortcut (Win+Shift+?)"
echo ""
echo "[TIP] You must set the wallpaper once manually:"
echo "      Run: nitrogen --set-zoom-fill --save ~/Pictures/bg.jpg"
echo ""
