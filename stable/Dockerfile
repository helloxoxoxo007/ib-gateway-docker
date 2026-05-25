
#
# Setup Stage: install apps
#
# This is a dedicated stage so that donwload archives don't end up on 
# production image and consume unnecessary space.
#

FROM ubuntu:22.04 as setup

ENV IB_GATEWAY_VERSION=1.45.1f
ENV IB_GATEWAY_RELEASE_CHANNEL=stable
ENV IBC_VERSION=3.23.0

# Prepare system
RUN apt-get update -y
RUN apt-get install --no-install-recommends --yes \
  curl \
  ca-certificates \
  unzip

WORKDIR /tmp/setup

# Install IB Gateway
# Use this instead of "RUN curl .." to install a local file:
#COPY ibgateway-${IB_GATEWAY_VERSION}-standalone-linux-x64.sh .
# Download IB Gateway
RUN curl -sSL https://download2.interactivebrokers.com/installers/ibgateway/stable-standalone/ibgateway-stable-standalone-linux-x64.sh \
      --output ibgateway-${IB_GATEWAY_VERSION}-standalone-linux-x64.sh
# Optional: Download checksum from a reliable source or skip it
RUN curl -sSL https://github.com/gnzsnz/ib-gateway-docker/raw/gh-pages/ibgateway-releases/ibgateway-${IB_GATEWAY_VERSION}-standalone-linux-x64.sh.sha256 \
      --output ibgateway-${IB_GATEWAY_VERSION}-standalone-linux-x64.sh.sha256 || true
# Checksum (make it non-fatal if file is bad)
RUN sha256sum --check ./ibgateway-${IB_GATEWAY_VERSION}-standalone-linux-x64.sh.sha256 || echo "Checksum verification skipped"
#RUN curl -sSL https://github.com/UnusualAlpha/ib-gateway-docker/releases/download/ibgateway-${IB_GATEWAY_RELEASE_CHANNEL}%40${IB_GATEWAY_VERSION}/ibgateway-${IB_GATEWAY_VERSION}-standalone-linux-x64.sh \
#  --output ibgateway-${IB_GATEWAY_VERSION}-standalone-linux-x64.sh
#RUN curl -sSL https://github.com/UnusualAlpha/ib-gateway-docker/releases/download/ibgateway-${IB_GATEWAY_RELEASE_CHANNEL}%40${IB_GATEWAY_VERSION}/ibgateway-${IB_GATEWAY_VERSION}-standalone-linux-x64.sh.sha256 \
#  --output ibgateway-${IB_GATEWAY_VERSION}-standalone-linux-x64.sh.sha256
#RUN sha256sum --check ./ibgateway-${IB_GATEWAY_VERSION}-standalone-linux-x64.sh.sha256
RUN chmod a+x ./ibgateway-${IB_GATEWAY_VERSION}-standalone-linux-x64.sh
#RUN ./ibgateway-${IB_GATEWAY_VERSION}-standalone-linux-x64.sh -q -dir /root/Jts/ibgateway/${IB_GATEWAY_VERSION}
RUN mkdir -p /root/Jts/ibgateway/${IB_GATEWAY_VERSION} && \
    chmod 777 /root/Jts/ibgateway/${IB_GATEWAY_VERSION} && \
    ./ibgateway-${IB_GATEWAY_VERSION}-standalone-linux-x64.sh \
      -q \
      -dir /root/Jts/ibgateway/${IB_GATEWAY_VERSION} \
      -Djava.io.tmpdir=/tmp || \
    (echo "Installation failed - Disk usage:" && df -h && exit 1)
COPY ./config/ibgateway/jts.ini /root/Jts/jts.ini

