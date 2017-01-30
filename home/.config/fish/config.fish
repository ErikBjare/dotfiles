begin
    set PATH $PATH /usr/games
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

begin
    set PATH $HOME/.bin $PATH

end
