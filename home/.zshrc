# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
# ZSH_THEME="erb"

# Set DEFAULT_USER
export DEFAULT_USER="erb"

# My shell aliases
if [ -f ~/.aliases ]; then
    . ~/.aliases
fi

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(vagrant pass)

# Load up antigen
source ~/.antigenrc.sh

# bind UP and DOWN arrow keys
zmodload zsh/terminfo
bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey "$terminfo[kcud1]" history-substring-search-down

# Override theme
source ~/.zsh/agnoster-modified.zsh-theme

if [[ "$(uname)" == "Linux" ]]; then
    # Solarized dircolors
    eval `dircolors $HOME/.dircolors-solarized/dircolors.256dark`
fi
