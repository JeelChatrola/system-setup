#!/bin/bash
# Setup Ubuntu/GNOME appearance and customization on Debian-based systems

set -e

echo "🎨 Setting up appearance and customization..."

# Check if running on Debian-based system
if ! command -v apt &> /dev/null; then
    echo "❌ Error: This script is for Debian-based systems only"
    exit 1
fi

# Detect desktop environment
DE="${XDG_CURRENT_DESKTOP:-unknown}"
echo "📍 Detected desktop environment: $DE"

# Install GNOME Tweaks and Extensions (if GNOME)
if [[ "$DE" == *"GNOME"* ]]; then
    echo ""
    echo "📦 Installing GNOME customization tools..."
    sudo apt update
    sudo apt install -y \
        gnome-tweaks \
        gnome-shell-extensions \
        chrome-gnome-shell \
        dconf-editor
    
    echo "✅ Installed GNOME Tweaks and Extensions"
fi

# Install themes and icon packs
echo ""
read -p "Install popular themes and icon packs? [Y/n]: " install_themes
install_themes=${install_themes:-Y}

if [[ $install_themes =~ ^[Yy]$ ]]; then
    echo "📦 Installing themes and icon packs..."
    sudo apt install -y \
        arc-theme \
        papirus-icon-theme \
        numix-gtk-theme \
        numix-icon-theme
    
    echo "✅ Installed themes and icons"
fi

# Install fonts
echo ""
read -p "Install recommended fonts (Nerd Fonts, etc)? [Y/n]: " install_fonts
install_fonts=${install_fonts:-Y}

if [[ $install_fonts =~ ^[Yy]$ ]]; then
    echo "📦 Installing fonts..."
    sudo apt install -y \
        fonts-firacode \
        fonts-jetbrains-mono \
        fonts-noto-color-emoji
    
    # Install a Nerd Font (JetBrainsMono Nerd Font)
    FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"
    
    echo "⬇️  Downloading JetBrainsMono Nerd Font..."
    TEMP_DIR="$(mktemp -d)"
    cd "$TEMP_DIR"
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip
    unzip -q JetBrainsMono.zip -d JetBrainsMono
    cp JetBrainsMono/*.ttf "$FONT_DIR/"
    
    # Update font cache
    fc-cache -f -v > /dev/null 2>&1
    
    cd - > /dev/null
    rm -rf "$TEMP_DIR"
    
    echo "✅ Installed fonts"
fi

# Create appearance configuration script
APPEARANCE_CONFIG="$HOME/.config/appearance-settings.sh"
mkdir -p "$HOME/.config"

cat > "$APPEARANCE_CONFIG" << 'EOF'
#!/bin/bash
# Appearance settings - customize as needed

echo "🎨 Applying appearance settings..."

# Only apply GNOME settings if on GNOME
if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
    # Dark theme
    gsettings set org.gnome.desktop.interface gtk-theme 'Arc-Dark'
    gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    
    # Fonts
    gsettings set org.gnome.desktop.interface font-name 'Ubuntu 11'
    gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 10'
    
    # Window controls (show minimize/maximize)
    gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
    
    # Enable fractional scaling (for HiDPI displays)
    # gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"
    
    # Touchpad settings
    gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
    gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true
    
    # Workspaces
    gsettings set org.gnome.mutter dynamic-workspaces false
    gsettings set org.gnome.desktop.wm.preferences num-workspaces 4
    
    # Dock settings (if using Ubuntu Dock)
    if gsettings list-schemas | grep -q "org.gnome.shell.extensions.dash-to-dock"; then
        gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
        gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false
        gsettings set org.gnome.shell.extensions.dash-to-dock autohide true
        gsettings set org.gnome.shell.extensions.dash-to-dock intellihide true
    fi
    
    echo "✅ Applied GNOME appearance settings"
else
    echo "⚠️  Not on GNOME, skipping GNOME-specific settings"
fi

echo "✅ Appearance configuration complete!"
EOF

chmod +x "$APPEARANCE_CONFIG"

echo ""
echo "✅ Appearance setup complete!"
echo ""
echo "📍 What was installed:"
if [[ "$DE" == *"GNOME"* ]]; then
    echo "   - GNOME Tweaks (run: gnome-tweaks)"
    echo "   - GNOME Extensions"
fi
echo "   - Themes: Arc, Numix"
echo "   - Icons: Papirus, Numix"
echo "   - Fonts: FiraCode, JetBrains Mono, Nerd Fonts"
echo ""
echo "📍 Appearance config saved to: $APPEARANCE_CONFIG"
echo ""
echo "💡 To apply appearance settings now:"
echo "   bash $APPEARANCE_CONFIG"
echo ""
echo "💡 Customize your settings by editing:"
echo "   $APPEARANCE_CONFIG"
echo ""

