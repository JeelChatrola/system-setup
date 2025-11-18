# system-setup

Automated installation of Personal Setup (Dev Tools, Browsers, GUI Apps, System Configuration, etc.)

> **Philosophy**: System-level tools via `apt`, user-level packages via `Nix` → Best of both worlds! 🎯

## 🚀 Quick Start

```bash
# Clone the repository
git clone <your-repo-url> ~/system-setup
cd ~/system-setup

# Run the interactive installer
./install.sh

# Or install specific tools
./install.sh nix         # Install Nix Package Manager
./install.sh docker      # Install Docker
./install.sh chrome      # Install Google Chrome
./install.sh all         # Install everything!
```

## 📦 What Gets Installed

### 📦 Core System (via apt)
- **Nix** - Package manager for reproducible builds and dotfile management
- **Docker** - Container platform with Docker Compose
- **NVIDIA Container Toolkit** - GPU support for Docker containers

### 🌐 Browsers & Editors (via apt)
- **Google Chrome** - Fast and secure web browser
- **Cursor** - AI-powered code editor built on VSCode

### 💻 Terminal & Tools (via apt)
- **Alacritty** - GPU-accelerated terminal emulator
- **AppImage Tools** - Manage and run AppImage applications

### ⚙️ Customization & Configuration (via apt)
- **Application Launcher** - Mac Spotlight-like launcher (Ulauncher/Albert/Rofi)
  - Ctrl+Space to launch apps (just like macOS!)
- **Keybindings** - Ctrl+Alt+T for terminal, custom shortcuts
- **Appearance** - Themes, icon packs, fonts (including Nerd Fonts)

## 🐧 Supported Operating Systems

Currently supported:
- ✅ Debian
- ✅ Ubuntu

*More distributions will be added based on need*

## 🎯 Installation Philosophy

### Why apt for system stuff?

System-level tools that need deep OS integration should use the system package manager:
- ✅ **Docker** (needs kernel modules, systemd services)
- ✅ **NVIDIA toolkit** (kernel drivers, hardware access)
- ✅ **Desktop integration** (launchers, keybindings, themes)
- ✅ **Terminal emulators** (desktop entries, proper integration)

### Why Nix for user stuff?

Nix is perfect for user-level packages and dotfiles:
- ✅ **Development tools** (nodejs, python, rust, go)
- ✅ **CLI utilities** (ripgrep, fd, bat, eza)
- ✅ **Reproducible environments** (per-project dependencies)
- ✅ **Dotfile management** (via home-manager)
- ✅ **No sudo needed** (user-space only)
- ✅ **Version control everything** (your entire config!)

See [POST-INSTALL-NIX.md](POST-INSTALL-NIX.md) for detailed Nix setup guide.

## 📋 Installation Options

### Interactive Mode (Recommended)
```bash
./install.sh
```

You'll get a menu with all options:
```
==================== INSTALLATION MENU ====================

📦 Core System:
  1)  Nix Package Manager (for dotfiles & user packages)
  2)  Docker + Docker Compose
  3)  NVIDIA Container Toolkit (requires Docker)

🌐 Browsers & Editors:
  4)  Google Chrome
  5)  Cursor (AI Code Editor)

💻 Terminal & Tools:
  6)  Alacritty (Terminal Emulator)
  7)  AppImage Tools

⚙️  Customization:
  8)  Application Launcher (Ctrl+Space, like Mac Spotlight)
  9)  Setup Keybindings (Ctrl+Alt+T for terminal)
  10) Setup Appearance (themes, fonts, tweaks)

🚀 Quick Install:
  11) Install System Essentials (1-7)
  12) Install Everything (1-10)

  0)  Exit
```

### Command-Line Mode
```bash
# Individual installations
./install.sh nix             # Nix Package Manager
./install.sh docker          # Docker + Docker Compose
./install.sh nvidia          # NVIDIA Container Toolkit
./install.sh chrome          # Google Chrome
./install.sh cursor          # Cursor AI Editor
./install.sh alacritty       # Alacritty Terminal
./install.sh appimage        # AppImage Tools
./install.sh launcher        # Application Launcher
./install.sh keybindings     # Custom Keybindings
./install.sh appearance      # Themes & Appearance

# Bulk installations
./install.sh essentials      # Core system tools (1-7)
./install.sh all             # Everything!
```

