1#!/bin/sh

## This script will download offline packages to be used for Wazuh Offline Installation

#Download Packages
curl -sO https://packages.wazuh.com/4.14/wazuh-install.sh 
chmod 744 wazuh-install.sh

#Download Deb packages
./wazuh-install.sh -dw deb -da amd64

#Pull Certificates Config File
curl -sO https://packages.wazuh.com/4.14/config.yml

echo "Edit config.yml IP's with 127.0.0.1"

#Run Config.yml auto updater script
./config_updater_127001.sh

#nano ./config.yml

#Create certificates for nodes
./wazuh-install.sh -g

echo "Files downloaded, certs created"

echo "Copy the following files, wazuh-install.sh, wazuh-offline.tar.gz, wazuh-install-files.tar"

mkdir ./SCP

cp wazuh-install.sh wazuh-offline.tar.gz wazuh-install-files.tar ./SCP

echo "Files copied to SCP folder"

exit

