#!/bin/bash

####################
#  Initialization  #
####################

# Log to file
logfile="$HOME/.profile-log.txt"

# The following doesn't work due to the date command on OS X (doesn't have --rfc-3339 support)
if [[ `uname` != 'Darwin' ]]; then
    echo "Starting log: $(date --rfc-3339=seconds)" >> $logfile
fi


############################
#  Set up the environment  #
############################

export DEFAULT_USER="erb"
export BROWSER="google-chrome"
export EDITOR="vim"
export VISUAL="vim"
export GPGKEY="86E4C130"
export TZ="Europe/Stockholm"
export DISPLAY=":0"

# Needed on OS X for pbcopy etc.
# Done generally if not already set just in case
if [[ -z $LANG ]]; then
    export LANG="en_US.UTF-8"
fi

# Apparently you should never set term... Who knew?
# https://wiki.archlinux.org/index.php/Home_and_End_keys_not_working
#export TERM="xterm-256color"

###########################
#   Setting up the PATH   #
###########################

# include user's private bin-folders if any of them exists
if [ -d "$HOME/bin" ]; then
    export PATH="$HOME/bin:$PATH"
fi
if [ -d "$HOME/.bin" ]; then
    export PATH="$HOME/.bin:$PATH"
fi

# bin folder used by Python for user installs
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# bin folder used by Cabal (Haskell) for user installs
if [ -d "$HOME/.cabal/bin" ]; then
    export PATH="$HOME/.cabal/bin:$PATH"
fi

# user bin folder used by Cargo (Rust)
if [ -d "$HOME/.cargo/bin" ]; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# set up the go environment
if hash go 2>/dev/null; then
    # get default GOROOT
    export GOROOT="$(go env | grep "GOROOT=\".*\"$" | grep "\".*"\" -o | sed 's/\"//g')"

    export GOGAE="$HOME/Applications/go_appengine"
    export GOPATH="$HOME/.go"

    export PATH="$GOPATH/bin:$PATH"
    export PATH="$GOGAE:$PATH"
fi

# Set up Java and the JDK
if [[ `uname` == 'Darwin' ]]; then
    export JAVA_HOME=$(/usr/libexec/java_home)
else
    if [ -d "/usr/local/jdk1.8.0" ]; then
        export JAVA_HOME="/usr/local/jdk1.8.0"
    elif [ -d "/usr/local/jdk1.7.0" ]; then
        export JAVA_HOME="/usr/local/jdk1.7.0"
    elif [ -d "/usr/local/jdk1.6.0" ]; then
        export JAVA_HOME="/usr/local/jdk1.6.0"
    else
        echo "WARNING: Could not find java" >> $logfile
    fi
fi
export PATH="$JAVA_HOME/bin:$PATH"


###########################
#        Finish up        #
###########################

# Import PATH to systemd
if hash systemctl 2>/dev/null; then
    systemctl --user import-environment PATH;
fi

echo ".profile ran successfully" >> $logfile

export NVM_DIR="/home/erb/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm

export NVS_HOME="$HOME/.nvs"
[ -s "$NVS_HOME/nvs.sh" ] && . "$NVS_HOME/nvs.sh"
