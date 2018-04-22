FROM ubuntu:16.04

ENV VERSION=v1.0.0

# =======================================================================================
# Add bhash user
# =======================================================================================
RUN useradd -m bhash \
# ---------------------------------------------------------------------------------------

# =======================================================================================
# Add Bitcoin Apt repo and update
# =======================================================================================
&& DEBIAN_FRONTEND=noninteractive add-apt-repository -y ppa:bitcoin/bitcoin \
&& DEBIAN_FRONTEND=noninteractive apt update \
&& DEBIAN_FRONTEND=noninteractive apt -y upgrade \
&& DEBIAN_FRONTEND=noninteractive apt -y dist-upgrade \
# ---------------------------------------------------------------------------------------

# =======================================================================================
# Add Bitcoin Apt repo and update
# =======================================================================================
&& DEBIAN_FRONTEND=noninteractive apt install -y \
build-essential libtool autotools-dev autoconf pkg-config libssl-dev software-properties-common nano libboost-all-dev libzmq3-dev libminiupnpc-dev libevent-dev libdb4.8-dev libdb4.8++-dev
&& DEBIAN_FRONTEND=noninteractive apt install -y git
# ---------------------------------------------------------------------------------------

# =======================================================================================
# Install gosu utility
# =======================================================================================
&& latestBaseurl="$(curl -s https://api.github.com/repos/tianon/gosu/releases | grep browser_download_url | head -n 1 | cut -d '' -f 4 | sed 's:/[^/]*$::')" \
&& dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
&& curl -o /usr/local/bin/gosu -SL "$latestBaseurl/gosu-$dpkgArch" \
&& curl -o /usr/local/bin/gosu.asc -SL "$latestBaseurl/gosu-$dpkgArch.asc" \
&& export GNUPGHOME="$(mktemp -d)" \
&& gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
&& rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
&& chmod +x /usr/local/bin/gosu \
&& gosu nobody true \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/*
# ---------------------------------------------------------------------------------------

# =======================================================================================
# Install bhash
# =======================================================================================
bhashOS=linux
bhashURL=$(curl -s https://api.github.com/repos/bhashcoin/bhash/releases/latest | jq -r ".assets[] | select(.name | test(\"${bhashOS}\")) | .browser_download_url")
curl -sSL $bhashURL | tar xvz -C /usr/local/bin/
# ---------------------------------------------------------------------------------------

# =======================================================================================
# Expose communication port
# =======================================================================================
#Default is 17652
EXPOSE 17652
# ---------------------------------------------------------------------------------------

# =======================================================================================
# Data directory
# =======================================================================================
# Data volumes, if you prefer mounting a host directory use "-v /path:/mnt/bhash" command line
# option (folder ownership will be changed to the same UID/GID as provided by the docker run command)
VOLUME ["/mnt/bhash"]
# ---------------------------------------------------------------------------------------

# =======================================================================================
# Data directory
# =======================================================================================
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
# ---------------------------------------------------------------------------------------

# =======================================================================================
# Launch bhash daemon
# =======================================================================================
CMD ["bhashd"]
# ---------------------------------------------------------------------------------------
