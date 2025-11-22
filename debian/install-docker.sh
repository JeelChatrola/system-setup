#!/bin/bash
# Install Docker and Docker Compose on Debian-based systems

set -e

echo "[*] Installing Docker..."

# Check if running on Debian-based system
if ! command -v apt &> /dev/null; then
    echo "[ERROR] Error: This script is for Debian-based systems only"
    exit 1
fi

# Check if Docker is already installed
if command -v docker &> /dev/null; then
    echo "[OK] Docker is already installed"
    docker --version
    docker compose version
    exit 0
fi

# Install dependencies
echo "[*] Installing dependencies..."
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
echo "[*] Adding Docker GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]')/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Set up Docker repository
echo "[*] Adding Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]') \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
echo "[*] Installing Docker Engine..."
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add current user to docker group
echo "[*] Adding $USER to docker group..."
sudo usermod -aG docker "$USER"

# Enable and start Docker service
echo "[*] Enabling Docker service..."
sudo systemctl enable docker
sudo systemctl start docker

# Verify installation
echo ""
if command -v docker &> /dev/null; then
    echo "[OK] Docker installed successfully!"
    echo ""
    docker --version
    docker compose version
    echo ""
    echo "[*] Installation complete!"
    echo ""
    echo "[WARN]  IMPORTANT: You need to log out and log back in for docker group changes to take effect"
    echo "   Or run: newgrp docker"
    echo ""
    echo "[TIP] Test with: docker run hello-world"
else
    echo "[ERROR] Installation failed"
    exit 1
fi