## 📁 Directory Structure

```
system-setup/
├── install.sh                          # Main installer (interactive + CLI)
├── POST-INSTALL-NIX.md                # Nix setup guide with home-manager examples
├── README.md                           # This file
└── debian/                             # Debian/Ubuntu-specific scripts
    ├── install-nix.sh                 # Nix package manager
    ├── install-docker.sh              # Docker + Docker Compose
    ├── install-nvidia-toolkit.sh      # NVIDIA Container Toolkit
    ├── install-chrome.sh              # Google Chrome
    ├── install-cursor.sh              # Cursor AI Editor
    ├── install-alacritty.sh           # Alacritty Terminal
    ├── setup-appimage.sh              # AppImage management
    ├── install-launcher.sh            # Application launcher (Ulauncher/Albert/Rofi)
    ├── setup-keybindings.sh           # Custom keyboard shortcuts
    └── setup-appearance.sh            # Themes, icons, fonts
```

## 🔍 What Each Script Does

### Nix (`install-nix.sh`)
- Installs Nix package manager (multi-user or single-user)
- Optionally enables experimental features (flakes, nix-command)
- Optionally installs home-manager for dotfile management
- Configures Nix channels (nixpkgs-unstable)
- **Recommended**: Install this first! See [POST-INSTALL-NIX.md](POST-INSTALL-NIX.md)

### Docker (`install-docker.sh`)
- Installs Docker Engine and Docker Compose
- Adds user to docker group (no sudo for docker commands)
- Enables Docker service on boot
- **Note**: Needs system package manager (kernel modules, systemd)

### NVIDIA Toolkit (`install-nvidia-toolkit.sh`)
- Installs NVIDIA Container Toolkit for Docker
- Enables GPU support in containers
- Configures Docker runtime for NVIDIA
- **Requires**: Docker must be installed first

### Chrome (`install-chrome.sh`)
- Downloads latest stable Google Chrome .deb
- Installs Chrome and dependencies
- Verifies installation

### Cursor (`install-cursor.sh`)
- Downloads Cursor AppImage
- Installs to ~/.local/bin/
- Creates desktop entry for application menu
- **Note**: AI-powered editor, great for coding

### Alacritty (`install-alacritty.sh`)
- Installs build dependencies
- Installs Rust (if needed)
- Builds Alacritty from source
- Installs binary, man pages, shell completions
- Creates desktop entry

### AppImage Tools (`setup-appimage.sh`)
- Installs FUSE (required for AppImages)
- Creates AppImage directory structure
- Installs AppImageLauncher
- Provides `appimage-manager` CLI tool
- Updates PATH in shell config

### Launcher (`install-launcher.sh`) 🎯
- Installs application launcher (Ulauncher/Albert/Rofi)
- **Mac Spotlight equivalent for Linux!**
- Configure with **Ctrl+Space** hotkey
- Provides setup helper: `setup-launcher-hotkey`

### Keybindings (`setup-keybindings.sh`)
- Sets up **Ctrl+Alt+T** to open terminal (Alacritty if installed)
- Auto-detects desktop environment (GNOME/KDE/etc.)
- Creates custom keyboard shortcuts
- Works with GNOME, KDE, XFCE, and others

### Appearance (`setup-appearance.sh`)
- Installs GNOME Tweaks and Extensions
- Installs popular themes (Arc, Numix)
- Installs icon packs (Papirus, Numix)
- Installs fonts (FiraCode, JetBrains Mono, Nerd Fonts)
- Creates appearance config script at `~/.config/appearance-settings.sh`

## 🚀 Complete New Machine Setup

Here's the recommended flow for a brand new machine:

```bash
# 1. Clone this repo
git clone <your-repo> ~/system-setup
cd ~/system-setup

# 2. Install system essentials (includes Nix)
./install.sh essentials

# 3. (Optional) Install NVIDIA toolkit if you have NVIDIA GPU
./install.sh nvidia

# 4. Setup customization
./install.sh launcher        # Ctrl+Space app launcher
./install.sh keybindings     # Ctrl+Alt+T terminal
./install.sh appearance      # Themes and fonts

# 5. Log out and log back in (for docker group, appearance, etc.)

# 6. Set up Nix and home-manager for your dotfiles
# See POST-INSTALL-NIX.md for detailed guide
git clone <your-dotfiles-repo> ~/.config/home-manager
home-manager switch

# 7. Done! 🎉
```

