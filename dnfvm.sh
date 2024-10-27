#!/bin/bash

# Function to update the system and install essential packages
function update_system() {
  echo "Updating system and installing essential packages (sudo, openssh-server, curl)..."
  yum update -y
  yum install -y sudo openssh-server curl
  systemctl enable --now sshd
}

# Function to change the hostname
function change_hostname() {
  read -p "Do you want to change the hostname? (y/n): " change_hostname
  if [[ "$change_hostname" == "y" ]]; then
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

    # Backup existing network configuration
    cp /etc/sysconfig/network-scripts/ifcfg-$interface /etc/sysconfig/network-scripts/ifcfg-$interface.bak

    # Write new static IP configuration
    cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-$interface
DEVICE=$interface
BOOTPROTO=static
ONBOOT=yes
IPADDR=$ip_addr
NETMASK=$netmask
GATEWAY=$gateway
EOF

    if systemctl restart network; then
      echo "Static IP configured for $interface."
    else
      echo "Failed to configure networking. Check /etc/sysconfig/network-scripts/ifcfg-$interface."
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
  if [[ "$install_docker" == "y" ]]; then selected_packages+="docker "; fi
  if [[ "$install_nano" == "y" ]]; then selected_packages+="nano "; fi
  if [[ "$install_wget" == "y" ]]; then selected_packages+="wget "; fi
  if [[ "$install_curl" == "y" ]]; then selected_packages+="curl "; fi

  # Install selected packages if any
  if [ -n "$selected_packages" ]; then
    echo "Installing selected packages: $selected_packages"
    yum install -y $selected_packages
  else
    echo "No packages selected for installation."
  fi

  # Option to install additional packages repeatedly until user declines
  while true; do
    read -p "Install additional package? (y/n): " add_pkg
    if [[ "$add_pkg" == "y" ]]; then
      read -p "Enter additional package name: " extra_package
      yum install -y "$extra_package"
    else
      break
    fi
  done
}

# Function to install Docker specifically for RHEL-based systems
function install_docker() {
  echo "Installing Docker on RHEL-based system..."
  yum install -y yum-utils
  yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  yum install -y docker-ce docker-ce-cli containerd.io
  systemctl enable --now docker
  echo "Docker installed and started."
}

# Function to add users to sudo group
function add_sudo_user() {
  current_user=$(whoami)
  if [[ $current_user != "root" ]]; then
    usermod -aG wheel "$current_user"
    echo "$current_user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$current_user
    echo "$current_user added to sudoers."
  fi

  read -p "Add another user to sudo group? (y/n): " add_user
  if [[ $add_user == "y" ]]; then
    read -p "Enter username: " new_user
    usermod -aG wheel "$new_user"
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
install_docker
add_sudo_user
setup_ssh_key

echo "Setup complete!"
