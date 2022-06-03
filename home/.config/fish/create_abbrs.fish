#!/usr/bin/env fish

abbr --add eg "egrep"

abbr --add archive-targz "tar xzvf"

abbr --add llt "ls -l --sort=time --reverse"
abbr --add lld "ls -l --group-directories-first -X"
abbr --add lsd "ls --group-directories-first -X"

abbr --add gs "git status"
abbr --add gss "git submodule summary"

abbr --add gl "git log --all --graph --decorate --pretty"
abbr --add gd "git diff"
abbr --add gds "git diff --staged"

abbr --add gpl "git pull"
abbr --add gps "git push"

abbr --add pe "pipenv"

abbr --add tmain "tmux attach -t main; or tmux new-session -t main"
abbr --add tsys "tmux attach -t system; or tmux new-session -t system"

abbr --add vim "nvim"

abbr --add sctl "systemctl"
abbr --add usctl "systemctl --user"

abbr --add own "sudo chown (whoami)"
