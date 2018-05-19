#!/bin/bash

# =======================================================================================
# Silence apt
# =======================================================================================
export DEBIAN_FRONTEND=noninteractive
# ---------------------------------------------------------------------------------------

# =======================================================================================
# Run as root
# =======================================================================================
if [[ $(whoami) != "root" ]]; then
    echo "Please run this script as root user"
    exit 1
fi
# ---------------------------------------------------------------------------------------

# =======================================================================================
# Helper functions
# =======================================================================================

# Use 'print_status "text to display"'
print_status() {
    echo
    echo "## $1"
    echo
}

# Use 'echo "Please enter some information: (Default value)"'
#    'variableName=$(inputWithDefault value)'
inputWithDefault() {
    read -r userInput
    userInput=${userInput:-$@}
    echo "$userInput"
}

# run commands inside docker container on host
function docker_alias() {
    docker exec $1 gosu $2 $3
}
# ---------------------------------------------------------------------------------------

# =======================================================================================
# Install required packages
# =======================================================================================
print_status "Installing packages required for setup..."
apt-get update
apt-get -y upgrade
apt-get install -y docker.io \
	apt-transport-https \
	lsb-release \
	unattended-upgrades \
	wget curl htop jq \
	libzmq3-dev > /dev/null 2>&1
# ---------------------------------------------------------------------------------------

# =======================================================================================
# Installation variables
# =======================================================================================
rpcuser="nodiumhuser"
rpcpassword="$(head -c 32 /dev/urandom | base64)"
nodiumuserpw="$(head -c 32 /dev/urandom | base64)"
publicip="$(dig +short myip.opendns.com @resolver1.opendns.com)"
Hostname="$(cat /etc/hostname)"
sshPort=$(cat /etc/ssh/sshd_config | grep Port | awk '{print $2}')
# ---------------------------------------------------------------------------------------

