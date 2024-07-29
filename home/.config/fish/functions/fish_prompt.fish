set -g bgcolor '111'

function fish_prompt --description 'Write out the prompt'

    # set LAST_STATUS
	set -l LAST_STATUS $status

    # set SESSION_TYPE
    if test -n "$SSH_CLIENT" -o -n "$SSH_TTY"
        set -g SESSION_TYPE "remote/ssh"
    else
        #switch (ps -o comm= -p $PPID)
        #    case 'sshd' '*sshd'
        #        set -g SESSION_TYPE "remote/ssh"
        #end
    end

    if false
        echo -n ':'

        # PWD
        set_color $fish_color_cwd
        echo -n (prompt_pwd)
        set_color normal

        __terlar_git_prompt
        __fish_hg_prompt
        echo
  end

  if not test $LAST_STATUS -eq 0
    set_color -o f00 -b $bgcolor
    echo -n ' ↪ '
    #echo -n ' Exited with error code '$LAST_STATUS
    #echo
  else
    set_color -o white -b $bgcolor
    echo -n ' ↪ '
    #set_color '383'
    #echo -n ' Exited gracefully'
    #echo
  end
  set_color -b '111'

  set_color -o 'fff'
#  echo -n ' 🗁  '
  echo -n ' '
  set_color '999'
  echo -n (prompt_pwd)' '

  set -l git_dir (git rev-parse --git-dir 2> /dev/null)
  if test $git_dir
    echo -n ' '(parse_git_branch)
  end

  if set -q VIRTUAL_ENV
    set_color 999 $bgcolor
    #echo -n -s (set_color -b 111 white)
    echo -n " (venv:"(basename "$VIRTUAL_ENV")")"
  end

  if test "$SESSION_TYPE" = "remote/ssh"
      set -l color_misc '555'
      set -l color_ssh 'ff0'
      set -l color_user '5f5'
      set -l color_host '338'

      set_color normal -b $bgcolor
      set_color $color_misc
      echo -n ' ('
      set_color --bold $color_ssh
      echo -n 'ssh '

      # User
      # if user != erb
      if test (whoami) != 'erb'
          set_color --bold $color_user
          echo -n (whoami)
          set_color $color_misc
          echo -n '@'
      end

      # Host
      set_color --bold $color_host
      # I once used the -s flag for hostname, caused some crazy slow
      # execution of the command however (>2s), so now I don't.
      echo -n (hostname)
      set_color normal
      set_color $color_misc -b $bgcolor
      echo -n ')'
  end

  # set_color -b '000'
  echo
  # set_color -b '000'

  # reset color
  set_color -b normal

  #__informative_git_prompt
  set_color -o red; echo -n "➤"
  set_color -o yellow; echo -n "➤"
  set_color -o green; echo -n "➤ "
end


# -----------------------------------------------------------------------------
# The below was taken from https://gist.github.com/davidmh/721241c7c34f841eed07
# -----------------------------------------------------------------------------

function parse_git_branch
  set fish_git_dirty_color 'f22'
  set fish_git_not_dirty_color green

  # Get current branch
  set -l branch (git branch 2> /dev/null | grep -e '\* ' | sed 's/^..\(.*\)/\1/')

  # Runs git status with timeout such that it's skipped for slow git repos
  # FIXME: If timeout is triggered, status will incorrectly always show as clean
  set -l git_status (timeout 0.5 git status -s)
  set -l git_status_code $status

  set_color normal
  set_color -d grey -b $bgcolor
  echo -n '['$branch

  # if status code was 124 then command timed out
  if test $git_status_code -eq 124
    echo -n ''
  else if test -n "$git_status"
    echo -n (set_color $fish_git_dirty_color)'*'
  else
    echo -n (set_color $fish_git_not_dirty_color)'✔️'
  end
  set_color -d grey
  echo -n ']'
end
