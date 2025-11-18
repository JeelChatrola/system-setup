# ⚡ Quick Start Guide

## 🎯 Fresh Machine Setup (Recommended Path)

```bash
# 1. Clone repo
git clone <your-repo-url> ~/system-setup
cd ~/system-setup

# 2. Install everything
./install.sh all

# 3. Log out and log back in
# (Required for docker group, appearance changes, etc.)

# 4. Configure Nix for your dotfiles
# See POST-INSTALL-NIX.md for details
```

## 🚀 What You Get

After running `./install.sh all`:

### ✅ System Tools
- [x] Nix package manager (for user packages & dotfiles)
- [x] Docker + Docker Compose
- [x] Chrome browser
- [x] Cursor AI editor
- [x] Alacritty terminal
- [x] AppImage support

### ✅ macOS-like Features  
- [x] **Ctrl+Space** → App launcher (like Spotlight)
- [x] **Ctrl+Alt+T** → Open terminal
- [x] Dark theme with nice icons
- [x] Nerd Fonts for terminal

### ✅ Optional (prompted during install)
- [ ] NVIDIA Container Toolkit (if you have NVIDIA GPU)
- [ ] Launcher choice: Ulauncher / Albert / Rofi
- [ ] Themes and fonts customization

## 💡 Most Common Commands

```bash
# Install one thing
./install.sh docker          # Just Docker
./install.sh launcher        # Just app launcher
./install.sh appearance      # Just themes/fonts

# Helper tools (after install)
appimage-manager list        # List AppImages
setup-launcher-hotkey        # Setup Ctrl+Space
bash ~/.config/appearance-settings.sh  # Apply themes

# Nix/home-manager (after Nix install)
nix search nixpkgs ripgrep   # Search packages
home-manager switch          # Apply dotfile config
```

## 🎯 Recommended Next Steps

### 1. Setup home-manager for dotfiles
```bash
mkdir -p ~/.config/home-manager
# Copy example from POST-INSTALL-NIX.md
nano ~/.config/home-manager/home.nix
home-manager switch
```

### 2. Configure your launcher (Ctrl+Space)
```bash
# Start your launcher
ulauncher  # or albert, or rofi

# Set hotkey to Ctrl+Space in launcher preferences
# Run this helper for DE-specific instructions:
setup-launcher-hotkey
```

### 3. Customize appearance
```bash
# Edit appearance settings
nano ~/.config/appearance-settings.sh

# Apply changes
bash ~/.config/appearance-settings.sh

# Or use GUI
gnome-tweaks  # if on GNOME
```

## 🐛 Quick Fixes

### Docker permission denied
```bash
newgrp docker
# or log out/in
```

### Nix commands not found
```bash
source ~/.bashrc  # or ~/.zshrc
```

### Launcher not working
```bash
# Start launcher manually first
ulauncher &

# Then set Ctrl+Space in its preferences
```

### Ctrl+Alt+T not opening terminal
```bash
# Re-run keybinding setup
./debian/setup-keybindings.sh
```

## 📚 More Info

- **Full README**: [README.md](README.md)
- **Nix Setup Guide**: [POST-INSTALL-NIX.md](POST-INSTALL-NIX.md)
- **Individual Scripts**: `debian/*.sh`

## 🎨 Customization Examples

### Change terminal in Ctrl+Alt+T
Edit `~/.local/bin/open-terminal` or reconfigure in your DE settings

### Change launcher choice
```bash
./debian/install-launcher.sh
# Pick different option when prompted
```

### Add more Nix packages
```bash
nano ~/.config/home-manager/home.nix
# Add packages to home.packages list
home-manager switch
```

## 🌟 Philosophy Reminder

- **apt** (system package manager) → System-level stuff
  - Docker, NVIDIA, desktop integration
  
- **Nix** (user package manager) → User-level stuff
  - Development tools, CLI utilities, dotfiles

This way you get:
- ✅ Stability (from Debian/Ubuntu)
- ✅ Reproducibility (from Nix)
- ✅ Best of both worlds!

---

**Happy configuring! 🚀**

