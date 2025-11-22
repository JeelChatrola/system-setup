#!/bin/bash
# Install Themes and Fonts (Universal)
# Installs to ~/.themes, ~/.icons, and ~/.local/share/fonts
# Works for GNOME, i3, or any other WM

set -e

echo "[*] Setting up universal appearance (themes & fonts)..."

# Create directories
mkdir -p "$HOME/.themes"
mkdir -p "$HOME/.icons"
mkdir -p "$HOME/.local/share/fonts"

# 1. Install Fonts (Nerd Fonts)
echo "[*] Installing JetBrainsMono Nerd Font..."
TEMP_DIR="$(mktemp -d)"
cd "$TEMP_DIR"
wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip
unzip -q JetBrainsMono.zip -d JetBrainsMono
cp JetBrainsMono/*.ttf "$HOME/.local/share/fonts/"
cd - > /dev/null
rm -rf "$TEMP_DIR"

# Update font cache
if command -v fc-cache &> /dev/null; then
    fc-cache -f -v > /dev/null 2>&1
    echo "[OK] Fonts installed"
fi

# 2. Install Gruvbox Theme
echo "[*] Installing Gruvbox GTK Theme..."
if [ -d "$HOME/.themes/Gruvbox-Dark-BL" ]; then
    echo "[OK] Gruvbox theme already installed"
else
    TEMP_DIR="$(mktemp -d)"
    cd "$TEMP_DIR"
    git clone --depth 1 https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme.git
    # Create directory if not exists (the repo structure might vary, so we find the theme dir)
    # Usually it's in themes/ inside the repo
    if [ -d "Gruvbox-GTK-Theme/themes" ]; then
        cp -r Gruvbox-GTK-Theme/themes/* "$HOME/.themes/"
        echo "[OK] Gruvbox theme installed to ~/.themes"
    else
        echo "[WARN] Could not find theme directory in cloned repo"
    fi
    cd - > /dev/null
    rm -rf "$TEMP_DIR"
fi

# 3. Install Icons (Papirus)
# We'll use apt for this as it's easiest on Debian/Ubuntu
if command -v apt &> /dev/null; then
    echo "[*] Installing Papirus Icons via apt..."
    sudo apt update
    sudo apt install -y papirus-icon-theme
    echo "[OK] Icons installed"
fi

echo ""
echo "[OK] Appearance assets installed!"
echo "Themes: ~/.themes/"
echo "Icons:  /usr/share/icons/ (Papirus)"
echo "Fonts:  ~/.local/share/fonts/"
echo ""
echo "[TIP] Use 'lxappearance' or 'gnome-tweaks' to select them."

