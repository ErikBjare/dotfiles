#!/bin/bash
# WARNING: Script assumes that the archive only contains the executable

SYNCTHING_INOTIFY_ARCHIVE="https://github.com/syncthing/syncthing-inotify/releases/download/v0.6.7/syncthing-inotify-linux-amd64-v0.6.7.tar.gz"
TMP_ARCHIVE_NAME="syncthing-inotify.tar.gz"

cd /tmp
wget $SYNCTHING_INOTIFY_ARCHIVE -O $TMP_ARCHIVE_NAME
sudo tar xvf $TMP_ARCHIVE_NAME -C /usr/bin

SYSTEMD_SERVICE_FILE_URL="https://raw.githubusercontent.com/syncthing/syncthing-inotify/master/etc/linux-systemd/user/syncthing-inotify.service"

curl $SYSTEMD_SERVICE_FILE_URL | sudo tee /usr/lib/systemd/user/syncthing-inotify.service >> /dev/null
