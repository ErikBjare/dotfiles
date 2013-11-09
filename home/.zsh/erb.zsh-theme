# vim:ft=zsh ts=2 sw=2 sts=2

if which powerline &>/dev/null; then
  export POWERLINE_COMMAND=powerline

  PS1='$($POWERLINE_COMMAND shell left -r zsh_prompt --last_exit_code=$? --last_pipe_status="$pipestatus")'
  RPS1='$($POWERLINE_COMMAND shell right -r zsh_prompt --last_exit_code=$? --last_pipe_status="$pipestatus")'
else
  echo "Powerline not installed! (from ~/.zsh-theme)"

  PROMPT="%{$fg_bold[green]%}%n%{$reset_color%}@%{$fg_bold[blue]%}%m%{$fg[white]%}:%{$fg[red]%}%~%{$fg[yellow]%}$%{$reset_color%} "
  RPROMPT="[%{$fg_no_bold[yellow]%}%!%{$reset_color%}]"
fi