# =======================================================================================
# Server setup
# =======================================================================================
read -p "Would you like perform a base server setup (swap, hostname, nodium user, ufw, fail2ban)? " choice
case "$choice" in 
  y|Y ) 
  	# =======================================================================================
	# Create swapfile if less then 4GB memory
	# =======================================================================================
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
	# ---------------------------------------------------------------------------------------
	
	# =======================================================================================
	print_status "Name Your Server..."
	# =======================================================================================
	read -p "Would you like to change your server hostname from $Hostname to something else? " choice
	case "$choice" in 
	  y|Y ) echo "Please enter server name: (Default: my.nodium.node)"
		newHostname=$(inputWithDefault my.nodium.node)
		sed -i "s|$Hostname|$newHostname|1" /etc/hostname
		if grep -q "$Hostname" /etc/hosts; then
		    sed -i "s|$Hostname|$newHostname|1" /etc/hosts
		else
		    echo "127.0.1.1 $newHostname" >> /etc/hosts
		fi
		hostname "$newHostname";;
		* ) echo "skipped";;
	esac
	# ---------------------------------------------------------------------------------------
	
	
	# =======================================================================================
	print_status "Add a nodium user..."
	# =======================================================================================
	read -p "Would you like to a nodium user? " choice
	case "$choice" in 
	  y|Y ) echo "Please enter the new user name: (Default nodium)"
		username=$(inputWithDefault nodium)
		echo "Please enter the password for '${username}': (Default $nodiumuserpw)"
		echo "You will need to remember this password"
		userPassword=$(inputWithDefault $nodiumuserpw)	
		adduser --gecos "" --disabled-password --quiet "$username"
		echo "$username:$userPassword" | chpasswd	
		# Add user to sudoers and docker
		adduser $username sudo docker;;
		* ) echo "skipped";;
	esac
	# ---------------------------------------------------------------------------------------
	
	# =======================================================================================
	# Secure SSH
	# =======================================================================================
	# if [ $sshPort = '22']
	# 	print_status "Secure SSH"
	# 	read -p "Change SSH from $sshPort?" choice
	# 	echo "Warning: You will no longer be able to connect to this server on $sshPort"
	# 	case "$choice" in 
	# 		# Set ssh port to 2222
	# 		y|Y ) echo "Please new port for SSH: (Default: 2222)"
	# 		sshPort=$(inputWithDefault 2222)
	# 		echo "You will need to remember this port to connect to this server"
	# 		if grep -q Port /etc/ssh/sshd_config; then
	# 		    sed -ri "s|(^(.{0,2})Port)( *)?(.*)|Port $sshPort|1" /etc/ssh/sshd_config
	# 		else
	# 		    echo "Port $sshPort" >> /etc/ssh/sshd_config
	# 		fi;;
	# 		* ) echo "skipped";;
	# 	esac
	# fi
	
	# Disable root user ssh login
	# read -p "Forbid root user SSH access?" choice
	# echo "Warning: root users will no longer be able to connect with SSH"
	# case "$choice" in
	# 	y|Y ) if grep -q PermitRootLogin /etc/ssh/sshd_config; then
	# 	    sed -ri "s|(^(.{0,2})PermitRootLogin)( *)?(.*)|PermitRootLogin no|1" /etc/ssh/sshd_config
	# 		else
	# 	    echo "PermitRootLogin no" >> /etc/ssh/sshd_config
	# 		fi;;
	# 	* ) echo "skipped";;
	# esac
	# 
	# if [ -n "$username" ]
	# 	# Disable the use of passwords with ssh
	# 	read -p "Disable Password Authentication and setup SSH keys for $username?" choice
	# 	echo "Warning: If you do not complete all steps to create SSH keys you will no longer be able to login to your server!"
	# 	echo "Do not do this unless you have created a SSH key on your local machine"
	# 	case "$choice" in
	# 	y|Y ) if grep -q PasswordAuthentication /etc/ssh/sshd_config; then
	# 		    sed -ri "s|(^(.{0,2})PasswordAuthentication)( *)?(.*)|PasswordAuthentication no|1" /etc/ssh/sshd_config
	# 		else
	# 		    echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
	# 		fi;;
	# 	* ) echo "skipped";;
	# 	esac
	# 	fi
	# 	
	# 	if [ ! -d "/home/$username/.ssh" ]; then
	# 	    mkdir "/home/$username/.ssh"
	# 	fi
	# 	clear
	# # improvement: put this first, do not continue unless a valid key is entered.
	# 	while [[ -z "$sshPublicKey" ]]
	# 	do
	# 	    echo "Please paste the contents of the public key(~.ssh/id_rsa.pub) here and press enter: (Cannot be empty)"
	# 	    read -r  sshPublicKey
	# 	done
	# 	
	# 	echo "$sshPublicKey" > "/home/$username/.ssh/authorized_keys"
	# 	chown -R "$username": "/home/$username/.ssh"
	# fi
	# 
	# # Restart the ssh daemon
	# systemctl restart sshd
	# 
	# clear
	# ---------------------------------------------------------------------------------------
	
	# =======================================================================================
	print_status "Enable basic firewall services?"
	# =======================================================================================
	read -p "Would you like to install UFW (a basic firewall)? " choice
	case "$choice" in 
	  y|Y ) apt-get install -y ufw
		ufw default allow outgoing
		ufw default deny incoming
		# Open ports for ssh and webapps
		ufw allow $sshPort/tcp comment 'ssh port'
		ufw allow 17652/tcp comment 'nodium daemon'	
		# Enable the firewall
		ufw enable;;
		* ) echo "skipped";;
	esac
	# ---------------------------------------------------------------------------------------
	
	# =======================================================================================
	print_status "Enabling fail2ban services..."
	# =======================================================================================
	read -p "Would you like to install fail2ban (basic intrusion detection)? " choice
	case "$choice" in
		y|Y ) apt-get install -y fail2ban
		systemctl enable fail2ban
		systemctl start fail2ban;;
		* ) echo "skipped";;
	esac;;
	# ---------------------------------------------------------------------------------------
	* ) echo "skipped";;
