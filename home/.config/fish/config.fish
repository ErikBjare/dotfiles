# ~/.config/fish/config.fish

# Set the default editor
set -x EDITOR nvim

# Bind virtual Home and End keys with Cmd+Shift+Left and Cmd+Shift+Right
bind \e\[1\;4D beginning-of-line
bind \e\[1\;4C end-of-line

# PATH setup
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

    # PATH PREPENDS (last has highest priority)
    path_prepend /opt/homebrew/bin
    path_prepend /opt/homebrew/opt/coreutils/libexec/gnubin
    path_prepend /opt/homebrew/opt/gnu-sed/libexec/gnubin
    path_prepend /opt/homebrew/opt/grep/libexec/gnubin
    path_prepend /opt/homebrew/opt/postgresql@15/bin

    path_prepend ~/.gem/ruby/2.4.0/bin
    path_prepend ~/.gem/ruby/2.5.0/bin
    path_prepend ~/.gem/ruby/2.6.0/bin
    path_prepend ~/.gem/ruby/2.7.0/bin
    # path_prepend /opt/homebrew/opt/ruby/bin
    # path_prepend /opt/homebrew/opt/ruby@2.7/bin
    path_prepend /opt/homebrew/opt/ruby@3/bin

    # gems
    path_prepend ~/.local/share/gem/ruby/3.0.0/bin       # linux
    path_prepend /opt/homebrew/lib/ruby/gems/3.2.0/bin/  # macos

    # Setting brew JDK on macOS
    path_prepend /opt/homebrew/opt/openjdk/bin

    # To set system Python as default on macOS
    path_prepend ~/Library/Python/3.9/bin
    path_prepend /opt/homebrew/opt/python@3.10/bin

    # Setting PATH for Python 3.9
    # The original version is saved in /Users/erb/.config/fish/config.fish.pysave
    #set -x PATH "/Library/Frameworks/Python.framework/Versions/3.9/bin" "$PATH"

    # I need 16 as my system node on macOS (Copilot)
    #path_prepend /opt/homebrew/opt/node@16/bin
    path_prepend /opt/homebrew/opt/node@18/bin

    path_prepend ~/.bin/git-subrepo/lib
    path_prepend ~/.local/bin
    path_prepend ~/.cargo/bin
    path_prepend ~/.bin

    # PATH APPENDS
    path_append /usr/games

    set -x MANPATH ":$MANPATH" ~/.bin/git-subrepo/man

    path_prepend ~/.npm-packages/$NPM_PACKAGES/bin
    set MANPATH ~/.npm-packages/share/man $MANPATH
end

# Style
begin
    set fish_color_command green --bold
    set fish_color_error yellow
    set fish_color_redirection yellow --bold
end

# set default node version
set --universal nvm_default_version v20.10.0

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
        # echo "autojump was not found on system, won't be available"
    end
end

begin
    if type -f zoxide -q
        zoxide init fish | source
    else
        # echo "zoxide was not found on system, won't be available"
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

# Set FREESURFER_HOME for easier surfin'
if test -d /opt/freesurfer
    set FREESURFER_HOME /opt/freesurfer
end

# I don't remember the exact purpose of this...
begin
    set -x GPG_TTY (tty)
end

# see https://wiki.archlinux.org/index.php/GNOME/Keyring#Terminal_applications
if test -n "$DESKTOP_SESSION"
    set -x (gnome-keyring-daemon --start | string split "=")
end

begin
    if type -f -q rbenv
        status --is-interactive; and rbenv init - fish | source
    else
        # echo "rbenv was not found on system, won't be available"
    end
end

if status is-interactive
    source ~/.config/fish/create_abbrs.fish

    # if atuin is installed, load it
    type -q atuin > /dev/null; and atuin init fish --disable-up-arrow | source
end
