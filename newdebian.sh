#!/bin/bash

# Define the user to be added to the sudoers file
USER_TO_ADD=$(whoami)
PUBLIC_KEY_URL="https://raw.githubusercontent.com/vineethmn/proxscript/refs/heads/main/publickey.pub"

# Function to install necessary packages
install_packages() {
    # Check if each package is installed, and install if not
    for package in sudo nano git curl; do
        if ! dpkg -l | grep -qw "$package"; then
            echo "Installing $package..."
            apt-get install -y "$package"
        else
            echo "$package is already installed."
        fi
    done
}

# Function to add user to the sudoers file
add_user_to_sudoers() {
    if ! grep -q "^$USER_TO_ADD" /etc/sudoers; then
        echo "Adding $USER_TO_ADD to the sudoers file..."
        # Use echo and tee to safely append to the sudoers file
        echo "$USER_TO_ADD ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers > /dev/null
    else
        echo "$USER_TO_ADD is already in the sudoers file."
    fi
}

# Function to set up SSH key-based authentication
setup_ssh_key_auth() {
    echo "Setting up SSH key-based authentication..."
    # Create the .ssh directory if it doesn't exist
    mkdir -p /home/$USER_TO_ADD/.ssh
    # Fetch the public key and append it to authorized_keys
    curl -fsSL "$PUBLIC_KEY_URL" -o /home/$USER_TO_ADD/.ssh/authorized_keys
    # Set the correct permissions
    chown -R "$USER_TO_ADD:$USER_TO_ADD" /home/$USER_TO_ADD/.ssh
    chmod 700 /home/$USER_TO_ADD/.ssh
    chmod 600 /home/$USER_TO_ADD/.ssh/authorized_keys
}

# Execute the functions
install_packages
add_user_to_sudoers
setup_ssh_key_auth

echo "Setup complete."
