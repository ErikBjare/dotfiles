# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
# ZSH_THEME="erb"

# Set DEFAULT_USER
export DEFAULT_USER="erb"

# My shell aliases
if [ -f ~/.shell_aliases ]; then
    . ~/.shell_aliases
fi

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(git vagrant python pip npm cabal)

# Load oh-my-zsh
source $ZSH/oh-my-zsh.sh

# Override theme
source ~/.zsh/agnoster-modified.zsh-theme
