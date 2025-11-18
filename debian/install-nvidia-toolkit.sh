#!/bin/bash
# Install NVIDIA Container Toolkit for Docker on Debian-based systems

set -e

echo "📦 Installing NVIDIA Container Toolkit..."

# Check if running on Debian-based system
if ! command -v apt &> /dev/null; then
    echo "❌ Error: This script is for Debian-based systems only"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker must be installed first"
    echo "   Run: ./install-docker.sh"
    exit 1
fi

# Check if NVIDIA GPU is present
if ! lspci | grep -i nvidia > /dev/null; then
    echo "⚠️  Warning: No NVIDIA GPU detected"
    read -p "Continue anyway? [y/N]: " continue
    if [[ ! $continue =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# Check if nvidia-container-toolkit is already installed
if command -v nvidia-ctk &> /dev/null; then
    echo "✅ NVIDIA Container Toolkit is already installed"
    nvidia-ctk --version
    exit 0
fi

# Add NVIDIA Container Toolkit repository
echo "📡 Adding NVIDIA Container Toolkit repository..."
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Install NVIDIA Container Toolkit
echo "🔧 Installing NVIDIA Container Toolkit..."
sudo apt update
sudo apt install -y nvidia-container-toolkit

# Configure Docker to use NVIDIA runtime
echo "⚙️  Configuring Docker runtime..."
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# Verify installation
echo ""
if command -v nvidia-ctk &> /dev/null; then
    echo "✅ NVIDIA Container Toolkit installed successfully!"
    echo ""
    nvidia-ctk --version
    echo ""
    echo "💡 Test with: docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi"
else
    echo "❌ Installation failed"
    exit 1
fi

