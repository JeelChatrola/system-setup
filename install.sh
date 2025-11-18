#!/bin/bash
# Main installation script for system-setup

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  System Setup - Installation${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    else
        print_error "Cannot detect OS"
        exit 1
    fi
    
    print_info "Detected OS: $OS $VER"
}

show_menu() {
    echo ""
    echo "==================== INSTALLATION MENU ===================="
    echo ""
    echo "📦 Core System:"
    echo "  1)  Nix Package Manager (for dotfiles & user packages)"
    echo "  2)  Docker + Docker Compose"
    echo "  3)  NVIDIA Container Toolkit (requires Docker)"
    echo ""
    echo "🌐 Browsers & Editors:"
    echo "  4)  Google Chrome"
    echo "  5)  Cursor (AI Code Editor)"
    echo ""
    echo "💻 Terminal & Tools:"
    echo "  6)  Alacritty (Terminal Emulator)"
    echo "  7)  AppImage Tools"
    echo ""
    echo "⚙️  Customization:"
    echo "  8)  Application Launcher (Ctrl+Space, like Mac Spotlight)"
    echo "  9)  Setup Keybindings (Ctrl+Alt+T for terminal)"
    echo "  10) Setup Appearance (themes, fonts, tweaks)"
    echo ""
    echo "🚀 Quick Install:"
    echo "  11) Install System Essentials (1-7)"
    echo "  12) Install Everything (1-10)"
    echo ""
    echo "  0)  Exit"
    echo ""
    echo "==========================================================="
    echo ""
    read -p "Enter your choice [0-12]: " choice
}

install_nix() {
    print_info "Installing Nix Package Manager..."
    if [ "$OS" = "debian" ] || [ "$OS" = "ubuntu" ]; then
        bash "$SCRIPT_DIR/debian/install-nix.sh"
    else
        print_error "Nix installation not supported for $OS yet"
    fi
}

install_chrome() {
    print_info "Installing Google Chrome..."
    if [ "$OS" = "debian" ] || [ "$OS" = "ubuntu" ]; then
        bash "$SCRIPT_DIR/debian/install-chrome.sh"
    else
        print_error "Chrome installation not supported for $OS yet"
    fi
}

install_cursor() {
    print_info "Installing Cursor..."
    if [ "$OS" = "debian" ] || [ "$OS" = "ubuntu" ]; then
        bash "$SCRIPT_DIR/debian/install-cursor.sh"
    else
        print_error "Cursor installation not supported for $OS yet"
    fi
}

install_alacritty() {
    print_info "Installing Alacritty..."
    if [ "$OS" = "debian" ] || [ "$OS" = "ubuntu" ]; then
        bash "$SCRIPT_DIR/debian/install-alacritty.sh"
    else
        print_error "Alacritty installation not supported for $OS yet"
    fi
}

install_appimage_tools() {
    print_info "Setting up AppImage tools..."
    if [ "$OS" = "debian" ] || [ "$OS" = "ubuntu" ]; then
        bash "$SCRIPT_DIR/debian/setup-appimage.sh"
    else
        print_error "AppImage setup not supported for $OS yet"
    fi
}

install_docker() {
    print_info "Installing Docker..."
    if [ "$OS" = "debian" ] || [ "$OS" = "ubuntu" ]; then
        bash "$SCRIPT_DIR/debian/install-docker.sh"
    else
        print_error "Docker installation not supported for $OS yet"
    fi
}

install_nvidia_toolkit() {
    print_info "Installing NVIDIA Container Toolkit..."
    if [ "$OS" = "debian" ] || [ "$OS" = "ubuntu" ]; then
        bash "$SCRIPT_DIR/debian/install-nvidia-toolkit.sh"
    else
        print_error "NVIDIA Toolkit installation not supported for $OS yet"
    fi
}

install_launcher() {
    print_info "Installing Application Launcher..."
    if [ "$OS" = "debian" ] || [ "$OS" = "ubuntu" ]; then
        bash "$SCRIPT_DIR/debian/install-launcher.sh"
    else
        print_error "Launcher installation not supported for $OS yet"
    fi
}

setup_keybindings() {
    print_info "Setting up keybindings..."
    if [ "$OS" = "debian" ] || [ "$OS" = "ubuntu" ]; then
        bash "$SCRIPT_DIR/debian/setup-keybindings.sh"
    else
        print_error "Keybinding setup not supported for $OS yet"
    fi
}

setup_appearance() {
    print_info "Setting up appearance..."
    if [ "$OS" = "debian" ] || [ "$OS" = "ubuntu" ]; then
        bash "$SCRIPT_DIR/debian/setup-appearance.sh"
    else
        print_error "Appearance setup not supported for $OS yet"
    fi
}

install_essentials() {
    print_info "Installing System Essentials..."
    install_nix
    install_docker
    install_chrome
    install_cursor
    install_alacritty
    install_appimage_tools
}

install_all() {
    print_info "Installing Everything..."
    install_nix
    install_docker
    install_chrome
    install_cursor
    install_alacritty
    install_appimage_tools
    install_launcher
    setup_keybindings
    setup_appearance
}

# Main execution
print_header
detect_os

if [ "$OS" != "debian" ] && [ "$OS" != "ubuntu" ]; then
    print_warning "This script currently only supports Debian-based systems"
    print_info "Detected: $OS"
    exit 1
fi

# Check if running with arguments
if [ $# -gt 0 ]; then
    case "$1" in
        nix)
            install_nix
            ;;
        docker)
            install_docker
            ;;
        nvidia|nvidia-toolkit)
            install_nvidia_toolkit
            ;;
        chrome)
            install_chrome
            ;;
        cursor)
            install_cursor
            ;;
        alacritty)
            install_alacritty
            ;;
        appimage)
            install_appimage_tools
            ;;
        launcher)
            install_launcher
            ;;
        keybindings)
            setup_keybindings
            ;;
        appearance)
            setup_appearance
            ;;
        essentials)
            install_essentials
            ;;
        all)
            install_all
            ;;
        *)
            echo "Usage: $0 [OPTION]"
            echo ""
            echo "Options:"
            echo "  nix             Install Nix package manager"
            echo "  docker          Install Docker"
            echo "  nvidia          Install NVIDIA Container Toolkit"
            echo "  chrome          Install Google Chrome"
            echo "  cursor          Install Cursor AI Editor"
            echo "  alacritty       Install Alacritty terminal"
            echo "  appimage        Setup AppImage tools"
            echo "  launcher        Install application launcher (Spotlight-like)"
            echo "  keybindings     Setup custom keybindings"
            echo "  appearance      Setup themes and appearance"
            echo "  essentials      Install core system tools"
            echo "  all             Install everything"
            exit 1
            ;;
    esac
else
    # Interactive mode
    while true; do
        show_menu
        case $choice in
            1)
                install_nix
                ;;
            2)
                install_docker
                ;;
            3)
                install_nvidia_toolkit
                ;;
            4)
                install_chrome
                ;;
            5)
                install_cursor
                ;;
            6)
                install_alacritty
                ;;
            7)
                install_appimage_tools
                ;;
            8)
                install_launcher
                ;;
            9)
                setup_keybindings
                ;;
            10)
                setup_appearance
                ;;
            11)
                install_essentials
                ;;
            12)
                install_all
                ;;
            0)
                print_info "Exiting..."
                exit 0
                ;;
            *)
                print_error "Invalid choice. Please try again."
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
fi

