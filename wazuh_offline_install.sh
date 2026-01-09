#!/bin/sh

## This script will download offline packages to be used for Wazuh Offline Installation

# Download Packages
curl -sO https://packages.wazuh.com/4.14/wazuh-install.sh
if [ $? -ne 0 ]; then
    echo "Failed to download wazuh-install.sh"
    exit 1
fi

# Make the installation script executable
chmod +x wazuh-install.sh

# Download Deb packages
./wazuh-install.sh -dw deb -da amd64
if [ $? -ne 0 ]; then
    echo "Failed to download deb packages"
    exit 1
fi

# Pull Certificates Config File
curl -sO https://packages.wazuh.com/4.14/config.yml
if [ $? -ne 0 ]; then
    echo "Failed to download config.yml"
    exit 1
fi

echo "Edit config.yml IP's with 127.0.0.1"

# Run Config.yml auto updater script
./config_updater_127001.sh
if [ $? -ne 0 ]; then
    echo "Failed to run config updater script"
    exit 1
fi

# Uncomment if you want to edit manually
# nano ./config.yml

# Create certificates for nodes
./wazuh-install.sh -g
if [ $? -ne 0 ]; then
    echo "Failed to create certificates"
    exit 1
fi

echo "Files downloaded, certs created"
echo "Copy the following files: wazuh-install.sh, wazuh-offline.tar.gz, wazuh-install-files.tar"

exit 0
