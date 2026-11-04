dotfiles
========

[![Test](https://github.com/ErikBjare/dotfiles/actions/workflows/test.yml/badge.svg)](https://github.com/ErikBjare/dotfiles/actions/workflows/test.yml)
![Works on my machine](https://forthebadge.com/images/badges/works-on-my-machine.svg)

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



## tmux agent status

OSC 7501-speaking programs (including the gptme CLI integration) get event-driven
status badges: `!` blocked, `ERR` error, `~` working, `+` done, `.` idle.
Window badges roll up all splits in that priority order. Split borders show the
exact state; prefix+w includes window badges and pane states. Existing title and
ActivityWatch naming stays unchanged. Python 3 is required.

The bridge reads raw pane output through `pipe-pane`, retaining no logs. It does
not scrape agent text and does not require `allow-passthrough`. Programs that do
not emit OSC 7501 have no status: Claude Code/Codex need their own event hooks or
adapters; installing this does not magically add protocol support to them.

Reload with `tmux source-file ~/.tmux/master.conf`. Reports begin with the next
state change, not by reconstructing history. Existing logging pipes take
precedence, so panes using another `pipe-pane` consumer are skipped. Normal chat
exit clears status; shell OSC 133 prompt markers also clear it after crashes.
Without those shell markers, a hard-killed agent can leave a stale badge; clear
one with `tmux set-option -pu -t %PANE @agent-state`. Remote direct SSH output
works if it carries reports; nested remote tmux consumes unknown OSC sequences
and needs a bridge on that server (not enabled automatically).

Test the parser with `python3 -m unittest discover -s tests`.

## Thanks to...
 - [Johan Bjäreholt](https://github.com/johan-bjareholt/) for his [dotfiles](https://github.com/johan-bjareholt/linux-configs)
 - [brafales](https://github.com/brafales/) for his [XMonad config](https://github.com/brafales/xmonad-config) and [guide](http://thinkingeek.com/2011/11/21/simple-guide-configure-xmonad-dzen2-conky/)
 - Everyone else from whom I stole!
