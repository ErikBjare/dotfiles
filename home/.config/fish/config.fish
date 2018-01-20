begin
    if test -e /usr/games
        set -x PATH $PATH /usr/games
    end

    if test -e ~/.local/bin
        set -x PATH ~/.local/bin $PATH
    end

    if test -e ~/.cargo/bin
        set -x PATH ~/.cargo/bin $PATH
    end

    if test -e ~/.gem/ruby/2.4.0/bin
        set -x PATH $PATH ~/.gem/ruby/2.4.0/bin
    end

    if test -e ~/.gem/ruby/2.5.0/bin
        set -x PATH $PATH ~/.gem/ruby/2.5.0/bin
    end

    if test -e ~/.bin/git-subrepo/lib
        set -x PATH $PATH ~/.bin/git-subrepo/lib
    end

    if test -e ~/.config/fish/nvm-wrapper/nvm.fish
        source ~/.config/fish/nvm-wrapper/nvm.fish
    end

    # Should be first (or almost first) on PATH
    set -x PATH ~/.bin $PATH

    set -x MANPATH ":$MANPATH" ~/.bin/git-subrepo/man
end

# Style
begin
    set fish_color_command green --bold
    set fish_color_error yellow
    set fish_color_redirection yellow --bold
end


begin
    # Try with the users install
    set --local AUTOJUMP_PATH $HOME/.autojump/share/autojump/autojump.fish

    # If user did not have his own, try the system one
    if test "! -e $AUTOJUMP_PATH"
        set AUTOJUMP_PATH /usr/share/autojump/autojump.fish
    end

    if test -e $AUTOJUMP_PATH
        source $AUTOJUMP_PATH
    else
        echo "autojump was not found on system, won't be available"
    end
end

