#!/bin/bash
# Install Nix package manager on Debian-based systems

set -e

echo "📦 Installing Nix Package Manager..."

# Check if Nix is already installed
if command -v nix &> /dev/null; then
    echo "✅ Nix is already installed"
    nix --version
    echo ""
    echo "📍 Nix profile: $HOME/.nix-profile"
    echo "📍 Nix config: $HOME/.config/nix"
    exit 0
fi

# Check if running on Debian-based system
if ! command -v apt &> /dev/null; then
    echo "❌ Error: This script is for Debian-based systems only"
    exit 1
fi

# Install dependencies
echo "📦 Installing dependencies..."
sudo apt update
sudo apt install -y curl xz-utils

# Prompt for installation type
echo ""
echo "Choose Nix installation type:"
echo "1) Multi-user installation (recommended for most users)"
echo "2) Single-user installation (no daemon, simpler)"
echo ""
read -p "Enter your choice [1-2] (default: 1): " install_type
install_type=${install_type:-1}

case $install_type in
    1)
        echo "⬇️  Installing Nix (multi-user mode)..."
        sh <(curl -L https://nixos.org/nix/install) --daemon
        ;;
    2)
        echo "⬇️  Installing Nix (single-user mode)..."
        sh <(curl -L https://nixos.org/nix/install) --no-daemon
        ;;
    *)
        echo "❌ Invalid choice. Defaulting to multi-user installation..."
        sh <(curl -L https://nixos.org/nix/install) --daemon
        ;;
esac

# Source Nix for current session
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
    . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
elif [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi

# Enable flakes and nix-command (experimental features commonly used)
echo ""
read -p "Enable experimental features (flakes, nix-command)? [Y/n]: " enable_flakes
enable_flakes=${enable_flakes:-Y}

if [[ $enable_flakes =~ ^[Yy]$ ]]; then
    mkdir -p "$HOME/.config/nix"
    
    if [ ! -f "$HOME/.config/nix/nix.conf" ] || ! grep -q "experimental-features" "$HOME/.config/nix/nix.conf"; then
        echo "experimental-features = nix-command flakes" >> "$HOME/.config/nix/nix.conf"
        echo "✅ Enabled experimental features (flakes, nix-command)"
    else
        echo "ℹ️  Experimental features already configured"
    fi
fi

# Configure Nix channels
echo ""
echo "📡 Setting up Nix channels..."
nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs
nix-channel --update

# Install some useful tools via Nix (optional)
echo ""
read -p "Install home-manager for dotfile management? [Y/n]: " install_home_manager
install_home_manager=${install_home_manager:-Y}

if [[ $install_home_manager =~ ^[Yy]$ ]]; then
    echo "📦 Installing home-manager..."
    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
    nix-channel --update
    nix-shell '<home-manager>' -A install
    echo "✅ home-manager installed"
    echo "💡 Configure home-manager in: ~/.config/home-manager/home.nix"
fi

# Verify installation
echo ""
if command -v nix &> /dev/null; then
    echo "✅ Nix installed successfully!"
    echo ""
    nix --version
    echo ""
    echo "📍 Installation details:"
    echo "   - Profile: $HOME/.nix-profile"
    echo "   - Config: $HOME/.config/nix"
    echo "   - Store: /nix/store"
    echo ""
    echo "💡 Usage examples:"
    echo "   nix-env -iA nixpkgs.package-name  # Install a package"
    echo "   nix-env -q                         # List installed packages"
    echo "   nix-env -e package-name            # Uninstall a package"
    echo "   nix search nixpkgs package         # Search for packages"
    echo "   nix-shell -p package               # Try package without installing"
    echo ""
    echo "🔄 Reload your shell or run:"
    echo "   source ~/.bashrc (or ~/.zshrc)"
else
    echo "❌ Installation failed"
    exit 1
fi

