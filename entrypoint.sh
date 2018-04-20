#!/bin/bash
set -e

# Add local user
# Either use the LOCAL_USER_ID if passed in at runtime or
# fallback
USER_ID=${LOCAL_USER_ID:-9001}
GRP_ID=${LOCAL_GRP_ID:-9001}

getent group bhash > /dev/null 2>&1 || groupadd -g $GRP_ID bhash
id -u bhash > /dev/null 2>&1 || useradd --shell /bin/bash -u $USER_ID -g $GRP_ID -o -c "" -m bhash

LOCAL_UID=$(id -u bhash)
LOCAL_GID=$(getent group bhash | cut -d ":" -f 3)

if [ ! "$USER_ID" == "$LOCAL_UID" ] || [ ! "$GRP_ID" == "$LOCAL_GID" ]; then
    echo "Warning: User with differing UID "$LOCAL_UID"/GID "$LOCAL_GID" already exists, most likely this container was started before with a different UID/GID. Re-create it to change UID/GID."
fi

echo "Starting with UID/GID : "$(id -u bhash)"/"$(getent group bhash | cut -d ":" -f 3)

export HOME=/home/bhash

# Must have a bhash config file
if [ ! -f "/mnt/bhash/config/bhash.conf" ]; then
  echo "No config found. Exiting."
  exit 1
else
  if [ ! -L $HOME/.bhash ]; then
    ln -s /mnt/bhash/config $HOME/.bhash.conf > /dev/null 2>&1 || true
  fi
fi

# data folder can be an external volume or created locally
if [ ! -d "/mnt/bhash/data" ]; then
  echo "Using local data folder"
  mkdir -p /mnt/bhash/data > /dev/null 2>&1 || true
else
  echo "Using external data volume"
fi

# Fix ownership of the created files/folders
chown -R bhash:bhash /home/bhash /mnt/bhash

# /usr/local/bin/gosu bhash bhash-fetch-params

# echo "Starting $@ .."
# if [[ "$1" == bhash ]]; then
#     exec /usr/local/bin/gosu bhash /bin/bash -c "$@ $OPTS"
# fi

exec /usr/local/bin/gosu bhashd "$@"