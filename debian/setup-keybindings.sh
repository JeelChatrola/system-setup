#!/bin/bash
# Setup custom keybindings for Debian-based systems

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OPEN_TERMINAL_SOURCE="$REPO_ROOT/scripts/open-terminal.sh"
OPEN_TERMINAL_DESTINATION="$HOME/.local/bin/open-terminal"

echo "[*] Setting up custom keybindings..."

# Check if running on Debian-based system
if ! command -v apt &> /dev/null; then
    echo "[ERROR] Error: This script is for Debian-based systems only"
    exit 1
fi

# Detect desktop environment
DE="${XDG_CURRENT_DESKTOP:-unknown}"

echo "[*] Detected desktop environment: $DE"
echo ""

if [[ ! -f "$OPEN_TERMINAL_SOURCE" ]]; then
    echo "[ERROR] Missing terminal helper: $OPEN_TERMINAL_SOURCE" >&2
    exit 1
fi

if ! "$OPEN_TERMINAL_SOURCE" --check >/dev/null 2>&1; then
    echo "[ERROR] Keybindings require a usable terminal. Install Ghostty first or set TERMINAL." >&2
    exit 1
fi

mkdir -p "$(dirname "$OPEN_TERMINAL_DESTINATION")"
terminal_tmp="$(mktemp "$(dirname "$OPEN_TERMINAL_DESTINATION")/.open-terminal.XXXXXX")"
install -m 0755 "$OPEN_TERMINAL_SOURCE" "$terminal_tmp"
mv "$terminal_tmp" "$OPEN_TERMINAL_DESTINATION"
TERMINAL_CMD="$OPEN_TERMINAL_DESTINATION"

echo "[OK] Installed open-terminal helper"

setup_gnome_keybinding() {
    local custom_keybindings
    local existing_paths
    local path
    local command
    local terminal_path=""
    local managed_path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom-terminal/"

    if ! command -v dconf &> /dev/null; then
        echo "[*] Installing dconf-cli..."
        sudo apt install -y dconf-cli
    fi

    if ! command -v gsettings &> /dev/null; then
        echo "[ERROR] gsettings is required to configure GNOME keybindings" >&2
        exit 1
    fi

    custom_keybindings="$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)"

    if [[ "$custom_keybindings" == *"$managed_path"* ]]; then
        terminal_path="$managed_path"
    elif [[ "$custom_keybindings" != "@as []" && "$custom_keybindings" != "[]" ]]; then
        existing_paths="$(printf '%s' "$custom_keybindings" | tr -d "[],'")"
        for path in $existing_paths; do
            command="$(gsettings get "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path" command)"
            command="${command#\'}"
            command="${command%\'}"
            if [[ "$command" == "$TERMINAL_CMD" ]]; then
                terminal_path="$path"
                break
            fi
        done
    fi

    if [[ -z "$terminal_path" ]]; then
        terminal_path="$managed_path"
        if [[ "$custom_keybindings" == "@as []" || "$custom_keybindings" == "[]" ]]; then
            gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$terminal_path']"
        else
            gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "${custom_keybindings%]}, '$terminal_path']"
        fi
    fi

    gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$terminal_path" name "Terminal"
    gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$terminal_path" command "$TERMINAL_CMD"
    gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$terminal_path" binding "<Primary><Alt>t"
    echo "[OK] Configured GNOME Ctrl+Alt+T → $TERMINAL_CMD"
}

USE_GNOME_KEYBINDINGS=false
if [[ "${DE,,}" == *"gnome"* ]] || {
    [[ "${DE,,}" == *"unity"* ]] \
        && command -v gsettings &> /dev/null \
        && gsettings list-schemas | grep -Fxq org.gnome.settings-daemon.plugins.media-keys
}; then
    USE_GNOME_KEYBINDINGS=true
fi

if $USE_GNOME_KEYBINDINGS; then
    setup_gnome_keybinding
else
    echo "[*] Configure Ctrl+Alt+T in $DE to run: $TERMINAL_CMD"
fi

echo ""
echo "[OK] Keybinding setup complete!"
echo ""
if ! $USE_GNOME_KEYBINDINGS; then
    echo "[TIP] Add Ctrl+Alt+T through your desktop environment's keyboard settings."
fi
