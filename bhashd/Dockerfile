FROM ubuntu:17.10
ENV VERSION=v1.0.0

# =======================================================================================
# Add bhash user
# =======================================================================================
RUN useradd -m bhash \
# ---------------------------------------------------------------------------------------

# =======================================================================================
# Add Bitcoin apt-get repo and update
# =======================================================================================
	&& apt-get update \
	&& apt-get -y upgrade \
	&& apt-get -y --no-install-recommends install apt-utils \
	&& DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends install ca-certificates curl wget apt-transport-https lsb-release libgomp1 build-essential software-properties-common python-software-properties libtool git jq nano autoconf pkg-config \
	&& apt-get -y dist-upgrade \
	&& add-apt-repository -y ppa:bitcoin/bitcoin \
	&& apt-get update \
	&& apt-get -y upgrade \
	&& DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends install autotools-dev libssl-dev software-properties-common libboost-all-dev libzmq3-dev libminiupnpc-dev libevent-dev libdb4.8-dev libdb4.8++-dev \
	&& apt-get autoremove \
# ---------------------------------------------------------------------------------------

# =======================================================================================
# Install gosu utility
# =======================================================================================
#	&& gosuURL=$(curl -s https://api.github.com/repos/tianon/gosu/releases | grep browser_download_url | head -n 1 | cut -d '"' -f 4 | sed 's:/[^/]*$::') \
#	&& dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
#	&& curl -o /usr/local/bin/gosu -SL "$gosuURL/gosu-$dpkgArch" \
#	&& curl -o /usr/local/bin/gosu.asc -SL "$gosuURL/gosu-$dpkgArch.asc" \
#	&& export GNUPGHOME="$(mktemp -d)" \
#	&& gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
#	&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
#	&& rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
#	&& chmod +x /usr/local/bin/gosu \
#	&& gosu nobody true \
#	&& apt-get clean \
#	&& rm -rf /var/lib/apt/lists/* \
	# Dependencies for both C++ and Ruby
	&& DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends libsdl2-dev libsdl2-ttf-dev libpango1.0-dev libgl1-mesa-dev libopenal-dev libsndfile-dev libmpg123-dev libgmp-dev \
	&& DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends ruby-dev \
	&& gem install gosu \


# ---------------------------------------------------------------------------------------

# =======================================================================================
# Install bhash
# =======================================================================================
	&& bhashOS=linux \
	&& bhashURL=$(curl -s https://api.github.com/repos/bhashcoin/bhash/releases/latest | jq -r ".assets[] | select(.name | test(\"${bhashOS}\")) | .browser_download_url") \
	&& curl -sSL "$bhashURL" | tar xvz -C /usr/local/bin/
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
