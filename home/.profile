####################
#  Initialization  #
####################

# Log to file
logfile="$HOME/.$logfile"

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi



############################
#  Set up the environment  #
############################

export EDITOR="vim"
export TERM="xterm-256color"
export GPGKEY="86E4C130"

# tmux requires strange things to get 256-color and ncurses to play nicely.
# https://unix.stackexchange.com/questions/1045/getting-256-colors-to-work-in-tmux
# https://bbs.archlinux.org/viewtopic.php?pid=880348
alias tmux="TERM=xterm-256color tmux"


###########################
#   Setting up the PATH   #
###########################

# include user's private bin if it exists
if [ -d "$HOME/bin" ]; then
    export PATH="$HOME/bin:$PATH"
fi

# set up the go environment
which go >& /dev/null
if [ $? -eq 0 ]; then
    # get default GOROOT
    export GOROOT="$(go env | grep "GOROOT=\".*\"$" | grep "\".*"\" -o | sed 's/\"//g')"

    export GOGAE="$HOME/Applications/go_appengine"
    export GOPATH="$HOME/.go"

    export GOROOT="$GOROOT:$GOGAE/goroot"
    export PATH="$GOPATH/bin:$PATH"
    export PATH="$GOGAE:$PATH"
    echo $GOROOT >> $logfile
    echo "Did GO stuff" >> $logfile
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



#############
#  Aliases  #
#############

# Enable color support of ls and others
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Find process command
alias proc="ps -ef | grep"

# Alias for quick reloading of zsh
alias zsh-reload='source ~/.zshrc'

# Alias for making quick python-commands inline
alias pyc='python3 -c'

# Clipboard helper func
alias toclip='xclip -sel clipboard'

echo ".profile ran successfully" >> $logfile
