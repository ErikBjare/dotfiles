#!/bin/bash

# In-progress script for making sure all savegames are synced (because Steam Sync isn't a catch-all, which is sad)
# Might be rewritten in Python later


# Directories of interest:
#   - `~/Documents/My Games/`, this is where games run in Wine/PlayOnLinux usually place their saves
#   - `~/.local/share/Steam/steamapps/common/Kerbal\ Space\ Program/saves/`, some programs do naughty things and put their saves
#       in their local assets, dangerous case since it is easy to remove the program folder and not realize the saves are stored there.
#   - ``, lalala
#   - More?
#


function for_directory() {
    # echo "Checking '$1'"
    if [ -d "$1" ]; then
        echo "Found: '$1'"
    else
        echo "Not found: '$1'"
    fi
}

LOCALSHARE="$HOME/.local/share"
STEAM="$LOCALSHARE/Steam"

for_directory "$HOME/Documents/My Games"
for_directory "$STEAM/steamapps/common/Kerbal Space Program/saves"
for_directory "$LOCALSHARE/openmw/saves"
for_directory "$LOCALSHARE/willnotbefound"
