#!/bin/bash
# Install Google Chrome on Debian-based systems

set -e

echo "📦 Installing Google Chrome..."

# Check if running on Debian-based system
if ! command -v apt &> /dev/null; then
    echo "❌ Error: This script is for Debian-based systems only"
    exit 1
fi

# Check if Chrome is already installed
if command -v google-chrome &> /dev/null; then
    echo "✅ Google Chrome is already installed"
    google-chrome --version
    exit 0
fi

# Download Google Chrome
TEMP_DEB="$(mktemp).deb"
echo "⬇️  Downloading Google Chrome..."
wget -O "$TEMP_DEB" 'https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb'

# Install Chrome
echo "🔧 Installing Google Chrome..."
sudo apt update
sudo apt install -y "$TEMP_DEB"

# Clean up
rm -f "$TEMP_DEB"

# Verify installation
if command -v google-chrome &> /dev/null; then
    echo "✅ Google Chrome installed successfully!"
    google-chrome --version
else
    echo "❌ Installation failed"
    exit 1
fi

