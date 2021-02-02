set -g bgcolor '111'

function fish_prompt --description 'Write out the prompt'

	set -l last_status $status

    if false
          # User
          set_color $fish_color_user
          echo -n (whoami)
          set_color normal


          # Host
          echo -n '@'
          set_color $fish_color_host
          # I once used the -s flag for hostname, caused some crazy slow
          # execution of the command however (>2s), so now I don't.
          echo -n (hostname | grep -o '[^erb-].*')
          set_color normal

          echo -n ':'

          # PWD
          set_color $fish_color_cwd
          echo -n (prompt_pwd)
          set_color normal

          __terlar_git_prompt
          __fish_hg_prompt
          echo
  end

  if not test $last_status -eq 0
    set_color -o f00 -b $bgcolor
    echo -n ' ↪ '
    #echo -n ' Exited with error code '$last_status
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
  echo -n ' 🗁  '
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

  set_color -b '000'
  echo
  set_color -b '000'

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
  set -l git_status (timeout 1 git status -s)


  set_color normal
  set_color -d grey -b $bgcolor
  echo -n '['$branch
  if test -n "$git_status"
    echo -n (set_color $fish_git_dirty_color)'*'
  else
    echo -n (set_color $fish_git_not_dirty_color)'✔️'
  end
  set_color -d grey
  echo -n ']'
end
