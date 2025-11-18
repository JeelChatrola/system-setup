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
    echo "What would you like to install?"
    echo ""
    echo "1) Nix Package Manager"
    echo "2) Google Chrome"
    echo "3) Cursor (AI Code Editor)"
    echo "4) Alacritty (Terminal Emulator)"
    echo "5) AppImage Tools"
    echo "6) All of the above"
    echo "7) Exit"
    echo ""
    read -p "Enter your choice [1-7]: " choice
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

install_all() {
    install_nix
    install_chrome
    install_cursor
    install_alacritty
    install_appimage_tools
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
        all)
            install_all
            ;;
        *)
            echo "Usage: $0 [nix|chrome|cursor|alacritty|appimage|all]"
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
                install_chrome
                ;;
            3)
                install_cursor
                ;;
            4)
                install_alacritty
                ;;
            5)
                install_appimage_tools
                ;;
            6)
                install_all
                ;;
            7)
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

