#!/bin/bash
# Install Rofi application launcher on Debian-based systems

set -e

echo "[*] Installing Rofi Launcher..."

# Check if running on Debian-based system
if ! command -v apt &> /dev/null; then
    echo "[ERROR] This script is for Debian-based systems only"
    exit 1
fi

# Check if Rofi is already installed
if command -v rofi &> /dev/null; then
    echo "[OK] Rofi is already installed"
    rofi -version
    exit 0
fi

# Install Rofi
echo "[*] Installing Rofi..."
sudo apt update
sudo apt install -y rofi

# Verify installation
if command -v rofi &> /dev/null; then
    echo "[OK] Rofi installed successfully!"
    rofi -version | head -1
    echo ""
    echo "Usage:"
    echo "  rofi -show drun -show-icons    # Application launcher"
    echo "  rofi -show run                 # Command runner"
    echo "  rofi -show window              # Window switcher"
    echo ""
    echo "Setup Ctrl+Space hotkey:"
    echo "  GNOME: Settings -> Keyboard -> Custom Shortcuts"
    echo "    Command: rofi -show drun -show-icons"
    echo "    Shortcut: Ctrl+Space"
else
    echo "[ERROR] Installation failed"
    exit 1
fi

# Create setup reminder script
REMINDER_SCRIPT="$HOME/.local/bin/setup-launcher-hotkey"
mkdir -p "$HOME/.local/bin"

cat > "$REMINDER_SCRIPT" << 'EOF'
#!/bin/bash
# Helper script to set up launcher hotkey

echo "[*] Setting up launcher hotkey (Ctrl+Space)..."
echo ""

# Detect desktop environment
if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ] || [ "$XDG_CURRENT_DESKTOP" = "ubuntu:GNOME" ]; then
    echo "[*] Detected GNOME desktop"
    echo ""
    echo "To set Ctrl+Space for your launcher:"
    echo "1. Open Settings → Keyboard → Keyboard Shortcuts → Custom Shortcuts"
    echo "2. Click '+' to add new shortcut"
    echo "3. Name: 'Launcher'"
    echo "4. Command: ulauncher-toggle (or 'albert toggle' or 'rofi -show drun')"
    echo "5. Set shortcut: Ctrl+Space"
    
elif [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
    echo "[*] Detected KDE desktop"
    echo ""
    echo "To set Ctrl+Space for your launcher:"
    echo "1. System Settings → Shortcuts → Custom Shortcuts"
    echo "2. Add new shortcut with your launcher command"
    echo "3. Set to Ctrl+Space"
    
else
    echo "[*] Desktop environment: $XDG_CURRENT_DESKTOP"
    echo ""
    echo "Add a custom keyboard shortcut for Ctrl+Space to launch your chosen launcher"
fi

echo ""
echo "[TIP] Note: You may need to disable existing Ctrl+Space shortcuts first"
EOF

chmod +x "$REMINDER_SCRIPT"

echo ""
echo "=========================================="
echo "[*] Next Steps:"
echo "=========================================="
echo ""
echo "1. $HOTKEY_HINT"
echo ""
echo "2. Run this helper anytime: setup-launcher-hotkey"
echo ""
echo "3. You may need to log out and log back in"
echo ""

