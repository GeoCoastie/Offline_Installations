#!/bin/bash

##Wazuh Offline Installation Package
## Steps can be followed here :https://documentation.wazuh.com/current/deployment-options/offline-installation/index.html

#Run as root for easier installation/index
su root

# Following commands pull required packages and configurations
curl -sO https://packages.wazuh.com/4.12/wazuh-install.sh
chmod 744 wazuh-install.sh
./wazuh-install.sh -dw deb -da amd64

#Download config file
curl -sO https://packages.wazuh.com/4.12/config.yml

#All in one deployment need to modify yml.
# If you are performing an all-in-one deployment, replace "<indexer-node-ip>", "<wazuh-manager-ip>", and "<dashboard-node-ip>" with 127.0.0.1.

#Creates certs
./wazuh-install.sh -g

#Copy/scp the following files for Host(s) installation.
# wazuh-install.sh, wazuh-offline.tar.gz, wazuh-install-files.tar

#COMPONENT INSTALL

#Indexer Installation
bash wazuh-install.sh --offline-installation --wazuh-indexer node-1

bash wazuh-install.sh --offline-installation --start-cluster

#Test cluster and pull admin password
tar -axf wazuh-install-files.tar wazuh-install-files/wazuh-passwords.txt -O | grep -P "\'admin\'" -A 1

#Test installation, chnage/modify IP
# curl -k -u admin:<ADMIN_PASSWORD> https://<WAZUH_INDEXER_IP_ADDRESS>:9200

#Test cluster
curl -k -u admin:<ADMIN_PASSWORD> https://<WAZUH_INDEXER_IP_ADDRESS>:9200/_cat/nodes?v

#Install Wazuh Server
bash wazuh-install.sh --offline-installation --wazuh-server wazuh-1

#Install Wazuh dashboard
bash wazuh-install.sh --offline-installation --wazuh-dashboard dashboard

#Password Files 
tar -O -xvf wazuh-install-files.tar wazuh-install-files/wazuh-passwords.txt

#Install Wazuh Indexer

#inside directory where offline files are placed
tar xf wazuh-offline.tar.gz
tar xf wazuh-install-files.tar

dpkg -i ./wazuh-offline/wazuh-packages/wazuh-indexer*.deb

#Config Node Name
NODE_NAME=<INDEXER_NODE_NAME>

