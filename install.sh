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
# ---------------------------------------------------------------------------------------

# =======================================================================================
# Installation variables
# =======================================================================================
rpcpassword=$(head -c 32 /dev/urandom | base64)
bhashuserpw=$(head -c 32 /dev/urandom | base64)
publicip=$(dig +short myip.opendns.com @resolver1.opendns.com)
Hostname="$(cat /etc/hostname)"
# ---------------------------------------------------------------------------------------

# =======================================================================================
print_status "Name Your Server"
# =======================================================================================
read -p "Would you like to change your server hostname from $Hostname to something else? " choice
case "$choice" in 
  y|Y ) echo "Please enter server name: (Default: my.bhash.node)"
	newHostname=$(inputWithDefault my.bhash.node)
	sed -i "s|$Hostname|$newHostname|1" /etc/hostname
	if grep -q "$Hostname" /etc/hosts; then
	    sed -i "s|$Hostname|$newHostname|1" /etc/hosts
	else
	    echo "127.0.1.1 $newHostname" >> /etc/hosts
	fi
	hostname "$newHostname";;
	* ) echo "skipped";;
esac
clear
# ---------------------------------------------------------------------------------------


# =======================================================================================
print_status "Add a bhash user"
# =======================================================================================
read -p "Would you like to a bhash user? " choice
case "$choice" in 
  y|Y ) echo "Please enter the new user name: (Default bhash)"
	username=$(inputWithDefault bhash)
	echo "Please enter the password for '${username}': (Default $bhashuserpw)"
	echo "You will need to remember this password"
	userPassword=$(inputWithDefault $bhashuserpw)	
	adduser --gecos "" --disabled-password --quiet "$username"
	echo "$username:$userPassword" | chpasswd	
	# Add user to sudoers and docker
	adduser $username sudo docker;;
	* ) echo "skipped";;
esac
clear
# ---------------------------------------------------------------------------------------

# =======================================================================================
# Secure SSH
# =======================================================================================
# sshPort=$(cat /etc/ssh/sshd_config | grep Port | awk '{print $2}')
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
read -p "Would you like to install a basic firewall? " choice
case "$choice" in 
  y|Y ) apt install -y ufw
	ufw default allow outgoing
	ufw default deny incoming
	# Open ports for ssh and webapps
	ufw allow $sshPort/tcp comment 'ssh port'
	ufw allow 17652/tcp comment 'bhash daemon'	
	# Enable the firewall
	ufw enable;;
	* ) echo "skipped";;
esac
# ---------------------------------------------------------------------------------------

# =======================================================================================
print_status "Enabling fail2ban services..."
# =======================================================================================
read -p "Would you like to install a basic firewall? " choice
case "$choice" in
	y|Y ) apt install -y fail2ban
	systemctl enable fail2ban
	systemctl start fail2ban;;
	* ) echo "skipped";;
esac
# ---------------------------------------------------------------------------------------

# =======================================================================================
print_status "Installing the BHash Masternode..."
# =======================================================================================
echo "Please enter the Masternode Private Key that you generated earlier from your wallet console"
while read masternodeprivkey && [ -z "$masternodeprivkey" ]; do :; done
masternodeprivkey=$(inputWithDefault value)

echo "#########################"
echo "Public IP: $publicip"
echo "Masternode Private Key: $masternodeprivkey"
echo "RPC User: $rpcuser"
echo "RPC Password: $rpspassword"
echo "#########################"
# ---------------------------------------------------------------------------------------

# =======================================================================================
# Install required packages
# =======================================================================================
print_status "Installing packages required for setup..."
apt install -y docker.io \
	apt-transport-https \
	lsb-release \
	unattended-upgrades \
	wget curl htop jq \
	libzmq3-dev > /dev/null 2>&1
# ---------------------------------------------------------------------------------------

# =======================================================================================
# Enable and start the docker service
# =======================================================================================
systemctl enable docker
systemctl start docker
print_status "Creating the docker mount directories..."
mkdir -p /mnt/bhash/{config,data}
# ---------------------------------------------------------------------------------------

# =======================================================================================
# Create Masternode configuration
# =======================================================================================
print_status "Creating the BHash Masternode configuration."
cat <<EOF > /mnt/bhash/config/bhash.conf
rpcuser=long bhashuser
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
# ---------------------------------------------------------------------------------------

# =======================================================================================
print_status "Installing BHash Maternode service..."
# =======================================================================================
cat <<EOF > /etc/systemd/system/bhashd.service
[Unit]
Description=BHash Masternode Container
After=docker.service
Requires=docker.service

[Service]
TimeoutStartSec=10m
Restart=always
ExecStartPre=-/usr/bin/docker stop bhash
ExecStartPre=-/usr/bin/docker rm  bhash
ExecStartPre=/usr/bin/docker pull greerso/bhashd:latest
ExecStartPre=/usr/bin/docker build greerso/bhashd:latest
ExecStart=/usr/bin/docker run --rm --net=host -p 17652:17652 -v /mnt/bhash:/mnt/bhash --name bhash greerso/bhashd:latest
[Install]
WantedBy=multi-user.target
EOF

print_status "Enabling and starting container service..."
systemctl daemon-reload
systemctl enable bhash
systemctl restart bhash
clear
# ---------------------------------------------------------------------------------------

# =======================================================================================
# "Install bash aliases"
# =======================================================================================
bash -c "$(curl -sSL https://raw.githubusercontent.com/greerso/docker-bhash-masternode/master/docker-aliases.sh)"
# ---------------------------------------------------------------------------------------

# =======================================================================================
print_status "Install Finished"
# =======================================================================================
# ---------------------------------------------------------------------------------------
## TODO: Post the shield address back to our API