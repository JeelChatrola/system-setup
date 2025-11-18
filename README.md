# system-setup

Repo to automate installation of Personal Setup (Dev Tools, Browsers, GUI Apps, etc)

## 🚀 Quick Start

```bash
# Clone the repository
git clone <your-repo-url> system-setup
cd system-setup

# Run the interactive installer
./install.sh

# Or install specific tools
./install.sh nix         # Install Nix Package Manager
./install.sh chrome      # Install Google Chrome
./install.sh cursor      # Install Cursor AI Editor
./install.sh alacritty   # Install Alacritty Terminal
./install.sh appimage    # Setup AppImage tools
./install.sh all         # Install everything
```

## 📦 Supported Applications

### Package Managers
- **Nix** - Powerful package manager for reproducible builds and dotfile management
  - Optional: home-manager for declarative dotfile configuration
  - Supports flakes and experimental features

### Browsers
- **Google Chrome** - Fast and secure web browser

### Development Tools
- **Cursor** - AI-powered code editor built on VSCode
- **Alacritty** - GPU-accelerated terminal emulator

### Utilities
- **AppImage Tools** - Manage and run AppImage applications

## 🐧 Supported Operating Systems

Currently supported:
- ✅ Debian
- ✅ Ubuntu

*More distributions will be added based on need*

## 📋 Individual Installation Scripts

All scripts are located in the `debian/` directory for Debian-based systems:

```bash
# Nix Package Manager
./debian/install-nix.sh

# Google Chrome
./debian/install-chrome.sh

# Cursor AI Editor
./debian/install-cursor.sh

# Alacritty Terminal
./debian/install-alacritty.sh

# AppImage Tools Setup
./debian/setup-appimage.sh
```

## 🛠️ AppImage Manager

After running the AppImage setup, you'll have access to a helper tool:

```bash
# Install an AppImage
appimage-manager install <url> <name>

# List installed AppImages
appimage-manager list

# Remove an AppImage
appimage-manager remove <name>

# Update an AppImage
appimage-manager update <name> <url>
```

## 📁 Directory Structure

```
system-setup/
├── install.sh                    # Main installer with interactive menu
├── debian/                       # Debian/Ubuntu-specific scripts
│   ├── install-nix.sh           # Nix package manager installer
│   ├── install-chrome.sh        # Google Chrome installer
│   ├── install-cursor.sh        # Cursor editor installer
│   ├── install-alacritty.sh     # Alacritty terminal installer
│   └── setup-appimage.sh        # AppImage tools setup
└── README.md                     # This file
```

## 🔍 What Each Script Does

### Nix (`install-nix.sh`)
- Installs Nix package manager (multi-user or single-user mode)
- Optionally enables experimental features (flakes, nix-command)
- Optionally installs home-manager for dotfile management
- Configures Nix channels (nixpkgs-unstable)
- Provides usage examples and documentation

### Chrome (`install-chrome.sh`)
- Downloads the latest stable Google Chrome .deb package
- Installs Chrome and its dependencies
- Verifies the installation

### Cursor (`install-cursor.sh`)
- Downloads the Cursor AppImage
- Installs it to `~/.local/bin/`
- Creates a desktop entry for easy access
- Adds Cursor to your application menu

### Alacritty (`install-alacritty.sh`)
- Installs build dependencies
- Installs Rust (if not already installed)
- Builds Alacritty from source
- Installs binary, man pages, and shell completions
- Creates desktop entry

### AppImage Tools (`setup-appimage.sh`)
- Installs FUSE (required for AppImages)
- Creates AppImage directory structure
- Installs AppImageLauncher
- Provides `appimage-manager` helper script
- Updates PATH in your shell config

## ⚙️ Requirements

- Debian or Ubuntu-based system
- `sudo` access for system-wide installations
- Internet connection for downloading packages

## 🤝 Contributing

Feel free to add support for more:
- Operating systems (Fedora, Arch, etc.)
- Applications and tools
- Configuration files

## 📝 Notes

- All scripts check if the application is already installed
- Scripts use colored output for better readability
- Error handling is included in all scripts
- The main installer supports both interactive and command-line modes

## 🎯 Using Nix for Dotfiles

After installing Nix, you can use it for managing your dotfiles:

### Option 1: home-manager (Recommended)
```bash
# The script can install home-manager automatically
# Then configure it at: ~/.config/home-manager/home.nix

# Example home.nix:
# { config, pkgs, ... }: {
#   home.packages = with pkgs; [ neovim git htop ];
#   programs.git = {
#     enable = true;
#     userName = "Your Name";
#     userEmail = "your@email.com";
#   };
# }

# Apply changes:
home-manager switch
```

### Option 2: Nix Flakes
```bash
# Create a flake for your system configuration
nix flake init
# Edit flake.nix to define your packages and configuration
nix develop  # Enter development shell with packages
```

### Option 3: Traditional nix-env
```bash
# Install packages directly
nix-env -iA nixpkgs.neovim nixpkgs.git nixpkgs.htop

# List installed packages
nix-env -q
```

## 🐛 Troubleshooting

### Nix installation issues
- Make sure you have curl and xz-utils: `sudo apt install curl xz-utils`
- For multi-user installation, the script needs sudo access
- After installation, reload your shell: `source ~/.bashrc` or `source ~/.zshrc`
- If nix commands aren't found, check if the profile is sourced in your shell config

### Chrome won't install
- Make sure you're on a 64-bit system (amd64)
- Check internet connection
- Try running: `sudo apt update && sudo apt upgrade`

### Cursor AppImage won't run
- Make sure FUSE is installed: `sudo apt install fuse libfuse2`
- Check if the file is executable: `chmod +x ~/.local/bin/cursor`

### Alacritty build fails
- Install all dependencies listed in the script
- Make sure you have enough disk space (build requires ~1GB)
- Check Rust installation: `rustc --version`

## 📜 License

Personal use repository
