#!/bin/bash
# Setup custom keybindings for Debian-based systems

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/configs"
KEYBINDINGS_CONFIG="$CONFIG_DIR/keybindings.conf"

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

# Check if Alacritty is installed
TERMINAL_CMD="gnome-terminal"
if command -v alacritty &> /dev/null; then
    TERMINAL_CMD="alacritty"
    echo "[OK] Using Alacritty as terminal"
elif command -v kitty &> /dev/null; then
    TERMINAL_CMD="kitty"
    echo "[OK] Using Kitty as terminal"
else
    echo "[WARN]  Alacritty not found, using default terminal"
fi

# Copy keybindings config to user directory
USER_KEYBINDINGS_CONFIG="$HOME/.config/keybindings.conf"
if [ -f "$KEYBINDINGS_CONFIG" ]; then
    cp "$KEYBINDINGS_CONFIG" "$USER_KEYBINDINGS_CONFIG"
    echo "[*] Copied keybindings config to: $USER_KEYBINDINGS_CONFIG"
fi

setup_gnome_keybindings() {
    echo "[*] Setting up GNOME keybindings..."
    
    # Install dconf-cli if not present
    if ! command -v dconf &> /dev/null; then
        sudo apt install -y dconf-cli
    fi
    
    # Create custom keybinding for Ctrl+Alt+T
    echo "[*] Setting Ctrl+Alt+T to open $TERMINAL_CMD..."
    
    CUSTOM_KEYBINDINGS="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"
    
    # Get existing custom keybindings
    existing=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
    
    # Add new keybinding path
    new_path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
    
    if [[ $existing == "@as []" ]]; then
        gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$new_path']"
    elif [[ $existing != *"custom0"* ]]; then
        # Remove the trailing ] and add new path
        modified="${existing%]}, '$new_path']"
        gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$modified"
    fi
    
    # Set the keybinding properties
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$new_path name "Terminal"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$new_path command "$TERMINAL_CMD"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$new_path binding "<Primary><Alt>t"
    
    echo "[OK] Ctrl+Alt+T → $TERMINAL_CMD"
}

setup_kde_keybindings() {
    echo "[*] Setting up KDE keybindings..."
    echo ""
    echo "[*] For KDE Plasma:"
    echo "1. Open System Settings"
    echo "2. Go to Shortcuts → Custom Shortcuts"
    echo "3. Click 'Edit' → 'New' → 'Global Shortcut' → 'Command/URL'"
    echo "4. Set:"
    echo "   - Name: Terminal"
    echo "   - Trigger: Ctrl+Alt+T"
    echo "   - Action: $TERMINAL_CMD"
    echo ""
    read -p "Press Enter after setting up KDE shortcuts..."
}

setup_generic_keybindings() {
    echo "[*] Generic setup for other desktop environments..."
    echo ""
    echo "[*] To set up Ctrl+Alt+T for terminal:"
    echo "1. Open your desktop environment's keyboard settings"
    echo "2. Add a custom shortcut:"
    echo "   - Shortcut: Ctrl+Alt+T"
    echo "   - Command: $TERMINAL_CMD"
    echo ""
    
    # Create a simple script as fallback
    mkdir -p "$HOME/.local/bin"
    cat > "$HOME/.local/bin/open-terminal" << EOF
#!/bin/bash
$TERMINAL_CMD
EOF
    chmod +x "$HOME/.local/bin/open-terminal"
    
    echo "[OK] Created helper script: ~/.local/bin/open-terminal"
    echo "   Use this in your keyboard shortcut configuration"
}

# Setup based on desktop environment
case "$DE" in
    *"GNOME"*|*"ubuntu:GNOME"*|*"Unity"*)
        setup_gnome_keybindings
        ;;
    *"KDE"*|*"Plasma"*)
        setup_kde_keybindings
        ;;
    *"XFCE"*|*"LXDE"*|*"LXQt"*|*"MATE"*|*"Cinnamon"*)
        setup_generic_keybindings
        ;;
    *)
        echo "[WARN]  Unknown desktop environment: $DE"
        setup_generic_keybindings
        ;;
esac

echo ""
echo "[OK] Keybinding setup complete!"
echo ""
echo "[TIP] Tips:"
echo "   - Ctrl+Alt+T should now open $TERMINAL_CMD"
echo "   - You may need to log out and log back in for changes to take effect"
echo "   - If it doesn't work, check your DE's keyboard settings"
echo ""
echo "[*] Keybindings config: $USER_KEYBINDINGS_CONFIG"
echo "[TIP] Edit and customize your keybindings there, then re-run this script"

