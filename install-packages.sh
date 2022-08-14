#!/usr/bin/bash

# TODO: Do all necessary add-apt-repository (for google-chrome)
# TODO: Fetch dpkg/alternative installers (for veracrypt)
# TODO: Fix Arch support

if (lsb_release -a | grep 'Arch Linux'); then
    echo 'Detected Arch Linux'

    TERMINAL="fish tmux alacritty powerline"
    BROWSERS="firefox okular"
    EDITORS="vim neovim"
    VCS="git"  # since this script is in git, we probably already have it, but still
    TOOLS="redshift zoxide git-delta github-cli dunst dex sshfs"
    MATH="octave"
    PYTHON="python ipython poetry pyenv"
    RUST="rustup"
    NODE="nodejs nvm"
    TEX="texlive-core"
    X11="xclip xorg-xkill"
    MISC="playerctl"

    ALL="$TERMINAL $BROWSERS $EDITORS $VCS $MATH $PYTHON $TEX $X11 $RUST $MISC"
    set -x
    sudo pacman --needed -S $ALL
    set +x

    # TODO: Check if yay is already installed
    read -p "Want to install yay? (y/N):  " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        # Install yay if not available
        TMP="$(mktemp -d --suffix='-yay')"
        git clone https://aur.archlinux.org/yay.git $TMP
        pushd $TMP
        makepkg -si
        popd
    fi

    read -p "Want to install AUR packages? (y/N):  " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        AUR_PACKAGES="spotify rbenv ruby-build escrotum-git"
        yay -S $AUR_PACKAGES
    fi
elif (lsb_release -a | grep 'Raspbian'); then
    echo 'Detected Raspbian'
    sudo apt install vim tmux fish git nodejs npm python3 python3-pip
else
    echo 'Detected Ubuntu'
    sudo add-apt-repository ppa:webupd8team/tor-browser
    sudo add-apt-repository ppa:neovim-ppa/unstable

    TERMINAL="fish tmux"
    BROWSERS="firefox tor-browser"
    EDITORS="vim neovim"
    VCS="mercurial git"
    TOOLS="redshift redshift-gtk"
    MATH="octave"
    PYTHON="python-dev python3-dev python3-pip ipython3 poetry"
    GPG="gnupg-curl"

    ALL="$TERMINAL $BROWSERS $EDITORS $VCS $MATH $PYTHON $GPG"

    sudo apt-get update
    sudo apt-get install $ALL
fi

read -p "Want to user-install Python packages? (y/N):  " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    PYTHON_PACKAGES="numpy scipy pandas matplotlib"
    pip install --upgrade --user $PYTHON_PACKAGES
    PYTHON_PACKAGES_DEV="virtualfish black jupyterlab wheel pytest mypy pyupgrade"
    pip install --upgrade --user $PYTHON_PACKAGES_DEV
    # After installation of virtualfish:
    #   vf install
    #   vf addplugins auto_activation
fi
