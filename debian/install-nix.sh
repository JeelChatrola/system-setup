#!/bin/bash
# Install Nix package manager using Determinate Systems installer
# See: https://github.com/DeterminateSystems/nix-installer

set -euo pipefail

INSTALLER_VERSION="3.21.5"
ARCH="$(uname -m)"
TEMP_DIR=""

cleanup() {
    [[ -n "$TEMP_DIR" ]] && rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

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

case "$ARCH" in
    x86_64|amd64)
        INSTALLER_ARCH="x86_64"
        INSTALLER_SHA256="ee9c560d6f093baf7a8b342d8a00e9f8b47dd4a6367f3f523482ee96897c4179"
        ;;
    aarch64|arm64)
        INSTALLER_ARCH="aarch64"
        INSTALLER_SHA256="9f56a034a7b0fe1bb83117a0326e1b38cc30dc14cdc311abb0637db332e1826f"
        ;;
    *)
        echo "[ERROR] Unsupported architecture: $ARCH" >&2
        exit 1
        ;;
esac

INSTALLER_URL="https://github.com/DeterminateSystems/nix-installer/releases/download/v${INSTALLER_VERSION}/nix-installer-${INSTALLER_ARCH}-linux"

# Check if running on Debian-based system
if ! command -v apt &> /dev/null; then
    echo "[ERROR] This script is for Debian-based systems only"
    exit 1
fi

# Install dependencies
echo "[*] Installing dependencies..."
sudo apt update
sudo apt install -y ca-certificates curl xz-utils

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

# Download, verify, and run the pinned Determinate Systems installer.
echo "[*] Downloading Determinate Systems Nix Installer v${INSTALLER_VERSION}..."
TEMP_DIR="$(mktemp -d)"
INSTALLER_PATH="$TEMP_DIR/nix-installer"
curl --proto '=https' --tlsv1.2 --fail --location --silent --show-error \
    --output "$INSTALLER_PATH" "$INSTALLER_URL"
echo "$INSTALLER_SHA256  $INSTALLER_PATH" | sha256sum --check --status
chmod 0755 "$INSTALLER_PATH"
"$INSTALLER_PATH" install --no-confirm

# Source Nix for current session
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
    . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
elif [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
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
