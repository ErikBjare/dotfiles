#!/usr/bin/env bash

# TODO: Do all necessary add-apt-repository (for google-chrome)
# TODO: Fetch dpkg/alternative installers (for veracrypt)

NOCONFIRM=${NOCONFIRM:-false}
if [ "$NOCONFIRM" = true ]; then
    echo 'NOCONFIRM is set, skipping confirmation'
fi

# function to ask for confirmation, or skip if NOCONFIRM is set
# returns 0 if confirmed, 1 if not
function ask() {
    if [ "$NOCONFIRM" = false ]; then
        read -p "$1 (y/N):  " -n 1 -r
        echo
    fi
    if [ "$NOCONFIRM" = true ] || [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# if macOS
if (uname | grep 'Darwin'); then
    echo 'Detected macOS'

    # if brew not installed
    if ! (which brew); then
        echo 'Installing Homebrew'
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi

    GNU_UTILS="coreutils gnu-sed grep moreutils findutils"
    BREW_PACKAGES="pyenv syncthing tmux neovim helix fish watch xz htop yt-dlp rustup rsync tree nmap pandoc ripgrep wget jq ncdu ruby graphviz gimp fzf"
    LIBS_PACKAGES="hdf5 c-blosc"
    GIT_PACKAGES="git git-delta git-annex rclone git-annex-remote-rclone git-lfs"
    BREW_CASK_PACKAGES="alacritty discord font-fira-code standard-notes zerotier-one visual-studio-code logseq koekeishiya/formulae/yabai"
    PIPX_PACKAGES="poetry powerline-status"

    ask "Want to install brew packages?"
    if [ $? -eq 0 ]; then
        brew install $GNU_UTILS $BREW_PACKAGES $GIT_PACKAGES $LIBS_PACKAGES
        brew install --cask $BREW_CASK_PACKAGES
    fi

    ask "Want to install pipx packages?"
    if [ $? -eq 0 ]; then
        for package in $PIPX_PACKAGES; do
            pipx install $package
        done
    fi
elif (lsb_release -a | grep 'Arch Linux'); then
    echo 'Detected Arch Linux'

    TERMINAL="fish tmux alacritty powerline"
    BROWSERS="firefox okular"
    EDITORS="vim neovim"
    VCS="git"  # since this script is in git, we probably already have it, but still
    TOOLS="redshift zoxide git-delta github-cli dunst dex sshfs tokei nmap fzf"
    MATH="octave"
    PYTHON="python ipython poetry pyenv"
    RUST="rustup"
    NODE="nodejs"
    TEX="texlive-core"
    X11="xclip xorg-xkill"
    MISC="playerctl age"

    ALL="$TERMINAL $BROWSERS $EDITORS $VCS $TOOLS $MATH $PYTHON $RUST $NODE $TEX $X11 $MISC"
    set -x
    sudo pacman --needed -S $ALL
    set +x

    # TODO: Check if yay is already installed
    ask "Want to install yay?"
    if [ $? -eq 0 ]; then
        # Install yay if not available
        TMP="$(mktemp -d --suffix='-yay')"
        git clone https://aur.archlinux.org/yay.git $TMP
        pushd $TMP
        makepkg -si
        popd
    fi

    ask "Want to install AUR packages?"
    if [ $? -eq 0 ]; then
        AUR_PACKAGES="spotify rbenv ruby-build escrotum-git nvm"
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
    TOOLS="redshift redshift-gtk fzf"
    MATH="octave"
    PYTHON="python-dev python3-dev python3-pip ipython3 poetry"
    GPG="gnupg-curl"

    ALL="$TERMINAL $BROWSERS $EDITORS $VCS $MATH $PYTHON $GPG"

    sudo apt-get update
    sudo apt-get install $ALL
fi
echo 'Done with OS-specific setup'
echo

ask "Want to user-install Python packages?"
if [ $? -eq 0 ]; then
    PYTHON_PACKAGES="numpy scipy pandas matplotlib powerline-status"
    pip install --upgrade --user $PYTHON_PACKAGES
    PYTHON_PACKAGES_DEV="virtualfish jupyterlab wheel pytest"
    PYTHON_PACKAGES_LINT="black bandit flake8 mypy pyupgrade"
    pip install --upgrade --user $PYTHON_PACKAGES_DEV

    echo "! After installation of virtualfish, do:"
    echo "!   vf install"
    echo "!   vf addplugins auto_activation"
fi
