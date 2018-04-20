#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

print_status() {
    echo
    echo "## $1"
    echo
}

if [ $# -ne 6 ]; then
    echo "Execution format ./install.sh [mn_alias] [mn_public_ip]:[mn_port] [masternodePrivkey] [tx_hash] [tx_index]"
    exit
fi

# Installation variables
mn_alias=${1}
mn_public_ip=${2}
mn_port=${3}
masternodePrivkey=${4}
tx_hash=${5}
tx_index=${6}

rpcpassword=$(head -c 32 /dev/urandom | base64)

print_status "Installing the Argo node..."

echo "#########################"
echo "Alias: $mn_alias"
echo "IP Address: $mn_public_ip"
echo "Port: $mn_port"
echo "Private Key: $masternodePrivkey"
echo "Collateral tx Hash: $tx_hash"
echo "Collateral tx Output Index: $tx_index"
echo "#########################"

# Create swapfile if less then 4GB memory
totalmem=$(free -m | awk '/^Mem:/{print $2}')
totalswp=$(free -m | awk '/^Swap:/{print $2}')
totalm=$(($totalmem + $totalswp))
if [ $totalm -lt 4000 ]; then
  print_status "Server memory is less then 4GB..."
  if ! grep -q '/swapfile' /etc/fstab ; then
    print_status "Creating a 4GB swapfile..."
    fallocate -l 4G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
  fi
fi

# Populating Cache
print_status "Populating apt-get cache..."
apt-get update

print_status "Installing packages required for setup..."
apt-get install -y docker.io apt-transport-https lsb-release curl fail2ban unattended-upgrades ufw > /dev/null 2>&1

systemctl enable docker
systemctl start docker

print_status "Creating the docker mount directories..."
mkdir -p /mnt/argo/{config,data,argo-params}

print_status "Creating the argo configuration."
cat <<EOF > /mnt/argo/config/argo.conf
rpcuser=argo
rpcpassword=$rpcpassword
rpcport=$mn_port
rpcallowip=127.0.0.0/24
listen=1
server=1
# Docker doesn't run as daemon
daemon=0
masternode=1
masternodeprivkey=$masternodePrivkey
EOF

print_status "Creating the masternode config..."
mkdir -p /mnt/argo/masternode/
echo -n $mn_alias > /mnt/argo/masternode/alias
echo -n $mn_public_ip > /mnt/argo/masternode/publicip
echo -n '127.0.0.0/24' > /mnt/argo/masternode/rpcallowip
echo -n '127.0.0.1' > /mnt/argo/masternode/rpcbind
echo -n $mn_port > /mnt/argo/masternode/rpcport
echo -n 'argo' > /mnt/argo/masternode/rpcuser
echo -n $rpcpassword > /mnt/argo/masternode/rpcpassword
echo -n $masternodePrivkey > /mnt/argo/masternode/privkey
echo -n $tx_hash > /mnt/argo/masternode/txhash
echo -n $tx_index > /mnt/argo/masternode/txindex

print_status "Installing argod service..."
cat <<EOF > /etc/systemd/system/argo-node.service
[Unit]
Description=Argo Daemon Container
After=docker.service
Requires=docker.service

[Service]
TimeoutStartSec=10m
Restart=always
ExecStartPre=-/usr/bin/docker stop argo-node
ExecStartPre=-/usr/bin/docker rm  argo-node
# Always pull the latest docker image
ExecStartPre=/usr/bin/docker pull greerso/argod:latest
ExecStart=/usr/bin/docker run --rm --net=host -p 8989:8989 -p 8988:8988 -v /mnt/argo:/mnt/argo --name argo-node greerso/argod:latest
[Install]
WantedBy=multi-user.target
EOF

print_status "Installing Argo Sentinel service..."
cat <<EOF > /etc/systemd/system/argo-sentinel.service
[Unit]
Description=Argo Sentinel Container
After=docker.service
Requires=docker.service

[Service]
TimeoutStartSec=10m
Restart=always
ExecStartPre=-/usr/bin/docker stop argo-sentinel
ExecStartPre=-/usr/bin/docker rm  argo-sentinel
# Always pull the latest docker image
ExecStartPre=/usr/bin/docker pull greerso/argo-sentinel:latest
#ExecStart=/usr/bin/docker run --init --rm --net=host -v /mnt/zen:/mnt/zen --name zen-secnodetracker whenlambomoon/secnodetracker:latest
ExecStart=/usr/bin/docker run --rm --net=host -v /mnt/argo:/mnt/argo --name argo-sentinel greero/argo-sentinel:latest
[Install]
WantedBy=multi-user.target
EOF

print_status "Enabling and starting container services..."
systemctl daemon-reload
systemctl enable argo-node
systemctl restart argo-node

systemctl enable argo-sentinel
systemctl restart argo-sentinel

print_status "Enabling basic firewall services..."
ufw default allow outgoing
ufw default deny incoming
ufw allow ssh/tcp
ufw limit ssh/tcp
ufw allow http/tcp
ufw allow https/tcp
ufw allow $mn_port/tcp
#ufw allow 19033/tcp
ufw --force enable

print_status "Enabling fail2ban services..."
systemctl enable fail2ban
systemctl start fail2ban

print_status "Waiting for node to sync could take > 10 minutes..."

secs=$((10 * 60))
while docker exec -it argo-node /usr/local/bin/gosu argo argo-cli mnsync status | grep `"IsSynced": true,`
do
  echo -ne "$secs\033[0K\r"
  sleep 1
  : $((secs--))
done

print_status "Go to Desktop wallet"
print_status "Open the ArgoCoin Desktop Wallet."
print_status ""
print_status "Go to [Settings] -> [Options] ->[Wallet]"
print_status "Enable the \"Enable coin control features\" and \"Show Masternodes Tab\""
print_status ""
print_status "Go to [Tools] -> [Open Masternode Configuration File]"
print_status ""
print_status "Edit masternode.conf file:"
print_status "Add: mn1 [public_ip]:8989 [masternodePrivkey] [tx_hash] [tx_index]"
print_status "example: mn1 197.4.0.21:8989 65WitritDkin0000002V0000000000b65SsCPk3eeMaaL1KHinW c84f87000000000083000000658810b92e0d032zz3c840000f9e18714456a67c 0"
print_status ""
print_status "Restart Desktop wallet."
print_status ""
print_status "[Masternodes] -> [Start all]"
print_status "Warning - Be sure to click [Start all] only when \"IsSynced\" is \"true\"."
print_status ""
print_status "[Masternodes] -> [Update status]"
print_status ""
print_status "Install Finished"

