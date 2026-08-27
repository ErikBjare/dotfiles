function fish_title
    # The "activity" layer of the terminal-title scheme (full design documented
    # in ~/.tmux/master.conf, title section): this emits WHAT is happening;
    # tmux appends WHERE (the pane path) to the terminal title, and
    # ActivityWatch categorizes on the combination.
    #
    # When the command being launched is ssh, pre-set the title to the target
    # host so remotes that never set a title (bare bash) still show where the
    # pane is connected; remotes running this same config overwrite it with
    # their own "dir @ host".
    if test (count $argv) -gt 0
        set -l words (string split ' ' -- $argv[1])
        if test "$words[1]" = ssh
            for w in $words[2..-1]
                string match -q -- '-*' $w; and continue
                echo "@ "(string replace -r '.*@' '' -- $w)
                return
            end
        end
    end
    if set -q SSH_TTY
        # Remote shell: "dir @ host" — becomes the outer tmux's #W and #T.
        set -l dir (basename $PWD)
        test "$PWD" = "$HOME"; and set dir '~'
        echo "$dir @ "(hostname -s)
    else if set -q TMUX
        # Local tmux pane: emit just the running command — tmux adds the path.
        # Empty at an idle prompt (the title format drops its "· " separator).
        # TUIs that set their own OSC title (claude, gptme) override this while
        # they run; fish re-emits at the next prompt, clearing it.
        if test (count $argv) -gt 0
            string sub -l 40 -- $argv[1]
        end
    else
        # Bare terminal without tmux: keep the dir so the title still says where.
        set -l dir (basename $PWD)
        test "$PWD" = "$HOME"; and set dir '~'
        echo $dir
    end
end
