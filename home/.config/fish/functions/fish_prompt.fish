function fish_prompt --description 'Write out the prompt'
	set -l last_status $status

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

  if not test $last_status -eq 0
    set_color $fish_color_error
  end

  echo -n '➤ '
  set_color normal
end
