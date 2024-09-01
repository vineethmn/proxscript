#!/bin/bash

# Update package index
echo "Updating package index..."
yum check-update

# Install OpenSSH server
echo "Installing OpenSSH server..."
yum install -y openssh-server

# Enable and start the SSH service
echo "Enabling and starting SSH service..."
systemctl enable sshd
systemctl start sshd

# Confirm SSH service status
echo "Checking SSH service status..."
systemctl status sshd

echo "SSH installation and setup complete."
