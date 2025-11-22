#!/bin/bash
# Install Nix package manager using Determinate Systems installer
# See: https://github.com/DeterminateSystems/nix-installer

set -e

echo "[*] Installing Nix Package Manager..."

# Check if Nix is already installed
if command -v nix &> /dev/null; then
    echo "[OK] Nix is already installed"
    nix --version
    echo ""
    echo "Nix profile: $HOME/.nix-profile"
    echo "Nix config: $HOME/.config/nix"
    exit 0
fi

# Check if running on Debian-based system
if ! command -v apt &> /dev/null; then
    echo "[ERROR] This script is for Debian-based systems only"
    exit 1
fi

# Install dependencies
echo "[*] Installing dependencies..."
sudo apt update
sudo apt install -y curl xz-utils

# Information about Determinate Systems installer
echo ""
echo "Using Determinate Systems Nix Installer"
echo "----------------------------------------"
echo "Benefits over official installer:"
echo "  - Faster and more reliable"
echo "  - Automatic flakes and nix-command support"
echo "  - Better error handling"
echo "  - Used by 7+ million installations"
echo ""
echo "See: https://github.com/DeterminateSystems/nix-installer"
echo ""

read -p "Continue with installation? [Y/n]: " confirm
confirm=${confirm:-Y}

if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "[*] Installation cancelled"
    exit 0
fi

# Install Nix using Determinate Systems installer
echo "[*] Downloading and installing Nix..."
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Source Nix for current session
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
    . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
elif [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi

# Verify flakes are enabled (Determinate installer enables by default)
echo ""
echo "[*] Verifying Nix configuration..."

mkdir -p "$HOME/.config/nix"

if [ ! -f "$HOME/.config/nix/nix.conf" ] || ! grep -q "experimental-features" "$HOME/.config/nix/nix.conf"; then
    echo "experimental-features = nix-command flakes" >> "$HOME/.config/nix/nix.conf"
    echo "[OK] Enabled experimental features"
else
    echo "[OK] Experimental features already enabled"
fi

# Configure Nix channels
echo ""
echo "[*] Setting up Nix channels..."
nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs
nix-channel --update

# Install home-manager (optional)
echo ""
read -p "Install home-manager for dotfile management? [Y/n]: " install_home_manager
install_home_manager=${install_home_manager:-Y}

if [[ $install_home_manager =~ ^[Yy]$ ]]; then
    echo "[*] Installing home-manager..."
    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
    nix-channel --update
    nix-shell '<home-manager>' -A install
    echo "[OK] home-manager installed"
    echo "[TIP] Configure at: ~/.config/home-manager/home.nix"
fi

# Verify installation
echo ""
if command -v nix &> /dev/null; then
    echo "[OK] Nix installed successfully!"
    echo ""
    nix --version
    echo ""
    echo "Installation details:"
    echo "  - Profile: $HOME/.nix-profile"
    echo "  - Config: $HOME/.config/nix"
    echo "  - Store: /nix/store"
    echo "  - Flakes: ENABLED (by default)"
    echo ""
    echo "Usage examples:"
    echo "  nix-env -iA nixpkgs.ripgrep        # Install a package"
    echo "  nix-env -q                         # List installed"
    echo "  nix search nixpkgs package         # Search packages"
    echo "  nix-shell -p nodejs python3        # Try without installing"
    echo ""
    echo "Reload your shell:"
    echo "  source ~/.bashrc  # or ~/.zshrc"
    echo ""
    echo "[TIP] Recommendation for GUI apps:"
    echo "  - GUI apps (Chrome, Cursor, Zen): Install manually"
    echo "  - CLI tools: Use Nix (perfect for this!)"
    echo "  - Dotfiles: Use home-manager (version controlled)"
    echo "  - System stuff: Use apt (Docker, NVIDIA)"
else
    echo "[ERROR] Installation failed"
    exit 1
fi
