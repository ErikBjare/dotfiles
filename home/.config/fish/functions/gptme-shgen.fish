function gptme-shgen --description 'LLM-generated shell command, confirmed and run in this shell'
    # Help/flags go straight to the script
    if test (count $argv) -eq 0; or contains -- -h $argv; or contains -- --help $argv
        command gptme-shgen $argv
        return
    end
    set -l cmd (command gptme-shgen --print --shell fish $argv | string collect)
    or return
    if string match -q '#*' -- $cmd
        echo $cmd >&2
        return 1
    end
    # Editable, prefilled prompt: Enter runs, Ctrl-C aborts
    read -l -c "$cmd" -P (set_color -o yellow)'$ '(set_color normal) final
    or return 130
    test -n "$final"; or return 130
    eval $final
end
