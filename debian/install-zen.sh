#!/bin/bash
# Install Zen Browser on Debian-based systems
# Zen is a beautiful, privacy-focused Firefox-based browser

set -e

echo "📦 Installing Zen Browser..."

# Check if running on Debian-based system
if ! command -v apt &> /dev/null; then
    echo "❌ Error: This script is for Debian-based systems only"
    exit 1
fi

# Check if Zen is already installed
if command -v zen-browser &> /dev/null || [ -f "$HOME/.local/bin/zen-browser" ]; then
    echo "✅ Zen Browser is already installed"
    if command -v zen-browser &> /dev/null; then
        zen-browser --version 2>/dev/null || echo "Zen Browser installed"
    fi
    exit 0
fi

# Create installation directory
INSTALL_DIR="$HOME/.local/bin"
ZEN_DIR="$HOME/.local/share/zen-browser"
mkdir -p "$INSTALL_DIR"
mkdir -p "$ZEN_DIR"

# Detect architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        ZEN_ARCH="x86_64"
        ;;
    aarch64)
        ZEN_ARCH="aarch64"
        ;;
    *)
        echo "❌ Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Download Zen Browser
echo "⬇️  Downloading Zen Browser..."
TEMP_DIR="$(mktemp -d)"
cd "$TEMP_DIR"

# Get latest release URL (using generic download link)
ZEN_URL="https://github.com/zen-browser/desktop/releases/latest/download/zen.linux-specific.tar.bz2"

wget -O zen.tar.bz2 "$ZEN_URL" || {
    echo "⚠️  Direct download failed, trying alternative method..."
    # Fallback to a specific version if latest fails
    ZEN_URL="https://github.com/zen-browser/desktop/releases/download/1.0.0-a.17/zen.linux-specific.tar.bz2"
    wget -O zen.tar.bz2 "$ZEN_URL"
}

# Extract
echo "📦 Extracting Zen Browser..."
tar -xjf zen.tar.bz2 -C "$ZEN_DIR" --strip-components=1

# Create launcher script
cat > "$INSTALL_DIR/zen-browser" << EOF
#!/bin/bash
"$ZEN_DIR/zen" "\$@"
EOF

chmod +x "$INSTALL_DIR/zen-browser"

# Create desktop entry
mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/zen-browser.desktop" << EOF
[Desktop Entry]
Name=Zen Browser
Comment=Privacy-focused web browser based on Firefox
Exec=$INSTALL_DIR/zen-browser %u
Terminal=false
Type=Application
Icon=$ZEN_DIR/browser/chrome/icons/default/default128.png
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;x-scheme-handler/chrome;video/webm;application/x-xpinstall;
StartupNotify=true
Actions=NewWindow;NewPrivateWindow;

[Desktop Action NewWindow]
Name=Open a New Window
Exec=$INSTALL_DIR/zen-browser --new-window

[Desktop Action NewPrivateWindow]
Name=Open a New Private Window
Exec=$INSTALL_DIR/zen-browser --private-window
EOF

# Update desktop database
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
fi

# Clean up
cd - > /dev/null
rm -rf "$TEMP_DIR"

# Verify installation
if [ -f "$INSTALL_DIR/zen-browser" ]; then
    echo "✅ Zen Browser installed successfully!"
    echo ""
    echo "📍 Location: $ZEN_DIR"
    echo "🚀 Command: zen-browser"
    echo ""
    echo "💡 Features:"
    echo "   - Beautiful, modern UI"
    echo "   - Privacy-focused (based on Firefox)"
    echo "   - Vertical tabs"
    echo "   - Split view"
    echo "   - Custom themes"
    echo ""
    echo "🎨 Find it in your applications menu or run: zen-browser"
else
    echo "❌ Installation failed"
    exit 1
fi

