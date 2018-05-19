FROM ubuntu:16.04
ENV VERSION=v1.0.0

# =======================================================================================
# Add nodium user
# =======================================================================================
RUN useradd -m nodium \
# ---------------------------------------------------------------------------------------

# =======================================================================================
# Add Bitcoin apt-get repo and update
# =======================================================================================
	&& apt-get update \
	&& apt-get -y --no-install-recommends install \
	&& apt-utils \
	&& DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends install \
	&& ca-certificates \
	&& curl \
	&& gosu \
	&& wget \
	&& apt-transport-https \
	&& lsb-release \
	&& libgomp1 \
	&& build-essential \
	&& software-properties-common \
	&& python-software-properties \
	&& libtool \
	&& git \
	&& jq \
	&& nano \
	&& autoconf \
	&& pkg-config \
	&& add-apt-repository -y ppa:bitcoin/bitcoin \
	&& apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends install \
	&& autotools-dev \
	&& libssl-dev \
	&& software-properties-common \
	&& libboost-all-dev \
	&& libzmq3-dev \
	&& libminiupnpc-dev \
	&& libevent-dev \
	&& libdb4.8-dev \
	&& libdb4.8++-dev \
	&& rm -rf /var/lib/apt/lists/*
# ---------------------------------------------------------------------------------------

# =======================================================================================
# Install nodium
# =======================================================================================
RUN nodiumOS=linux \
	&& nodiumURL=$(curl -s https://github.com/nodiumproject/zNodium.git | jq -r ".assets[] | select(.name | test(\"${nodiumOS}\")) | .browser_download_url") \
	&& curl -sSL "$nodiumURL" | tar xvz -C /usr/local/bin/
# ---------------------------------------------------------------------------------------

# =======================================================================================
# Expose communication port
# =======================================================================================
#Default is 6250
EXPOSE 6250
# ---------------------------------------------------------------------------------------

# =======================================================================================
# Data directory
# =======================================================================================
# Data volumes, if you prefer mounting a host directory use "-v /path:/mnt/nodium" command line
# option (folder ownership will be changed to the same UID/GID as provided by the docker run command)
VOLUME ["/mnt/nodium"]
# ---------------------------------------------------------------------------------------

# =======================================================================================
# Data directory
# =======================================================================================
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
# ---------------------------------------------------------------------------------------

# =======================================================================================
# Launch nodium daemon
# =======================================================================================
CMD ["nodiumd"]
# ---------------------------------------------------------------------------------------