mkdir /etc/wazuh-indexer/certs
mv -n wazuh-install-files/$NODE_NAME.pem /etc/wazuh-indexer/certs/indexer.pem
mv -n wazuh-install-files/$NODE_NAME-key.pem /etc/wazuh-indexer/certs/indexer-key.pem
mv wazuh-install-files/admin-key.pem /etc/wazuh-indexer/certs/
mv wazuh-install-files/admin.pem /etc/wazuh-indexer/certs/
cp wazuh-install-files/root-ca.pem /etc/wazuh-indexer/certs/
chmod 500 /etc/wazuh-indexer/certs
chmod 400 /etc/wazuh-indexer/certs/*
chown -R wazuh-indexer:wazuh-indexer /etc/wazuh-indexer/certs

#Edit Opensearch.yml's "network.host"
#Use same node address set in "config.yml"

#Set node.name ie node-1

#set cluster.initial_master_nodes:
#ie. 
cluster.initial_master_nodes:
- "node-1"
- "node-2"
- "node-3"

#Set discovery.seed_hosts: (list of master eligible hosts)
#ie.
discovery.seed_hosts:
  - "10.0.0.1"
  - "10.0.0.2"
  - "10.0.0.3"

# Set plugsins.security.nodes_dn: ( List of distinguied names of the certificates of all wazuh indexer cluster nodes)
#ie.
plugins.security.nodes_dn:
- "CN=node-1,OU=Wazuh,O=Wazuh,L=California,C=US"
- "CN=node-2,OU=Wazuh,O=Wazuh,L=California,C=US"
- "CN=node-3,OU=Wazuh,O=Wazuh,L=California,C=US"

#Enable and start Wazuh Indexer Service.
systemctl daemon-reload
systemctl enable wazuh-indexer
systemctl start wazuh-indexer

#After running, run on any indexer node to load new certs
/usr/share/wazuh-indexer/bin/indexer-security-init.sh

#Test
curl -XGET https://127.0.0.1:9200 -u admin:admin -k


#Install Wazuh Server
dpkg -i ./wazuh-offline/wazuh-packages/wazuh-manager*.deb

#Save wazuh indexer username and password
echo '<INDEXER_USERNAME>' | /var/ossec/bin/wazuh-keystore -f indexer -k username
echo '<INDEXER_PASSWORD>' | /var/ossec/bin/wazuh-keystore -f indexer -k password

#Restart Servicesystemctl daemon-reload
systemctl enable wazuh-manager
systemctl start wazuh-manager

#Check Status of Wazuh manager
systemctl status wazuh-manager

#Install Filebeat
dpkg -i ./wazuh-offline/wazuh-packages/filebeat*.deb

#Move a copy of configuration files and click YES to over write "/etc/filebeat/filebeat.yml"
cp ./wazuh-offline/wazuh-files/filebeat.yml /etc/filebeat/ &&\
cp ./wazuh-offline/wazuh-files/wazuh-template.json /etc/filebeat/ &&\
chmod go+r /etc/filebeat/wazuh-template.json

#Edit filebeat.yml
# Wazuh - Filebeat configuration file
 output.elasticsearch:
 hosts: ["10.0.0.1:9200"] #EDIT THIS
 protocol: https
 username: ${username}
 password: ${password}
 
 #Create filebeat keystore
 filebeat keystore create
 
 #Add username and password to secrets keystore
echo admin | filebeat keystore add username --stdin --force
echo admin | filebeat keystore add password --stdin --force

#Install Wazuh module for Filebeat
tar -xzf ./wazuh-offline/wazuh-files/wazuh-filebeat-0.4.tar.gz -C /usr/share/filebeat/module

#Replace server node name in config.yml. ie. wazuh-1
NODE_NAME=<SERVER_NODE_NAME>

mkdir /etc/filebeat/certs
mv -n wazuh-install-files/$NODE_NAME.pem /etc/filebeat/certs/filebeat.pem
mv -n wazuh-install-files/$NODE_NAME-key.pem /etc/filebeat/certs/filebeat-key.pem
cp wazuh-install-files/root-ca.pem /etc/filebeat/certs/
chmod 500 /etc/filebeat/certs
chmod 400 /etc/filebeat/certs/*
chown -R root:root /etc/filebeat/certs

#Enable and restart Filebeat
systemctl daemon-reload
systemctl enable filebeat
systemctl start filebeat

#Install wazuh-dashboard
dpkg -i ./wazuh-offline/wazuh-packages/wazuh-dashboard*.deb

#Replace dashboard_node_name in config.yml.
NODE_NAME=<DASHBOARD_NODE_NAME>

mkdir /etc/wazuh-dashboard/certs
mv -n wazuh-install-files/$NODE_NAME.pem /etc/wazuh-dashboard/certs/dashboard.pem
mv -n wazuh-install-files/$NODE_NAME-key.pem /etc/wazuh-dashboard/certs/dashboard-key.pem
cp wazuh-install-files/root-ca.pem /etc/wazuh-dashboard/certs/
chmod 500 /etc/wazuh-dashboard/certs
chmod 400 /etc/wazuh-dashboard/certs/*
chown -R wazuh-dashboard:wazuh-dashboard /etc/wazuh-dashboard/certs

#Edit opensearch_dashboards.yml
#ie.
server.host: 0.0.0.0
   server.port: 443
   opensearch.hosts: https://127.0.0.1:9200
   opensearch.ssl.verificationMode: certificate
   
#reload and restart services
systemctl daemon-reload
systemctl enable wazuh-dashboard
systemctl start wazuh-dashboard

#Edit wazuh.yml and replace url with wazuh server master node ip.
#ie.
hosts:
  - default:
      url: https://<WAZUH_SERVER_IP_ADDRESS>
      port: 55000
      username: wazuh-wui
      password: wazuh-wui
      run_as: false

#Verify dashboard Status
systemctl status wazuh-dashboard

# *************** Installation Completed!!! **********************

#To change internal passwords 

## All in one deployment =
# /usr/share/wazuh-indexer/plugins/opensearch-security/tools/wazuh-passwords-tool.sh --api --change-all --admin-user wazuh --admin-password wazuh
   
## Distributed deployment
# /usr/share/wazuh-indexer/plugins/opensearch-security/tools/wazuh-passwords-tool.sh --change-all

# Get Auth TOKEN
# TOKEN=$(curl -u wazuh-wui:wazuh-wui -k -X GET "https://127.0.0.1:55000/security/user/authenticate?raw=true")

# Change user creds
# 
curl -k -X PUT "https://127.0.0.1:55000/security/users/1" -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d'
{
  "password": "SuperS3cretPassword!"
}'

# Change wazuh-wui creds
# 
curl -k -X PUT "https://127.0.0.1:55000/security/users/2" -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d'
{
  "password": "SuperS3cretPassword!"
}'

# Restart Filebeat
# systemctl restart filebeat







 




