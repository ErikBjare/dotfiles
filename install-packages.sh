# TODO: Do all necessary add-apt-repository (for google-chrome)
# TODO: Fetch dpkg/alternative installers (for veracrypt)

TERMINAL="zsh tmux"
BROWSERS="firefox"
EDITORS="vim"
VCS="mercurial git"
TOOLS="redshift redshift-gtk"
MATH="octave"
PYTHON="python-dev python3-dev python3-pip ipython3"
GPG="gnupg-curl"

ALL="$TERMINAL $BROWSERS $EDITORS $VCS $MATH $PYTHON $GPG"


sudo apt-get install $ALL
