#!/bin/bash

# Update package index
echo "Updating package index..."
dnf check-update

# Install curl and git
echo "Installing curl and git..."
dnf install -y curl git

# Install Docker
echo "Installing Docker..."

# Set up the Docker repository
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Add user to the docker group (optional)
# Uncomment the following line if you want to add the current user to the docker group
# usermod -aG docker $USER

# Clean up
echo "Cleaning up..."
rm get-docker.sh

echo "Installation complete."
