dotfiles
========

[![Build Status](https://travis-ci.org/ErikBjare/dotfiles.svg)](https://travis-ci.org/ErikBjare/dotfiles)

Just my dotfiles and a nice script for managing them, based on a previously private home repo.

> *Look again at that dot. That's here. That's home.*  
> \- Carl Sagan

## Usage
Just run `setup.sh` and everything will be symlinked to your home dir.  
If there are collisions with existing files they will be moved to `./backup/`  
*(Always read through random scripts from the internets before executing)*

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

## Thanks to...
 - [Johan Bjäreholt](https://github.com/johan-bjareholt/) for his [dotfiles](https://github.com/johan-bjareholt/linux-configs)
 - [brafales](https://github.com/brafales/) for his [XMonad config](https://github.com/brafales/xmonad-config) and [guide](http://thinkingeek.com/2011/11/21/simple-guide-configure-xmonad-dzen2-conky/)
 - Everyone else from whom I stole!
