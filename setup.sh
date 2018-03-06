#!/bin/bash

REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Helper functions used for coloring output
CLEAR="\e[0m"
BOLD="\e[0;01m"
RED="\e[0;31m"
GREEN="\e[0;32m"
YELLOW="\e[0;33m"
echo_red()    { echo -e    "${RED}${1}${CLEAR}"; }
echo_green()  { echo -e  "${GREEN}${1}${CLEAR}"; }
echo_yellow() { echo -e "${YELLOW}${1}${CLEAR}"; }
echo_bold()   { echo -e   "${BOLD}${1}${CLEAR}"; }

submodules () {
    git submodule update --init --recursive;
    echo_green "Submodules initalized and updated!"
}

symlinks () {
    ##########
    # This function is based on a blogpost by Michael Smalley
    # http://blog.smalleycreative.com/tutorials/using-git-and-github-to-manage-your-dotfiles/
    #
    # This function creates symlinks for all files/dirs in the ./home directory to ~/ and backs up any files/dirs that collide to ./backup
    #
    # Modifications by Erik Bjäreholt (github.com/ErikBjare)
    #  - Made so that it automatically symlinks all files/dirs in ./home
    #  - Improved output and added color
    # Modifications by Johan Bjäreholt (github.com/johan-bjareholt)
    ##########

    # Variables
    dir=$REPO_DIR/home                    # files will symlink to ~/
    backup=$REPO_DIR/backup               # old dotfiles backup directory

    # files="zshrc config/awesome oh-my-zsh Xdefaults vimrc xmonad"   # list of files/folders to symlink in homedir
    files=$( cd $dir && find ./ -maxdepth 1 -mindepth 1 )

    # create dotfiles_old in homedir
    # echo "Creating $backup for backup of any existing dotfiles"
    mkdir -p $backup
    # echo "...done"

    # change to the dotfiles directory
    # echo "Changing to the $dir directory"
    cd $dir
    # echo "...done"

    # move any existing dotfiles (excluding symlinks) in homedir to dotfiles_old directory, then create symlinks

    for file in $files; do
        if [ -e ~/$file ]; then
            if [ ! -h ~/$file ]; then
                echo_red "Collision: Moving existing ~/${file:2} to $backup"
                mv ~/$file $backup
            else
                echo_yellow "Symlink already existed at ~/${file:2}"
            fi
        fi
        if [ ! -h ~/$file ]; then
            echo_green "Creating symlink to ${file:2}"
            ln -si $dir/$file ~/$file
        fi
    done

    cd $REPO_DIR

    # Set certain permissions on the folders leading down to .ssh to prevent SSH issues
    chmod 744 .
    chmod 744 home
    chmod 744 home/.ssh
    chmod 600 home/.ssh/authorized_keys
}

fortunes() {
    cd $REPO_DIR/home/.fortunes
    ./generate-dat.sh 1>&/dev/null
    cd $REPO_DIR
    echo_green "Generated fortune .dat files!"
}

youcompleteme() {
    cd home/.vim/bundle/YouCompleteMe
    git checkout master
    git submodule update --init --recursive
    ./install.py --clang-completer --racer-completer --tern-completer --gocode-completer
    cd $REPO_DIR
}

echo_bold "Welcome to my dotfiles setup script!"

SECTIONS=(submodules symlinks fortunes youcompleteme)

for section in "${SECTIONS[@]}"; do
    echo -ne "Would you like to setup $section? (${GREEN}y${CLEAR}/${RED}n${CLEAR}): "
    read prompt
    if [ $prompt = y ]; then
        `echo $section`
    fi
done

echo_green "Done!"
