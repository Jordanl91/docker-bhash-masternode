FROM ubuntu:17.10
ENV VERSION=v1.0.0

# =======================================================================================
# Silence apt
# =======================================================================================
RUN export DEBIAN_FRONTEND=noninteractive \
# ---------------------------------------------------------------------------------------


# =======================================================================================
# Add bhash user
# =======================================================================================
&& useradd -m bhash \
# ---------------------------------------------------------------------------------------

# =======================================================================================
# Add Bitcoin apt-get repo and update
# =======================================================================================
&& apt-get update \
&& apt-get -y upgrade \
&& apt-get -y dist-upgrade \
&& apt-get install -y build-essential software-properties-common python-software-properties libtool git jq nano wget curl autoconf pkg-config \
&& add-apt-repository -y ppa:bitcoin/bitcoin \
&& apt-get update \
&& apt-get -y upgrade \
&& apt-get install -y autotools-dev libssl-dev software-properties-common libboost-all-dev libzmq3-dev libminiupnpc-dev libevent-dev libdb4.8-dev libdb4.8++-dev \
# ---------------------------------------------------------------------------------------

# =======================================================================================
# Install gosu utility
# =======================================================================================
&& dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
&& gosuURL="$(curl -s https://api.github.com/repos/tianon/gosu/releases | grep browser_download_url | head -n 1 | cut -d '' -f 4 | sed 's:/[^/]*$::')" \
# && gosuURL=$(curl -s https://api.github.com/repos/tianon/gosu/releases/latest | jq -r ".assets[] | select(.name | test(\"${dpkgArch}\")) | .browser_download_url") \
&& curl -o /usr/local/bin/gosu -SL "$gosuURL/gosu-$dpkgArch" \
&& curl -o /usr/local/bin/gosu.asc -SL "$gosuURL/gosu-$dpkgArch.asc" \
&& export GNUPGHOME="$(mktemp -d)" \
&& gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
&& rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
&& chmod +x /usr/local/bin/gosu \
&& gosu nobody true \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/* \
# ---------------------------------------------------------------------------------------

# =======================================================================================
# Install bhash
# =======================================================================================
&& bhashOS=linux \
&& bhashURL=$(curl -s https://api.github.com/repos/bhashcoin/bhash/releases/latest | jq -r ".assets[] | select(.name | test(\"${bhashOS}\")) | .browser_download_url") \
&& curl -sSL $bhashURL | tar xvz -C /usr/local/bin/
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
