dotfiles
========

[![Build Status](https://travis-ci.org/ErikBjare/dotfiles.svg)](https://travis-ci.org/ErikBjare/dotfiles)

Just my dotfiles and a nice script for managing them, based on a previously private home repo.

> *Look again at that dot. That's here. That's home. That's us.*  
> \- Carl Sagan


## Usage
Just run `setup.sh` and everything will be symlinked to your home dir.  
If there are collisions with existing files they will be moved to `./backup/`  
*(Always read through random scripts from the internets before executing)*

You should probably skim through this README before using.  
Before using you should probably take the advice of a wise file:

> *"Read me"*  
> ***\- README***


## Introduction

We all feel strongly for our dotfiles, so why not share them?

These are my dotfiles that I use on a variety of hosts, from my desktop and laptop to my servers and Raspberry Pi's.

Configuration files that are here (incomplete list):
    - xmonad
    - zsh (+plugins)
    - vim` (+plugins)
    - editorconfig`
    - xinitrc` (sets up the X session)
    - ssh authorized hosts


### Keybindings
Incomplete section

**xmonad**
 - `Super-[1-9]`, switch to workspace
 - `Super-Shift-[1-9]`, move window to workspace
 - `Super-q`, close window
 - `Super-Tab`, select next window on current workspace
 - `Super-r`, launches dmenu
 - `Super-l`, locks the computer with slock

**tmux**
 - `Ctrl-Up/Down/Left/Right`, switch pane
 - `Ctrl-a + c`, new window
 - `Ctrl-a + Shift-2`, split horizontal
 - `Ctrl-a + Shift-5`, split vertical
 - `F[1-12]`, switch window


## Dependencies

### Base
 - git
 - zsh
 - tmux
 - python3

### Desktop Environment
 - xmonad, xmonad-contrib, xmonad-extras (get them using cabal)
 - dzen2, conky, dmenu, trayer, xfonts-terminus
 - redshift
 - zenity
 - Terminator (system terminal, might switch to urxvt later)
 - powerline-patched fonts (tmux & vim theme)
 - nm-applet, gnome-keyring (Managing WiFi)
 - feh (Sets background image)
 - suckless-tools (slock with super-l)

## Features
Here are a few features that you automatically get if you 

 - `.crontab` file that loads when zsh launches (might be loaded in a better way later)

## Thanks to...
 - [Johan Bjäreholt](https://github.com/johan-bjareholt/) for his [dotfiles](https://github.com/johan-bjareholt/linux-configs)
 - [brafales](https://github.com/brafales/) for his [XMonad config](https://github.com/brafales/xmonad-config) and [guide](http://thinkingeek.com/2011/11/21/simple-guide-configure-xmonad-dzen2-conky/)
 - Everyone else from whom I stole!