## 🛠️ Helper Tools

After installation, you'll have access to these helper commands:

```bash
# AppImage management
appimage-manager install <url> <name>  # Install AppImage
appimage-manager list                   # List installed
appimage-manager remove <name>          # Remove AppImage

# Launcher setup helper
setup-launcher-hotkey                   # Guide for Ctrl+Space setup

# Appearance configuration
bash ~/.config/appearance-settings.sh   # Apply appearance settings
```

## 🎨 Customization

### Mac-like Experience on Linux

Want that smooth macOS feel? Here's what gets configured:

✅ **Ctrl+Space** - Application launcher (like Spotlight)  
✅ **Ctrl+Alt+T** - Terminal (customizable to Alacritty)  
✅ **Dark theme** - Arc-Dark with Papirus icons  
✅ **Nerd Fonts** - Icon-rich terminal fonts  
✅ **Smooth UI** - GNOME Tweaks with optimized settings  

### Keybindings

| Shortcut | Action | Status |
|----------|--------|--------|
| Ctrl+Space | App Launcher | ✅ Configured by launcher script |
| Ctrl+Alt+T | Terminal | ✅ Configured by keybindings script |
| Super | Activities | ✅ Default GNOME |

### Appearance Settings

Edit `~/.config/appearance-settings.sh` to customize:
- GTK theme
- Icon theme
- Fonts
- Window controls
- Touchpad behavior
- Workspace settings
- Dock position

## ⚙️ Requirements

- Debian or Ubuntu-based system
- `sudo` access for system-wide installations
- Internet connection for downloading packages
- (Optional) NVIDIA GPU for NVIDIA Container Toolkit

## 🎯 Using Nix for Dotfiles

After installing Nix, you can manage your dotfiles and user packages:

```bash
# Install packages
nix-env -iA nixpkgs.neovim nixpkgs.ripgrep

# Or use home-manager (recommended)
home-manager switch
```

**See [POST-INSTALL-NIX.md](POST-INSTALL-NIX.md)** for:
- Complete home-manager setup
- Example configurations
- Package recommendations
- Dotfile management strategies
- Nix flakes guide

## 🐛 Troubleshooting

### Nix installation issues
- Make sure you have curl and xz-utils: `sudo apt install curl xz-utils`
- For multi-user installation, script needs sudo access
- After installation, reload shell: `source ~/.bashrc` or `source ~/.zshrc`
- If nix commands aren't found, check if profile is sourced

### Docker group issues
- After Docker installation, log out and log back in
- Or run: `newgrp docker`
- Test with: `docker run hello-world`

### NVIDIA Toolkit not working
- Ensure NVIDIA drivers are installed: `nvidia-smi`
- Check Docker is installed first
- Test with: `docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi`

### Ctrl+Space not working
- Disable existing Ctrl+Space shortcuts in your DE
- Run: `setup-launcher-hotkey` for DE-specific instructions
- May need to log out/in after launcher installation

### Ctrl+Alt+T not working
- Check your desktop environment's keyboard settings
- GNOME users: Settings → Keyboard → Custom Shortcuts
- May conflict with existing shortcuts

### Alacritty build fails
- Install all dependencies: Script handles this automatically
- Ensure Rust is installed: `rustc --version`
- Check disk space (~1GB needed for build)

### Appearance changes not applied
- Log out and log back in
- For GNOME: Run `gnome-tweaks` to verify settings
- Manually apply: `bash ~/.config/appearance-settings.sh`

## 🤝 Contributing

Feel free to add support for:
- More operating systems (Fedora, Arch, openSUSE)
- More applications and tools
- Configuration improvements
- Window managers (i3, Sway, etc.)

## 📝 Notes

- All scripts check if software is already installed
- Colored output for better readability
- Error handling in all scripts
- Both interactive and CLI modes
- System-level via apt, user-level via Nix

## 🌟 Inspiration

Inspired by the clean aesthetics and smooth workflow of Arch Linux setups (like Omarchy), but designed for Debian/Ubuntu stability. You get:

- The beautiful, customizable UI of Arch
- The stability and simplicity of Debian/Ubuntu
- The reproducibility of Nix
- The best of all worlds! 🚀

## 📜 License

Personal use repository

---

**Made with ❤️ for automated, reproducible system setups**
