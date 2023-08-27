#!/bin/bash
set -euo pipefail

log() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') $1"
}

# Require root privileges
[ "$EUID" -eq 0 ] || { log "Please run as root."; exit 1; }

# Check if Docker is already installed
command -v docker &> /dev/null && { log "Docker is already installed. Exiting."; exit 0; }

# Update and install prerequisites in one step
log "Updating package info and installing prerequisites..."
apt-get update -qq && apt-get install -y -qq apt-transport-https ca-certificates curl software-properties-common

# Add Docker GPG key and repository, and install Docker
log "Setting up Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
apt-get update -qq && apt-get install -y -qq docker-ce

# Enable and start Docker service
log "Enabling and starting Docker service..."
systemctl enable --now docker

# Create docker group and add user
getent group docker || { log "Creating docker group..."; groupadd docker; }
log "Adding current user to docker group..."
usermod -aG docker $SUDO_USER

# Install Docker Compose
log "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose

# Verify installations
log "Verifying installations..."
docker --version && docker-compose --version

log "Docker and Docker Compose installed successfully. You may need to log out and log back in to use Docker without sudo."
