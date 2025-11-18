#!/bin/bash
# Install Alacritty terminal emulator on Debian-based systems

set -e

echo "📦 Installing Alacritty..."

# Check if running on Debian-based system
if ! command -v apt &> /dev/null; then
    echo "❌ Error: This script is for Debian-based systems only"
    exit 1
fi

# Check if Alacritty is already installed
if command -v alacritty &> /dev/null; then
    echo "✅ Alacritty is already installed"
    alacritty --version
    exit 0
fi

# Install dependencies
echo "📦 Installing dependencies..."
sudo apt update
sudo apt install -y cmake pkg-config libfreetype6-dev libfontconfig1-dev \
    libxcb-xfixes0-dev libxkbcommon-dev python3 gzip scdoc

# Check if Rust is installed
if ! command -v cargo &> /dev/null; then
    echo "📦 Rust not found. Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

# Clone and build Alacritty
echo "🔨 Building Alacritty from source..."
TEMP_DIR="$(mktemp -d)"
cd "$TEMP_DIR"

git clone https://github.com/alacritty/alacritty.git
cd alacritty

# Build in release mode
cargo build --release

# Install binary
sudo cp target/release/alacritty /usr/local/bin
sudo chmod +x /usr/local/bin/alacritty

# Install desktop entry
sudo cp extra/logo/alacritty-term.svg /usr/share/pixmaps/Alacritty.svg
sudo desktop-file-install extra/linux/Alacritty.desktop
sudo update-desktop-database

# Install man pages
sudo mkdir -p /usr/local/share/man/man1
sudo mkdir -p /usr/local/share/man/man5
scdoc < extra/man/alacritty.1.scd | gzip -c | sudo tee /usr/local/share/man/man1/alacritty.1.gz > /dev/null
scdoc < extra/man/alacritty-msg.1.scd | gzip -c | sudo tee /usr/local/share/man/man1/alacritty-msg.1.gz > /dev/null
scdoc < extra/man/alacritty.5.scd | gzip -c | sudo tee /usr/local/share/man/man5/alacritty.5.gz > /dev/null
scdoc < extra/man/alacritty-bindings.5.scd | gzip -c | sudo tee /usr/local/share/man/man5/alacritty-bindings.5.gz > /dev/null

# Install shell completions (bash)
mkdir -p "$HOME/.bash_completion"
cp extra/completions/alacritty.bash "$HOME/.bash_completion/alacritty"

# Install shell completions (zsh)
if [ -d "$HOME/.oh-my-zsh" ]; then
    sudo cp extra/completions/_alacritty /usr/share/zsh/site-functions/_alacritty
fi

# Clean up
cd - > /dev/null
rm -rf "$TEMP_DIR"

# Verify installation
if command -v alacritty &> /dev/null; then
    echo "✅ Alacritty installed successfully!"
    alacritty --version
else
    echo "❌ Installation failed"
    exit 1
fi

