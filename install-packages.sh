# TODO: Do all necessary add-apt-repository (for google-chrome)
# TODO: Fetch dpkg/alternative installers (for veracrypt)
# TODO: Fix Arch support

sudo add-apt-repository ppa:webupd8team/tor-browser
sudo add-apt-repository ppa:neovim-ppa/unstable

TERMINAL="zsh tmux"
BROWSERS="firefox tor-browser"
EDITORS="vim neovim"
VCS="mercurial git"
TOOLS="redshift redshift-gtk"
MATH="octave"
PYTHON="python-dev python3-dev python3-pip ipython3"
GPG="gnupg-curl"

ALL="$TERMINAL $BROWSERS $EDITORS $VCS $MATH $PYTHON $GPG"

sudo apt-get update
sudo apt-get install $ALL
