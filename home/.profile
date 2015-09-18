####################
#  Initialization  #
####################

# Log to file
logfile="$HOME/.profile-log.txt"
echo "Starting log: $(date --rfc-3339=seconds)" >> $logfile


############################
#  Set up the environment  #
############################

export DEFAULT_USER="erb"
export BROWSER="google-chrome"
export EDITOR="vim"
export TERM="xterm-256color"
export GPGKEY="86E4C130"


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
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
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

# Set up java and the JDK
if [ -d "/usr/local/jdk1.7.0" ]; then
    export JAVA_HOME="/usr/local/jdk1.7.0"
elif [ -d "/usr/local/jdk1.6.0" ]; then
    export JAVA_HOME="/usr/local/jdk1.6.0"
else
    echo "WARNING: Could not find java" >> $logfile
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
