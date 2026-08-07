#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "=== Starting ROCm and HIP Installation for Linux Mint ==="

# 1. Create directory for APT keys
echo "Creating keyring directory..."
sudo mkdir --parents --mode=0755 /etc/apt/keyrings

# 2. Download and install the ROCm GPG key
echo "Downloading ROCm GPG key..."
wget -qO - https://radeon.com | sudo gpg --dearmor -o /etc/apt/keyrings/rocm.gpg

# 3. Add the ROCm repository (using the Ubuntu base codename)
echo "Adding AMD ROCm repository..."
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://radeon.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/rocm.list

# 4. Pin the ROCm packages to prioritize them
echo "Setting repository pinning priorities..."
echo -e "Package: *\nPin: release o=://radeon.com\nPin-Priority: 600" | sudo tee /etc/apt/preferences.d/rocm-pin-600

# 5. Update package lists and install HIP SDK
echo "Updating package lists and installing rocm-hip-sdk (this may take a while)..."
sudo apt update
sudo apt install -y rocm-hip-sdk

# 6. Configure User Permissions
echo "Adding user $USER to render and video groups..."
sudo usermod -aG render,video $USER

# 7. Apply Environment Variables to .bashrc if they don't already exist
echo "Configuring environment variables in ~/.bashrc..."
if ! grep -q '/opt/rocm/bin' ~/.bashrc; then
    echo 'export PATH=$PATH:/opt/rocm/bin' >> ~/.bashrc
fi
if ! grep -q '/opt/rocm/lib' ~/.bashrc; then
    echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/rocm/lib' >> ~/.bashrc
fi

echo "=== Installation complete! ==="
echo "!!! Please REBOOT your computer now for changes to take effect !!!"

