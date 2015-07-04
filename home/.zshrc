# Set up profile
if [ -f ~/.profile ]; then
    . ~/.profile
fi

# My shell aliases
if [ -f ~/.aliases ]; then
    . ~/.aliases
fi

# Set up crontab
. ~/.zsh/crontab-handling

# Load up antigen
source ~/.antigenrc.sh

# bind UP and DOWN arrow keys
zmodload zsh/terminfo
bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey "$terminfo[kcud1]" history-substring-search-down

if hash powerline 2>/dev/null; then
    # Override theme
    source ~/.zsh/agnoster-modified.zsh-theme;
else
    antigen bundle jdavis/zsh-files themes/jdavis
fi


if [[ "$(uname)" == "Linux" ]]; then
    # Solarized dircolors
    eval `dircolors $HOME/.dircolors-solarized/dircolors.256dark`
fi
