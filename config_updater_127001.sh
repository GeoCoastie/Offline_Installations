#!/bin/bash

# Define the path to your config.yml
CONFIG_FILE="config.yml"

# Replace placeholders with 127.0.0.1
sed -i 's/<indexer-node-ip>/127.0.0.1/g' "$CONFIG_FILE"
sed -i 's/<wazuh-manager-ip>/127.0.0.1/g' "$CONFIG_FILE"
sed -i 's/<dashboard-node-ip>/127.0.0.1/g' "$CONFIG_FILE"

echo "Configuration updated successfully."

exit
