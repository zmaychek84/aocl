# Copyright (C) 2025, Advanced Micro Devices, Inc. All rights reserved.

#!/bin/bash

# Function to check if the sudo password is correct
check_sudo_password() {
    if ! sudo -v; then
        echo "Incorrect sudo password. Exiting."
        exit 1
    fi
}

# Check sudo password
check_sudo_password

# Detect the OS
OS=$(awk -F= '/^NAME/{print $2}' /etc/os-release)

# Function to check if a package is installed (Ubuntu)
is_installed_ubuntu() {
    dpkg -s "$1" &> /dev/null
}

# Function to check if a package is installed (Red Hat/CentOS)
is_installed_rhel() {
    rpm -q "$1" &> /dev/null
}

# Function to check cmake version
check_cmake_version() {
    cmake_version=$(cmake --version | grep -oP 'cmake version \K[0-9.]+')
    if [[ $(echo -e "$cmake_version\n3.26.0" | sort -V | head -n1) != "3.26.0" ]]; then
        return 1
    else
        return 0
    fi
}

# Update package lists and install prerequisites
if [[ "$OS" == *"Ubuntu"* ]]; then
    sudo apt-get update
    # Install prerequisites if not already installed
    for pkg in git wget gpg lsb-release build-essential perl pkg-config; do
        if ! is_installed_ubuntu "$pkg"; then
            sudo apt-get install -y "$pkg"
        fi
    done
    
    # Check and install cmake version 3.26.0 or above
    if ! command -v cmake &> /dev/null || ! check_cmake_version; then
        wget https://github.com/Kitware/CMake/releases/download/v3.31.5/cmake-3.31.5-linux-x86_64.tar.gz
        tar -xzvf cmake-3.31.5-linux-x86_64.tar.gz
        sudo cp -r cmake-3.31.5-linux-x86_64/* /usr/local/
        # Remove downloaded and extracted files
        rm -rf cmake-3.31.5-linux-x86_64.tar.gz cmake-3.31.5-linux-x86_64
    fi
    
    # Download the key to system keyring
    wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | gpg --dearmor | sudo tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null
    # Add signed entry to apt sources and configure the APT client to use Intel repository
    echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" | sudo tee /etc/apt/sources.list.d/oneAPI.list
    # Update package lists again
    sudo apt-get update
elif [[ "$OS" == *"Red Hat"* || "$OS" == *"CentOS"* ]]; then
    sudo yum update -y
    # Install prerequisites if not already installed
    for pkg in wget gcc make git perl pkg-config; do
        if ! is_installed_rhel "$pkg"; then
            sudo yum install -y "$pkg"
        fi
    done
    
    # Check and install cmake version 3.26.0 or above
    if ! command -v cmake &> /dev/null || ! check_cmake_version; then
        wget https://github.com/Kitware/CMake/releases/download/v3.31.5/cmake-3.31.5-linux-x86_64.tar.gz
        tar -xzvf cmake-3.31.5-linux-x86_64.tar.gz
        sudo cp -r cmake-3.31.5-linux-x86_64/* /usr/
        # Remove downloaded and extracted files
        rm -rf cmake-3.31.5-linux-x86_64.tar.gz cmake-3.31.5-linux-x86_64
    fi
    
    # Check if the system is registered with an entitlement server
    if ! sudo subscription-manager status &> /dev/null; then
        echo "This system is not registered with an entitlement server. Please register using 'subscription-manager' or 'rhc'."
        exit 1
    fi
    # Add the Intel repository
    sudo tee /tmp/oneAPI.repo > /dev/null << EOF
[oneAPI]
name=Intel® oneAPI repository
baseurl=https://yum.repos.intel.com/oneapi
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
EOF
    sudo mv /tmp/oneAPI.repo /etc/yum.repos.d
else
    echo "Unsupported OS"
    exit 1
fi

# Install oneAPI HPC Toolkit if not already installed
if [[ ! -d "/opt/intel/oneapi" || ! -f "/opt/intel/oneapi/setvars.sh" ]]; then
    if [[ "$OS" == *"Ubuntu"* ]]; then
        sudo apt-get install -y intel-basekit intel-hpckit
    elif [[ "$OS" == *"Red Hat"* || "$OS" == *"CentOS"* ]]; then
        sudo yum install -y intel-basekit intel-hpckit --skip-broken
    fi
    echo "oneAPI HPC Toolkit and Base Toolkit installation completed."
else
    echo "oneAPI Toolkit is already installed."
fi

# Install OpenSSL if not already installed
if [[ ! -d "$HOME/openssl" ]]; then
    if ! command -v git &> /dev/null; then
        echo "git is not installed. Please install git and rerun the script."
        echo "Installation failed."
        exit 1
    fi
    git clone https://github.com/openssl/openssl/ -b openssl-3.3.2
    cd openssl
    ./Configure --prefix=$HOME/openssl
    make -j
    make install
    # Remove the cloned OpenSSL directory
    cd ..
    rm -rf openssl
    echo "OpenSSL installation completed and installed in $HOME/openssl."
else
    echo "OpenSSL is already installed."
fi

# Check if installations were successful
if [[ -d "/opt/intel/oneapi" && -d "$HOME/openssl" ]]; then
    # Print instructions for setting environment variables
    echo -e "\e[32mPlease run the following commands to set the environment variables:\e[0m"
    echo -e "\e[34mexport OPENSSL_INSTALL_DIR=$HOME/openssl\e[0m"
    echo -e "\e[34msource /opt/intel/oneapi/setvars.sh\e[0m"
else
    echo "Installation failed."
fi
