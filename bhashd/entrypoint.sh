#!/bin/bash
set -e

# Add local user
# Either use the LOCAL_USER_ID if passed in at runtime or
# fallback
USER_ID=${LOCAL_USER_ID:-9001}
GRP_ID=${LOCAL_GRP_ID:-9001}

getent group nodium > /dev/null 2>&1 || groupadd -g $GRP_ID nodium
id -u nodium > /dev/null 2>&1 || useradd --shell /bin/bash -u $USER_ID -g $GRP_ID -o -c "" -m nodium

LOCAL_UID=$(id -u nodium)
LOCAL_GID=$(getent group nodium | cut -d ":" -f 3)

if [ ! "$USER_ID" == "$LOCAL_UID" ] || [ ! "$GRP_ID" == "$LOCAL_GID" ]; then
    echo "Warning: User with differing UID "$LOCAL_UID"/GID "$LOCAL_GID" already exists, most likely this container was started before with a different UID/GID. Re-create it to change UID/GID."
fi

echo "Starting with UID/GID : "$(id -u nodium)"/"$(getent group nodium | cut -d ":" -f 3)

export HOME=/home/nodium

# Must have a nodium config file
if [ ! -f "/mnt/nodium/config/nodium.conf" ]; then
  echo "No nodium.conf found in /mnt/nodium/config/. Exiting."
  exit 1
else
  if [ ! -L $HOME/.nodium/nodium.conf ]; then
    ln -s /mnt/nodium/config/nodium.conf $HOME/.nodium/nodium.conf > /dev/null 2>&1 || true
  fi
fi

# Must have a nodium masternode config file
if [ ! -f "/mnt/nodium/config/masternode.conf" ]; then
  echo "No masternode.conf found in /mnt/nodium/config/. Exiting."
  exit 1
else
  if [ ! -L $HOME/.nodium/masternode.conf ]; then
    ln -s /mnt/nodium/config/masternode.conf $HOME/.nodium/masternode.conf > /dev/null 2>&1 || true
  fi
fi

# data folder can be an external volume or created locally
if [ ! -d "/mnt/nodium/data" ]; then
  echo "Using local data folder"
  mkdir -p /mnt/nodium/data > /dev/null 2>&1 || true
else
  echo "Using external data volume"
fi

# Fix ownership of the created files/folders
chown -R nodium:nodium /home/nodium /mnt/nodium

echo "Starting $@ .."
 if [[ "$1" == nodiumd ]]; then
     exec gosu nodium /bin/bash -c "$@ $OPTS"
 fi

exec gosu nodium "$@"
