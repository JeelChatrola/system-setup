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
    echo -e "${GREEN}[OK] $1${NC}"
}

print_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[WARN]  $1${NC}"
}

print_info() {
    echo -e "${BLUE}[INFO]  $1${NC}"
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
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                  INSTALLATION MENU                       ║"
    echo "╠══════════════════════════════════════════════════════════╣"
    echo ""
    echo "  [*] Core System:"
    echo "      1)  Nix Package Manager (for dotfiles & user packages)"
    echo "      2)  Docker + Docker Compose"
    echo "      3)  NVIDIA Container Toolkit (requires Docker)"
    echo ""
    echo "  [*] Desktop & Tools:"
    echo "      4)  Alacritty (Terminal Emulator)"
    echo "      5)  Application Launcher (Rofi)"
    echo "      6)  i3 Window Manager"
    echo ""
    echo "  [*] Configuration:"
    echo "      7)  Setup Keybindings (Ctrl+Alt+T for terminal)"
    echo "      8)  Setup Appearance (themes, fonts, tweaks)"
    echo ""
    echo "  [*] Quick Install:"
    echo "      9)  Install Essentials (Core + Terminal + Launcher)"
    echo "     10)  Install Everything"
    echo ""
    echo "     0)   Exit"
    echo ""
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    read -p "Enter your choice [0-10]: " choice
}

install_nix() {
    print_info "Installing Nix Package Manager..."
    if [ "$OS" = "debian" ] || [ "$OS" = "ubuntu" ]; then
        bash "$SCRIPT_DIR/debian/install-nix.sh"
    else
        print_error "Nix installation not supported for $OS yet"
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
    print_info "Setting up appearance (Themes & Fonts)..."
    if [ "$OS" = "debian" ] || [ "$OS" = "ubuntu" ]; then
        bash "$SCRIPT_DIR/debian/setup-appearance.sh"
    else
        print_error "Appearance setup not supported for $OS yet"
    fi
}

install_i3() {
    print_info "Installing i3 Window Manager..."
    if [ "$OS" = "debian" ] || [ "$OS" = "ubuntu" ]; then
        bash "$SCRIPT_DIR/debian/install-i3.sh"
    else
        print_error "i3 installation not supported for $OS yet"
    fi
}

install_essentials() {
    print_info "Installing Essentials..."
    install_nix
    install_docker
    install_alacritty
    install_launcher
}

install_all() {
    print_info "Installing Everything..."
    install_nix
    install_docker
    install_nvidia_toolkit
    install_alacritty
    install_launcher
    install_i3
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
        alacritty)
            install_alacritty
            ;;
        launcher)
            install_launcher
            ;;
        i3)
            install_i3
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
            echo "  alacritty       Install Alacritty terminal"
            echo "  launcher        Install Rofi launcher"
            echo "  i3              Install i3 Window Manager"
            echo "  keybindings     Setup custom keybindings"
            echo "  appearance      Install themes and fonts"
            echo "  essentials      Install core tools"
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
                install_alacritty
                ;;
            5)
                install_launcher
                ;;
            6)
                install_i3
                ;;
            7)
                setup_keybindings
                ;;
            8)
                setup_appearance
                ;;
            9)
                install_essentials
                ;;
            10)
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

