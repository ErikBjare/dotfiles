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
    set_color -o red
  else
    set_color -o grey
  end

  # Prompt
  echo -n '↪ '
  #__informative_git_prompt
  set_color -o red; echo -n "➤"
  set_color -o yellow; echo -n "➤"
  set_color -o green; echo -n "➤ "

  #

  set_color normal
end
