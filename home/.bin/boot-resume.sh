# start apps commonly started on boot


function start() {
    # starts an app in the background (disowning), if it's not already running
    cmd=$1
    if ! pgrep -f $cmd; then
        $cmd &
    fi
    sleep 0.5
    # disown the process
    if pgrep -f $cmd; then
        disown
    fi
}


start alacritty
start firefox
start standard-notes
start roam-research
start webcord
start pavucontrol
start spotify
