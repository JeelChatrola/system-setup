#!/bin/bash
# Install application launcher (Mac Spotlight-like) on Debian-based systems

set -e

echo "📦 Installing Application Launcher..."

# Check if running on Debian-based system
if ! command -v apt &> /dev/null; then
    echo "❌ Error: This script is for Debian-based systems only"
    exit 1
fi

# Show launcher options
echo ""
echo "Choose your launcher (Mac Cmd+Space equivalent):"
echo ""
echo "1) Ulauncher (recommended) - Modern, extensible launcher"
echo "2) Albert - Fast, lightweight launcher"
echo "3) Rofi - Minimalist window switcher/launcher"
echo "4) Skip"
echo ""
read -p "Enter your choice [1-4] (default: 1): " choice
choice=${choice:-1}

install_ulauncher() {
    if command -v ulauncher &> /dev/null; then
        echo "✅ Ulauncher is already installed"
        return
    fi
    
    echo "📦 Installing Ulauncher..."
    sudo apt update
    sudo apt install -y ulauncher
    
    echo "✅ Ulauncher installed!"
    echo ""
    echo "📍 Setup steps:"
    echo "   1. Start Ulauncher from applications menu"
    echo "   2. Set hotkey to Ctrl+Space in Ulauncher preferences"
    echo "   3. Enable 'Launch at login' in preferences"
    echo ""
    echo "💡 Or run: ulauncher"
}

install_albert() {
    if command -v albert &> /dev/null; then
        echo "✅ Albert is already installed"
        return
    fi
    
    echo "📦 Installing Albert..."
    
    # Add Albert PPA
    sudo apt update
    sudo apt install -y software-properties-common
    
    # For Ubuntu/Debian, we'll build from source or use snap
    echo "📦 Installing via snap..."
    sudo apt install -y snapd
    sudo snap install albert
    
    echo "✅ Albert installed!"
    echo ""
    echo "📍 Setup steps:"
    echo "   1. Start Albert: albert"
    echo "   2. Set hotkey to Ctrl+Space in settings"
    echo "   3. Enable autostart"
}

install_rofi() {
    if command -v rofi &> /dev/null; then
        echo "✅ Rofi is already installed"
        return
    fi
    
    echo "📦 Installing Rofi..."
    sudo apt update
    sudo apt install -y rofi
    
    echo "✅ Rofi installed!"
    echo ""
    echo "📍 Setup:"
    echo "   Add to your window manager config or create a keyboard shortcut:"
    echo "   rofi -show drun -show-icons"
    echo ""
    echo "💡 For Ctrl+Space, add this to your DE keyboard shortcuts"
}

case $choice in
    1)
        install_ulauncher
        LAUNCHER="ulauncher"
        HOTKEY_HINT="Set Ctrl+Space in Ulauncher preferences"
        ;;
    2)
        install_albert
        LAUNCHER="albert"
        HOTKEY_HINT="Set Ctrl+Space in Albert settings"
        ;;
    3)
        install_rofi
        LAUNCHER="rofi"
        HOTKEY_HINT="Create custom keyboard shortcut for: rofi -show drun -show-icons"
        ;;
    4)
        echo "⏭️  Skipping launcher installation"
        exit 0
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

# Create setup reminder script
REMINDER_SCRIPT="$HOME/.local/bin/setup-launcher-hotkey"
mkdir -p "$HOME/.local/bin"

cat > "$REMINDER_SCRIPT" << 'EOF'
#!/bin/bash
# Helper script to set up launcher hotkey

echo "🔧 Setting up launcher hotkey (Ctrl+Space)..."
echo ""

# Detect desktop environment
if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ] || [ "$XDG_CURRENT_DESKTOP" = "ubuntu:GNOME" ]; then
    echo "📍 Detected GNOME desktop"
    echo ""
    echo "To set Ctrl+Space for your launcher:"
    echo "1. Open Settings → Keyboard → Keyboard Shortcuts → Custom Shortcuts"
    echo "2. Click '+' to add new shortcut"
    echo "3. Name: 'Launcher'"
    echo "4. Command: ulauncher-toggle (or 'albert toggle' or 'rofi -show drun')"
    echo "5. Set shortcut: Ctrl+Space"
    
elif [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
    echo "📍 Detected KDE desktop"
    echo ""
    echo "To set Ctrl+Space for your launcher:"
    echo "1. System Settings → Shortcuts → Custom Shortcuts"
    echo "2. Add new shortcut with your launcher command"
    echo "3. Set to Ctrl+Space"
    
else
    echo "📍 Desktop environment: $XDG_CURRENT_DESKTOP"
    echo ""
    echo "Add a custom keyboard shortcut for Ctrl+Space to launch your chosen launcher"
fi

echo ""
echo "💡 Note: You may need to disable existing Ctrl+Space shortcuts first"
EOF

chmod +x "$REMINDER_SCRIPT"

echo ""
echo "=========================================="
echo "🎯 Next Steps:"
echo "=========================================="
echo ""
echo "1. $HOTKEY_HINT"
echo ""
echo "2. Run this helper anytime: setup-launcher-hotkey"
echo ""
echo "3. You may need to log out and log back in"
echo ""

