#!/bin/bash
# Setup AppImage tools and utilities on Debian-based systems

set -e

echo "📦 Setting up AppImage utilities..."

# Check if running on Debian-based system
if ! command -v apt &> /dev/null; then
    echo "❌ Error: This script is for Debian-based systems only"
    exit 1
fi

# Install FUSE (required for AppImages)
echo "📦 Installing FUSE..."
sudo apt update
sudo apt install -y fuse libfuse2

# Create AppImage directory
APPIMAGE_DIR="$HOME/.local/bin/appimages"
mkdir -p "$APPIMAGE_DIR"

# Add to PATH if not already there
if ! grep -q "$APPIMAGE_DIR" "$HOME/.bashrc" 2>/dev/null; then
    echo "" >> "$HOME/.bashrc"
    echo "# AppImage directory" >> "$HOME/.bashrc"
    echo "export PATH=\"\$PATH:$APPIMAGE_DIR\"" >> "$HOME/.bashrc"
fi

if [ -f "$HOME/.zshrc" ] && ! grep -q "$APPIMAGE_DIR" "$HOME/.zshrc"; then
    echo "" >> "$HOME/.zshrc"
    echo "# AppImage directory" >> "$HOME/.zshrc"
    echo "export PATH=\"\$PATH:$APPIMAGE_DIR\"" >> "$HOME/.zshrc"
fi

# Install appimagelauncher (optional but recommended)
echo "📦 Installing AppImageLauncher..."
if ! command -v appimagelauncher &> /dev/null; then
    TEMP_DIR="$(mktemp -d)"
    cd "$TEMP_DIR"
    
    # Get latest AppImageLauncher
    LAUNCHER_URL="https://github.com/TheAssassin/AppImageLauncher/releases/download/v2.2.0/appimagelauncher_2.2.0-travis995.0f91801.bionic_amd64.deb"
    wget -O appimagelauncher.deb "$LAUNCHER_URL"
    
    sudo apt install -y ./appimagelauncher.deb
    
    cd - > /dev/null
    rm -rf "$TEMP_DIR"
fi

# Create helper script for managing AppImages
HELPER_SCRIPT="$HOME/.local/bin/appimage-manager"
cat > "$HELPER_SCRIPT" << 'EOF'
#!/bin/bash
# AppImage Manager - Helper script for managing AppImages

APPIMAGE_DIR="$HOME/.local/bin/appimages"

show_help() {
    cat << HELP
AppImage Manager

Usage:
  appimage-manager install <url> <name>  Install an AppImage from URL
  appimage-manager list                   List installed AppImages
  appimage-manager remove <name>          Remove an AppImage
  appimage-manager update <name> <url>    Update an AppImage
  appimage-manager help                   Show this help message

Examples:
  appimage-manager install https://example.com/app.AppImage myapp
  appimage-manager list
  appimage-manager remove myapp

HELP
}

install_appimage() {
    local url="$1"
    local name="$2"
    
    if [ -z "$url" ] || [ -z "$name" ]; then
        echo "❌ Error: URL and name required"
        echo "Usage: appimage-manager install <url> <name>"
        exit 1
    fi
    
    echo "⬇️  Downloading $name..."
    wget -O "$APPIMAGE_DIR/$name" "$url"
    chmod +x "$APPIMAGE_DIR/$name"
    echo "✅ Installed: $name"
}

list_appimages() {
    echo "📦 Installed AppImages:"
    if [ -d "$APPIMAGE_DIR" ]; then
        ls -lh "$APPIMAGE_DIR" | tail -n +2
    else
        echo "None"
    fi
}

remove_appimage() {
    local name="$1"
    
    if [ -z "$name" ]; then
        echo "❌ Error: Name required"
        echo "Usage: appimage-manager remove <name>"
        exit 1
    fi
    
    if [ -f "$APPIMAGE_DIR/$name" ]; then
        rm "$APPIMAGE_DIR/$name"
        echo "✅ Removed: $name"
    else
        echo "❌ Not found: $name"
        exit 1
    fi
}

update_appimage() {
    local name="$1"
    local url="$2"
    
    if [ -z "$name" ] || [ -z "$url" ]; then
        echo "❌ Error: Name and URL required"
        echo "Usage: appimage-manager update <name> <url>"
        exit 1
    fi
    
    remove_appimage "$name"
    install_appimage "$url" "$name"
}

case "$1" in
    install)
        install_appimage "$2" "$3"
        ;;
    list)
        list_appimages
        ;;
    remove)
        remove_appimage "$2"
        ;;
    update)
        update_appimage "$2" "$3"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        show_help
        exit 1
        ;;
esac
EOF

chmod +x "$HELPER_SCRIPT"

echo "✅ AppImage setup complete!"
echo ""
echo "📍 AppImage directory: $APPIMAGE_DIR"
echo "🔧 Helper tool: appimage-manager"
echo ""
echo "Usage:"
echo "  appimage-manager install <url> <name>  # Install an AppImage"
echo "  appimage-manager list                   # List installed AppImages"
echo "  appimage-manager remove <name>          # Remove an AppImage"
echo ""
echo "💡 Reload your shell or run: source ~/.bashrc (or ~/.zshrc)"

