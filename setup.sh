#!/bin/sh

dotfiles () {
    ##########
    # This function is based on a blogpost by Michael Smalley
    # http://blog.smalleycreative.com/tutorials/using-git-and-github-to-manage-your-dotfiles/
    #
    # This function creates symlinks from the home directory to any desired dotfiles in ~/dotfiles
    #
    # Modifications by Erik Bjäreholt (github.com/ErikBjare) 
    # Modifications by Johan Bjäreholt (github.com/johan-bjareholt)
    ##########

    # Variables
    cwd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    dir=$cwd/home                    # files will symlink to ~/
    backup=$cwd/backup               # old dotfiles backup directory

    # files="zshrc config/awesome oh-my-zsh Xdefaults vimrc xmonad"   # list of files/folders to symlink in homedir
    files=$( cd $dir && find ./ -maxdepth 1 -mindepth 1 )

    # create dotfiles_old in homedir
    echo "Creating $backup for backup of any existing dotfiles"
    mkdir -p $backup
    echo "...done"

    # change to the dotfiles directory
    echo "Changing to the $dir directory"
    cd $dir
    echo "...done"

    # move any existing dotfiles (excluding symlinks) in homedir to dotfiles_old directory, then create symlinks
    for file in $files; do
        if [ -e ~/$file ]; then 
            if [ ! -h ~/$file ]; then
                echo "Collision: Moving existing ~/$file to $backup"
                mv ~/$file $backup
            else
                echo "Symlink ~/$file already existed"
            fi
	fi
        if [ ! -h ~/$file ]; then
            echo "Creating symlink to $file in home directory."
            ln -si $dir/$file ~/$file
        fi
    done
    cd $cwd
}

echo Welcome to my linux config setup script!

for section in dotfiles; do
    echo "Would you like to setup $section? (y/n): "
    read prompt
    echo
    if [ $prompt = y ]; then
        `echo $section`
    fi
done

echo "Done!"
