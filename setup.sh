#!/bin/bash

git submodule init
git submodule update

dotfiles () {
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
    cwd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    dir=$cwd/home                    # files will symlink to ~/
    backup=$cwd/backup               # old dotfiles backup directory

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
    RED="\e[0;31m"
    YELLOW="\e[0;33m"
    GREEN="\e[0;32m"

    for file in $files; do
        if [ -e ~/$file ]; then
            if [ ! -h ~/$file ]; then
                echo -e "${RED}Collision: Moving existing ~/${file:2} to $backup"
                mv ~/$file $backup
            else
                echo -e "${YELLOW}Symlink already existed at ~/${file:2}"
            fi
	fi
        if [ ! -h ~/$file ]; then
            echo -e "${GREEN}Creating symlink to ${file:2}"
            ln -si $dir/$file ~/$file
        fi
    done
    cd $cwd
}

echo Welcome to my linux config setup script!

for section in dotfiles; do
    echo -ne "Would you like to setup $section? (y/n): "
    read prompt
    if [ $prompt = y ]; then
        `echo $section`
    fi
done

NC="\e[0m"  # No color
echo -e "${NC}Done!"