esac
# ---------------------------------------------------------------------------------------

# =======================================================================================
print_status "Installing the Nodium Masternode..."
# =======================================================================================
echo "Please enter the Masternode Alias that you copied from your wallet earlier"
while read masternodealias && [ -z "$masternodealias" ]; do :; done
echo "Please enter the Masternode Private Key that you copied from your wallet earlier"
while read masternodeprivkey && [ -z "$masternodeprivkey" ]; do :; done
echo "Please enter the Stake Output txid that you copied from your wallet earlier"
while read collateral_output_txid && [ -z "$collateral_output_txid" ]; do :; done
echo "Please enter the Stake Output txid Index that you copied from your wallet earlier"
while read collateral_output_index && [ -z "$collateral_output_index" ]; do :; done

echo "#########################"
echo "Masternode Alias: $masternodealias"
echo "Public IP: $publicip"
echo "Masternode Private Key: $masternodeprivkey"
echo "Collateral Output txid: $collateral_output_txid"
echo "Collateral Output txid index: $collateral_output_index"
echo "RPC User: $rpcuser"
echo "RPC Password: $rpcpassword"
echo "#########################"
echo ""
read -n 1 -s -r -p "You will need this RPC User and RPC Password to enter into the Wallet on your main computer per step 12 of the install instructions.  Press any key to continue once you have completed step 12..."

# ---------------------------------------------------------------------------------------

# =======================================================================================
# Enable and start the docker service
# =======================================================================================
systemctl enable docker
systemctl start docker
print_status "Creating the docker mount directories..."
mkdir -p /mnt/nodium/{config,data}
# ---------------------------------------------------------------------------------------

# =======================================================================================
# Create nodiumd configuration
# =======================================================================================
print_status "Creating the Nodium configuration..."
cat <<EOF > /mnt/nodium/config/nodium.conf
rpcuser=$rpcuser
rpcpassword=$rpcpassword
rpcallowip=127.0.0.1
listen=1
server=1
daemon=0 #Docker doesnt run as daemon
logtimestamps=1
maxconnections=256
masternode=1
externalip=$publicip
bind=$publicip:17652
masternodeaddr=$publicip
masternodeprivkey=$masternodeprivkey
EOF
# ---------------------------------------------------------------------------------------

# =======================================================================================
print_status "Creating the Nodium Masternode configuration..."
# =======================================================================================
echo >> "$masternodealias $publicip:17652 $masternodeprivkey $collateral_output_txid $collateral_output_index"
# ---------------------------------------------------------------------------------------

# =======================================================================================
print_status "Installing Nodium Maternode service..."
# =======================================================================================
cat <<EOF > /etc/systemd/system/nodiumd.service
[Unit]
Description=Nodium Masternode Container
After=docker.service
Requires=docker.service

[Service]
TimeoutStartSec=10m
Restart=always
ExecStartPre=-/usr/bin/docker stop nodiumd
ExecStartPre=-/usr/bin/docker rm  nodiumd
ExecStartPre=/usr/bin/docker pull greerso/nodiumd:latest
ExecStart=/usr/bin/docker run --rm --net=host -p 17652:17652 -v /mnt/nodium:/mnt/nodium --name nodiumd greerso/nodiumd:latest
[Install]
WantedBy=multi-user.target
EOF

print_status "Enabling and starting container service (please be patient...)"
systemctl daemon-reload
systemctl enable nodiumd
until systemctl restart nodiumd
do
  echo ".."
  sleep 30
done

# ---------------------------------------------------------------------------------------

# =======================================================================================
# "Install nodium aliases"
# =======================================================================================
echo 'alias nodium-cli="docker_alias greerso/nodiumd nodium /usr/local/bin/nodium-cli"' >> /etc/environment
. /etc/environment
# ---------------------------------------------------------------------------------------

# =======================================================================================
print_status "Install Finished"
# =======================================================================================
# ---------------------------------------------------------------------------------------