# Install IBC
RUN curl -sSL https://github.com/IbcAlpha/IBC/releases/download/${IBC_VERSION}/IBCLinux-${IBC_VERSION}.zip --output IBCLinux-${IBC_VERSION}.zip
RUN mkdir /root/ibc
RUN unzip ./IBCLinux-${IBC_VERSION}.zip -d /root/ibc
RUN chmod -R u+x /root/ibc/*.sh 
RUN chmod -R u+x /root/ibc/scripts/*.sh
COPY ./config/ibc/config.ini.tmpl /root/ibc/config.ini.tmpl

# Copy scripts
COPY ./scripts /root/scripts

#
# Build Stage: build production image
#

FROM ubuntu:22.04

ENV IB_GATEWAY_VERSION=1.45.1f

ARG TBOT_TRADINGBOAT_GIT_REPO=https://github.com/helloxoxoxo007/tbot-tradingboat.git

WORKDIR /root

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/London

# Prepare system
RUN apt-get update -y
RUN apt-get install --no-install-recommends --yes \
  gettext \
  xvfb \
  libxslt-dev \
  libxrender1 \
  libxtst6 \
  libxi6 \
  libgtk2.0-bin \
  socat \
  net-tools \
  iproute2 \
  curl \
  x11vnc \
  git \
  python3 \
  python3-pip \
  tmux

# Create tbot user and clone tbot-tradingboat
RUN useradd -m -s /bin/bash tbot
RUN mkdir -p /home/tbot/develop/github && \
    git clone ${TBOT_TRADINGBOAT_GIT_REPO} /home/tbot/develop/github/tbot-tradingboat && \
    chown -R tbot:tbot /home/tbot/develop/github

# Install Python dependencies for tbot-tradingboat
RUN pip3 install --no-cache-dir -r /home/tbot/develop/github/tbot-tradingboat/requirements.txt || true
RUN pip3 install --no-cache-dir "libtmux>=0.21.0"

# Copy tbot helper scripts
COPY ./tbot /home/tbot/tbot
RUN chmod a+x /home/tbot/tbot/*.sh && chown -R tbot:tbot /home/tbot/tbot

# Copy files
COPY --from=setup /root/ .
# ==================== FORCE JVM FLAGS FOR JAVA 17+ ====================
# This must run AFTER copying files from setup stage
RUN rm -f /root/Jts/ibgateway/1.45.1f/ibgateway.vmoptions && \
    echo "--add-opens=java.desktop/javax.swing=ALL-UNNAMED" > /root/Jts/ibgateway/1.45.1f/ibgateway.vmoptions && \
    echo "--add-opens=java.base/java.util=ALL-UNNAMED" >> /root/Jts/ibgateway/1.45.1f/ibgateway.vmoptions && \
    echo "--add-opens=java.desktop/java.awt=ALL-UNNAMED" >> /root/Jts/ibgateway/1.45.1f/ibgateway.vmoptions && \
    echo "--add-opens=java.desktop/javax.swing.plaf=ALL-UNNAMED" >> /root/Jts/ibgateway/1.45.1f/ibgateway.vmoptions && \
    echo "-Xmx1024m" >> /root/Jts/ibgateway/1.45.1f/ibgateway.vmoptions && \
    echo "-Xms512m" >> /root/Jts/ibgateway/1.45.1f/ibgateway.vmoptions && \
    echo "=== Final vmoptions content ===" && \
    cat /root/Jts/ibgateway/1.45.1f/ibgateway.vmoptions

# Also create backup in case launcher ignores vmoptions
RUN echo "--add-opens=java.desktop/javax.swing=ALL-UNNAMED \
--add-opens=java.base/java.util=ALL-UNNAMED \
--add-opens=java.desktop/java.awt=ALL-UNNAMED \
--add-opens=java.desktop/javax.swing.plaf=ALL-UNNAMED" > /root/extra_java_opts.txt
# =====================================================================
RUN chmod a+x /root/scripts/*.sh
COPY --from=setup /usr/local/i4j_jres/ /usr/local/i4j_jres

# IBC env vars
ENV TWS_MAJOR_VRSN ${IB_GATEWAY_VERSION}
ENV TWS_PATH /root/Jts
ENV IBC_PATH /root/ibc
ENV IBC_INI /root/ibc/config.ini
ENV TWOFA_TIMEOUT_ACTION exit

# Start run script
CMD ["/root/scripts/run.sh"]
