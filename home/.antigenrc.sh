#
# Antigen
#

# Load Antigen
source $HOME/.antigen/antigen.zsh

# Load various lib files
antigen bundle robbyrussell/oh-my-zsh lib/

# Antigen Theme
#antigen theme jdavis/zsh-files themes/jdavis

# History Substring Search
antigen bundle zsh-users/zsh-history-substring-search

# Antigen Bundles
antigen bundle git
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle rupa/z

# Python Plugins
antigen bundle pip
antigen bundle python
antigen bundle virtualenv

# OS specific plugins
if [[ $CURRENT_OS == 'OS X' ]]; then
    antigen bundle brew
    antigen bundle brew-cask
    antigen bundle gem
    antigen bundle osx
elif [[ $CURRENT_OS == 'Linux' ]]; then

    if [[ $DISTRO == 'CentOS' ]]; then
        antigen bundle centos
    fi
elif [[ $CURRENT_OS == 'Cygwin' ]]; then
    antigen bundle cygwin
fi
