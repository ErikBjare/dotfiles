begin
    # TODO: Check if already in PATH?

    function path_prepend
        if test -e $argv
            set -x PATH $argv $PATH
        end
    end

    function path_append
        if test -e $argv
            set -x PATH $PATH $argv
        end
    end

    # PATH PREPENDS
    path_prepend  ~/.gem/ruby/2.4.0/bin
    path_prepend  ~/.gem/ruby/2.5.0/bin
    path_prepend  ~/.gem/ruby/2.6.0/bin
    path_prepend  ~/.gem/ruby/2.7.0/bin
    path_prepend ~/.bin/git-subrepo/lib
    path_prepend ~/.local/bin
    path_prepend ~/.cargo/bin
    path_prepend ~/.bin

    # PATH APPENDS
    path_append /usr/games

    set -x MANPATH ":$MANPATH" ~/.bin/git-subrepo/man

    # Nvm wrapper
    if test -e ~/.config/fish/nvm-wrapper/nvm.fish
        source ~/.config/fish/nvm-wrapper/nvm.fish
    end

    path_prepend ~/.npm-packages/$NPM_PACKAGES/bin
    set MANPATH ~/.npm-packages/share/man $MANPATH
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

begin
    if type -f zoxide -q
        zoxide init fish | source
    else
        echo "zoxide was not found on system, won't be available"
    end
end

# Virtualfish
# Needs `pip install --user virtualfish`
# https://github.com/excitedleigh/virtualfish
# NOTE: Replaced by `vf install` on first install
#begin
#    if type -q vf
#       eval (python -m virtualfish auto_activation)
#   end
#end

# pyenv
begin
    if type -q pyenv
        source (pyenv init - | psub)
    end
end

#source /opt/anaconda/etc/fish/conf.d/conda.fish

# Set FREESURFER_HOME for easier surfin'
set FREESURFER_HOME /opt/freesurfer

# I don't remember the exact purpose of this...
begin
    set -x GPG_TTY (tty)
end

# see https://wiki.archlinux.org/index.php/GNOME/Keyring#Terminal_applications
if test -n "$DESKTOP_SESSION"
    set -x (gnome-keyring-daemon --start | string split "=")
end
