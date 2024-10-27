#!/bin/bash

# Function to update the system and install essential packages
function update_system() {
  echo "Updating system and installing essential packages (sudo, openssh-server, curl)..."
  apt update -y && apt upgrade -y
  apt install -y sudo openssh-server curl
}

# Function to change the hostname
function change_hostname() {
  read -p "Do you want to change the hostname? (y/n): " change_host
  if [[ $change_host == "y" ]]; then
    read -p "Enter new hostname: " new_hostname
    hostnamectl set-hostname "$new_hostname"
    echo "127.0.1.1 $new_hostname" >> /etc/hosts
    echo "Hostname changed to $new_hostname"
  fi
}

# Function to set static IP address
function set_static_ip() {
  echo "Available network interfaces:"
  ip -o link show | awk -F': ' '{print $2}'
  read -p "Enter interface name to set static IP (or press Enter to skip): " interface
  if [ -n "$interface" ]; then
    read -p "Enter Static IP: " ip_addr
    read -p "Enter Netmask: " netmask
    read -p "Enter Gateway: " gateway
    
    # Backup existing interfaces file
    cp /etc/network/interfaces /etc/network/interfaces.bak

    # Create new interfaces file with static IP configuration
    cat <<EOF > /etc/network/interfaces
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto $interface
iface $interface inet static
  address $ip_addr
  netmask $netmask
  gateway $gateway
EOF

    if systemctl restart networking; then
      echo "Static IP configured for $interface."
    else
      echo "Failed to configure networking. Check /etc/network/interfaces."
    fi
  fi
}

# Function to install selected packages
function install_packages() {
  echo "Package installation options (y/n):"

  read -p "Install git? (y/n): " install_git
  read -p "Install docker? (y/n): " install_docker
  read -p "Install nano? (y/n): " install_nano
  read -p "Install wget? (y/n): " install_wget
  read -p "Install curl? (y/n): " install_curl

  # Initialize an empty variable for selected packages
  selected_packages=""

  # Append selected packages based on user input
  if [[ "$install_git" == "y" ]]; then selected_packages+="git "; fi
  if [[ "$install_nano" == "y" ]]; then selected_packages+="nano "; fi
  if [[ "$install_wget" == "y" ]]; then selected_packages+="wget "; fi
  if [[ "$install_curl" == "y" ]]; then selected_packages+="curl "; fi

  # Install selected packages if any
  if [ -n "$selected_packages" ]; then
    echo "Installing selected packages: $selected_packages"
    apt update && apt install -y $selected_packages
  else
    echo "No packages selected for installation."
  fi

  # Install Docker if selected
  if [[ "$install_docker" == "y" ]]; then
    echo "Installing Docker using the official installation script..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
  fi

  # Option to install additional package
  while true; do
    read -p "Install additional package? (y/n): " add_pkg
    if [[ "$add_pkg" == "y" ]]; then
      read -p "Enter additional package name: " extra_package
      apt install -y "$extra_package"
    else
      break
    fi
  done
}


# Function to add users to sudo group
function add_sudo_user() {
  current_user=$(whoami)
  if [[ $current_user != "root" ]]; then
    usermod -aG sudo "$current_user"
    echo "$current_user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$current_user
    echo "$current_user added to sudoers."
  fi

  read -p "Add another user to sudo group? (y/n): " add_user
  if [[ $add_user == "y" ]]; then
    read -p "Enter username: " new_user
    usermod -aG sudo "$new_user"
    echo "$new_user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$new_user
    echo "$new_user added to sudoers."
  fi
}

# Function to configure SSH key-based authentication
function setup_ssh_key() {
  echo "Configuring SSH key-based authentication..."
  
  ssh_pub_key_url="https://raw.githubusercontent.com/vineethmn/proxscript/refs/heads/main/publickey.pub"
  ssh_key=$(curl -s "$ssh_pub_key_url")

  if [ -n "$ssh_key" ]; then
    for user in "$current_user" "$new_user"; do
      user_home=$(eval echo ~$user)
      mkdir -p "$user_home/.ssh"
      echo "$ssh_key" >> "$user_home/.ssh/authorized_keys"
      chown -R "$user":"$user" "$user_home/.ssh"
      chmod 600 "$user_home/.ssh/authorized_keys"
      echo "SSH key configured for $user"
    done
  else
    echo "Failed to fetch SSH key."
  fi
}

# Main script execution
update_system
change_hostname
read -p "Set static IP address? (y/n): " set_ip
if [[ $set_ip == "y" ]]; then
  set_static_ip
fi
install_packages
add_sudo_user
setup_ssh_key

echo "Setup complete!"
