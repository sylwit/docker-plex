FROM ubuntu:16.04
MAINTAINER Tim Haak <tim@haak.co>

ENV DEBIAN_FRONTEND="noninteractive" \
    TERM="xterm"

RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup &&\
    echo "Acquire::http {No-Cache=True;};" > /etc/apt/apt.conf.d/no-cache && \
    apt-get -q update && \
    apt-get -qy dist-upgrade && \
    apt-get install -qy \
      iproute2 \
      ca-certificates \
      ffmpeg \
      jq \
      openssl \
      xmlstarlet \
      curl \
      sudo \
      wget \
    && \
    apt-get -y autoremove && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*

ARG PLEX_PASS='false'

ENV PLEX_URL="https://plex.tv/api/downloads/1.json" \
    PLEX_PASS_URL="https://plex.tv/api/downloads/1.json?channel=plexpass"

    RUN if [ "${PLEX_PASS}" = "true" ]; then PLEX_URL=${PLEX_PASS_URL}; fi && \
    PLEX_JSON=$(curl -s $PLEX_URL | jq -r '.computer.Linux.releases[] | select(.build=="linux-ubuntu-x86_64" and .distro=="ubuntu") | .') && \
    PLEX_DOWNLOAD=$(echo $PLEX_JSON | jq -r '.url') && \
    PLEX_CHECKSUM=$(echo $PLEX_JSON | jq -r '.checksum') && \
    wget -O plex_server.deb $PLEX_DOWNLOAD && \
    echo "$PLEX_CHECKSUM *plex_server.deb" | sha1sum -c - && \
    dpkg -i plex_server.deb && \
    rm plex_server.deb && \
    apt-get -y autoremove && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*

VOLUME ["/config","/data"]

ENV RUN_AS_ROOT="true" \
    CHANGE_DIR_RIGHTS="false" \
    CHANGE_CONFIG_DIR_OWNERSHIP="true" \
    HOME="/config" \
    PLEX_DISABLE_SECURITY=1

EXPOSE 32400

ADD ./Preferences.xml /Preferences.xml
ADD ./start.sh /start.sh

CMD ["/start.sh"]
