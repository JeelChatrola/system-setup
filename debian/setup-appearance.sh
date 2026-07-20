#!/bin/bash
# Install native themes and icons. Nix owns user fonts.
# Works for GNOME, i3, or any other WM

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/supply-chain.sh
source "$SCRIPT_DIR/../lib/supply-chain.sh"
# shellcheck source=../lib/gruvbox-theme.sh
source "$SCRIPT_DIR/../lib/gruvbox-theme.sh"

GRUVBOX_COMMIT=578cd220b5ff6e86b078a6111d26bb20ec8c733f
GRUVBOX_URL="https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme/archive/${GRUVBOX_COMMIT}.tar.gz"
GRUVBOX_SHA256=f45da23a6c4123148cf8f78983e391a86c2e2ee1b7a80aa66790f148cb9619bd
TEMP_DIR=""
THEME_BUILD_DEST=""

cleanup() {
    [[ -n "$TEMP_DIR" ]] && rm -rf "$TEMP_DIR"
    [[ -n "$THEME_BUILD_DEST" ]] && rm -rf "$THEME_BUILD_DEST"
}
trap cleanup EXIT

echo "[*] Setting up themes and icons..."

if ! command -v apt &> /dev/null; then
    echo "[ERROR] This script is for Debian-based systems only" >&2
    exit 1
fi

echo "[*] Installing appearance dependencies..."
sudo apt update
sudo apt install -y ca-certificates curl papirus-icon-theme sassc

# Create directories
mkdir -p "$HOME/.themes"
mkdir -p "$HOME/.icons"
# Install Gruvbox Theme
echo "[*] Installing Gruvbox GTK Theme..."
themes_home="$HOME/.themes"
stable_theme="$themes_home/Gruvbox-Dark"
refuse_unmanaged_gruvbox_stable "$themes_home"

theme_version=""
if [[ -L "$stable_theme" ]]; then
    stable_target="$(readlink -- "$stable_theme")"
    stable_bundle_name="${stable_target%/Gruvbox-Dark}"
    if [[ "$stable_bundle_name" == ".system-setup-gruvbox-$GRUVBOX_COMMIT".* ]] \
        && validate_gruvbox_bundle "$themes_home/$stable_bundle_name"; then
        theme_version="$themes_home/$stable_bundle_name"
    fi
fi
if [[ -z "$theme_version" ]]; then
    TEMP_DIR="$(mktemp -d)"
    download_verified_file "$GRUVBOX_URL" "$GRUVBOX_SHA256" "$TEMP_DIR/gruvbox.tar.gz"
    tar -xzf "$TEMP_DIR/gruvbox.tar.gz" -C "$TEMP_DIR"
    archive_root="$TEMP_DIR/Gruvbox-GTK-Theme-$GRUVBOX_COMMIT"
    validate_gruvbox_source_layout "$archive_root"
    THEME_BUILD_DEST="$(mktemp -d "$themes_home/.system-setup-gruvbox-$GRUVBOX_COMMIT.XXXXXX")"
    build_gruvbox_theme "$archive_root" "$THEME_BUILD_DEST"
    validate_gruvbox_bundle "$THEME_BUILD_DEST"
    write_gruvbox_ownership_marker "$THEME_BUILD_DEST"
    theme_version="$THEME_BUILD_DEST"
    THEME_BUILD_DEST=""
fi

publish_gruvbox_stable_link "$themes_home" "$theme_version"
echo "[OK] Gruvbox theme $GRUVBOX_COMMIT installed to ~/.themes"

# Papirus is installed by apt.
echo "[OK] Icons installed"

echo ""
echo "[OK] Appearance assets installed! Fonts remain owned by Nix."
echo "Themes: ~/.themes/"
echo "Icons:  /usr/share/icons/ (Papirus)"
echo ""
echo "[TIP] Use 'lxappearance' or 'gnome-tweaks' to select them."
