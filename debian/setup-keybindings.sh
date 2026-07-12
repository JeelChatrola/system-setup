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

mkdir -p "$(dirname "$OPEN_TERMINAL_DESTINATION")"
install -m 0755 "$OPEN_TERMINAL_SOURCE" "$OPEN_TERMINAL_DESTINATION"
TERMINAL_CMD="$OPEN_TERMINAL_DESTINATION"

echo "[OK] Installed open-terminal helper (ghostty > alacritty > gnome-terminal)"
echo "[*] Configure Ctrl+Alt+T in $DE to run: $TERMINAL_CMD"

echo ""
echo "[OK] Keybinding setup complete!"
echo ""
echo "[TIP] Add Ctrl+Alt+T through your desktop environment's keyboard settings."
