#!/bin/bash
set -x
GROUP=plextmp

mkdir -p /config/logs/supervisor

touch /supervisord.log
touch /supervisord.pid
chown plex: /supervisord.log /supervisord.pid

# Get the proper group membership, credit to http://stackoverflow.com/a/28596874/249107

TARGET_GID=$(stat -c "%g" /data)
EXISTS=$(cat /etc/group | grep ${TARGET_GID} | wc -l)

# Create new group using target GID and add plex user
if [ $EXISTS = "0" ]; then
  groupadd --gid ${TARGET_GID} ${GROUP}
else
  # GID exists, find group name and add
  GROUP=$(getent group $TARGET_GID | cut -d: -f1)
  usermod -a -G ${GROUP} plex
fi

usermod -a -G ${GROUP} plex

if [[ -n "${SKIP_CHOWN_CONFIG}" ]]; then
  CHANGE_CONFIG_DIR_OWNERSHIP=false
fi

if [ "${CHANGE_CONFIG_DIR_OWNERSHIP,,}" = "true" ]; then
  find /config ! -user plex -print0 | xargs -0 -I{} chown -R plex: {}
fi

# Will change all files in directory to be readable by group
if [ "${CHANGE_DIR_RIGHTS,,}" = "true" ]; then
  chgrp -R ${GROUP} /data
  chmod -R g+rX /data
fi


if [ ! -f /config/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml ]; then
  mkdir -p /config/Library/Application\ Support/Plex\ Media\ Server/
  cp /Preferences.xml /config/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml
fi

# Get plex token if PLEX_USERNAME and PLEX_PASSWORD are defined
# If not set, you will have to link your account to the Plex Media Server in Settings > Server
[ "${PLEX_USERNAME}" ] && [ "${PLEX_PASSWORD}" ] && {

  if [ -n "$(xmlstarlet sel -T -t -m "/Preferences" -v "@PlexOnlineToken" -n /config/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml)" ]; then
  # Ask Plex.tv a token key
  PLEX_TOKEN=$(curl -u "${PLEX_USERNAME}":"${PLEX_PASSWORD}" 'https://plex.tv/users/sign_in.xml' \
    -X POST -H 'X-Plex-Device-Name: PlexMediaServer' \
    -H 'X-Plex-Provides: server' \
    -H 'X-Plex-Version: 0.9' \
    -H 'X-Plex-Platform-Version: 0.9' \
    -H 'X-Plex-Platform: xcid' \
    -H 'X-Plex-Product: Plex Media Server'\
    -H 'X-Plex-Device: Linux'\
    -H 'X-Plex-Client-Identifier: XXXX' --compressed | sed -n 's/.*<authentication-token>\(.*\)<\/authentication-token>.*/\1/p')
  fi
}

function setConfig(){
  if [ -z "$(xmlstarlet sel -T -t -m "/Preferences" -v "@$1" -n /config/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml)" ]; then
    xmlstarlet ed --inplace --insert "Preferences" --type attr -n $1 -v $2 /config/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml
  else
    xmlstarlet ed --inplace --update "Preferences" -x $1 -v $2 /config/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml
  fi
}

if [ "${PLEX_TOKEN}" ]; then
  setConfig PlexOnlineToken ${PLEX_TOKEN}
fi

# Tells Plex the external port is not "32400" but something else.
# Useful if you run multiple Plex instances on the same IP
if [ "${PLEX_EXTERNALPORT}" ]; then
  setConfig ManualPortMappingPort ${PLEX_EXTERNALPORT}
fi

# Allow disabling the remote security (hidding the Server tab in Settings)
if [ "${PLEX_DISABLE_SECURITY}" ]; then
  setConfig disableRemoteSecurity ${PLEX_DISABLE_SECURITY}
fi

# Detect networks and add them to the allowed list of networks
PLEX_ALLOWED_NETWORKS=${PLEX_ALLOWED_NETWORKS:-$(ip route | grep "/" | awk '{print $1}' | paste -sd "," -)}
if [ -n "${PLEX_ALLOWED_NETWORKS}" ]; then
  setConfig allowedNetworks ${PLEX_ALLOWED_NETWORKS}
fi

#remove previous pid if it exists
rm ~/Library/Application\ Support/Plex\ Media\ Server/plexmediaserver.pid

# Current defaults to run as root while testing.
if [ "${RUN_AS_ROOT,,}" = "true" ]; then
  /usr/sbin/start_pms
else
  sudo -u plex -E sh -c "/usr/sbin/start_pms"
fi
