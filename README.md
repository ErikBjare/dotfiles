dotfiles
========

[![Build Status](https://travis-ci.org/ErikBjare/dotfiles.svg)](https://travis-ci.org/ErikBjare/dotfiles)

My dotfiles and a nice script for managing them, based on a previously private home repo.

> *Look again at that dot. That's here. That's home. That's us.*  
> \- Carl Sagan


## Usage
Just run `setup.sh` and everything will be symlinked to your home dir.
If there are collisions with existing files they will be moved to `./backup/`
*(Always read through random scripts from strangers on the internet before executing)*


## Introduction

We all feel strongly for our dotfiles, so why not share our love by sharing them?

These are my dotfiles that I use on a variety of hosts, from my desktop and laptop, to my servers and Raspberry Pi's.

## Current setup

|               | Now         | Past        |
|---------------|-------------|-------------|
| **DE/WM**       | i3          | xmonad, KDE |
| **Browser**     | firefox     | chromium    |
| **Terminal**    | Alacritty   | terminator  |
| **Shell**       | fish        |
| **Editor**      | Neovim      | Vim, PyCharm (with vim-mode), Eclipse  |
| **Terminal multiplexer** | tmux | screen |
| File synchronization | Syncthing | Dropbox |
| Archival/backup system      | git-annex |         |



## Thanks to...
 - [Johan Bjäreholt](https://github.com/johan-bjareholt/) for his [dotfiles](https://github.com/johan-bjareholt/linux-configs)
 - [brafales](https://github.com/brafales/) for his [XMonad config](https://github.com/brafales/xmonad-config) and [guide](http://thinkingeek.com/2011/11/21/simple-guide-configure-xmonad-dzen2-conky/)
 - Everyone else from whom I stole!
