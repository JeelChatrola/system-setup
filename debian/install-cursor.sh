#!/bin/bash
# Install Cursor AI Code Editor on Debian-based systems

set -e

echo "📦 Installing Cursor..."

# Check if running on Debian-based system
if ! command -v apt &> /dev/null; then
    echo "❌ Error: This script is for Debian-based systems only"
    exit 1
fi

# Check if Cursor is already installed
if command -v cursor &> /dev/null; then
    echo "✅ Cursor is already installed"
    cursor --version
    exit 0
fi

# Create temporary directory
TEMP_DIR="$(mktemp -d)"
cd "$TEMP_DIR"

# Download Cursor AppImage
echo "⬇️  Downloading Cursor..."
CURSOR_URL="https://downloader.cursor.sh/linux/appImage/x64"
wget -O cursor.AppImage "$CURSOR_URL"

# Make it executable
chmod +x cursor.AppImage

# Create installation directory
INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"

# Move AppImage to installation directory
mv cursor.AppImage "$INSTALL_DIR/cursor"

# Create desktop entry
mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/cursor.desktop" << EOF
[Desktop Entry]
Name=Cursor
Exec=$INSTALL_DIR/cursor %U
Terminal=false
Type=Application
Icon=cursor
StartupWMClass=Cursor
Comment=AI-powered Code Editor
MimeType=text/plain;inode/directory;
Categories=Development;IDE;
EOF

echo "✅ Cursor installed successfully!"
echo "📍 Location: $INSTALL_DIR/cursor"
echo "💡 Run 'cursor' from terminal or find it in your applications menu"

# Clean up
cd - > /dev/null
rm -rf "$TEMP_DIR"

