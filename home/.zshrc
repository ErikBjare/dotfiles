# Uncomment this line and the last line in the file to time performance
#zmodload zsh/zprof

# Set up profile
if [ -f ~/.profile ]; then
    . ~/.profile
fi

# My shell aliases
if [ -f ~/.aliases ]; then
    . ~/.aliases
fi

# Load up antigen
source ~/.antigenrc.sh

# Use vi mode
# Taken from http://dougblack.io/words/zsh-vi-mode.html
#bindkey -v

export KEYTIMEOUT=1

# bind UP and DOWN arrow keys
zmodload zsh/terminfo
bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey "$terminfo[kcud1]" history-substring-search-down
bindkey "^[[A" history-substring-search-up
bindkey "^[[B" history-substring-search-down

# bind Alt+Left and Alt+Right, works in my current setup
#
# Why OC and OD works and "^[^[[C" & "^[^[[D" doesn't I do not know
#
# Not compatible with vi mode since Alt+Right sends same key
# as Esc+Right, which enters vi-mode

#>bindkey "OD" backward-word
#>bindkey "OC" forward-word

# bind Ctrl+Alt+Left and Ctrl+Alt+Right

#>bindkey "[D" backward-word
#>bindkey "[C" forward-word

# Use powerline theme if available
if hash powerline 2>/dev/null; then
    # Override theme
    source ~/.zsh/agnoster-modified.zsh-theme;
fi

# Set dircolors if under Linux (where dircolors is available)
if [[ "$(uname)" == "Linux" ]]; then
    # Solarized dircolors
    eval `dircolors $HOME/.dircolors-solarized/dircolors.256dark`
fi

# Uncomment this line and line 2 in the file to time performance
#zprof

# added by travis gem
[ -f /home/erb/.travis/travis.sh ] && source /home/erb/.travis/travis.sh

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
