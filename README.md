dotfiles
========

Just my dotfiles and a nice script for managing them, based on a previously private home repo.



> *Look again at that dot. That's here. That's home.*  
> \- Carl Sagan


### Usage
Just run `setup.sh` and everything will be symlinked to your home dir.  
If there are collisions with existing files they will be moved to `./backup/`  
*(Always read through random scripts from the internets before executing)*

### Dependencies
 - XMonad, with xmonad-contrib & xmonad-extras (get xmonad-extras using cabal)
 - dzen2, conky, dmenu, trayer, xfonts-terminus (Status bar with tray and menu with super-r)
 - suckless-tools (slock with super-l)
 - feh (Sets background image)
 - nm-applet, gnome-keyring (Managing WiFi)
 - powerline-patched fonts (tmux & vim theme)
 - Terminator (system terminal, might switch to urxvt later)
 - and more I can't remember...

### Thanks to
 - [Johan Bjäreholt](https://github.com/johan-bjareholt/) for his [dotfiles](https://github.com/johan-bjareholt/linux-configs)
 - [brafales](https://github.com/brafales/) for his [XMonad config](https://github.com/brafales/xmonad-config) and [guide](http://thinkingeek.com/2011/11/21/simple-guide-configure-xmonad-dzen2-conky/)
 - Everyone else from whom I stole!
