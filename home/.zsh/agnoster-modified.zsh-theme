# vim:ft=zsh ts=2 sw=2 sts=2
#
# Modified by Erik Bjäreholt
#
# agnoster's Theme - https://gist.github.com/3712874
# A Powerline-inspired theme for ZSH
#
# # README
#
# In order for this theme to render correctly, you will need a
# [Powerline-patched font](https://gist.github.com/1595572).
#
# In addition, I recommend the
# [Solarized theme](https://github.com/altercation/solarized/) and, if you're
# using it on Mac OS X, [iTerm 2](http://www.iterm2.com/) over Terminal.app -
# it has significantly better color fidelity.
#
# # Goals
#
# The aim of this theme is to only show you *relevant* information. Like most
# prompts, it will only show git information when in a git working directory.
# However, it goes a step further: everything from the current user and
# hostname to whether the last call exited with an error to whether background
# jobs are running in this shell will all be displayed automatically when
# appropriate.

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'
SEGMENT_SEPARATOR_MIN=''
SEGMENT_SEPARATOR=''

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    echo -n " %{$fg_no_bold[$CURRENT_BG]$bg[$1]%}$SEGMENT_SEPARATOR%{$fg_bold[$2]%} "
  elif [[ $CURRENT_BG != 'NONE' && $1 == $CURRENT_BG ]]; then
    echo -n " %{$fg_no_bold[white]$bg[$1]%}$SEGMENT_SEPARATOR_MIN%{$fg_bold[$2]%} "
  else
    echo -n "%{$bg[$1]$fg_bold[$2]%} "
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && echo -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n " %{$fg_no_bold[$CURRENT_BG]$bg[default]%}$SEGMENT_SEPARATOR%{$fg_no_bold[white]%}"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%}"
  CURRENT_BG=''
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
prompt_context() {
  local user=`whoami`

  if [[ "$user" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    prompt_segment black green "%(!.%{%F{yellow}%}.)$user@%m"
  else
    prompt_segment black green "%(!.%{%F{yellow}%}.)$user"
  fi
}

# Git: branch/detached head, dirty status
prompt_git() {
  local ref dirty
  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    ZSH_THEME_GIT_PROMPT_DIRTY='±'
    dirty=$(parse_git_dirty)
    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git show-ref --head -s --abbrev |head -n1 2> /dev/null)"
    if [[ -n $dirty ]]; then
      prompt_segment yellow black
    else
      prompt_segment green black
    fi
    echo -n "${ref/refs\/heads\// }%{$fg_no_bold[grey]%}$dirty%{$fg_bold[grey]%}"
  fi
}

# Dir: current working directory
prompt_dir() {
  prompt_segment blue white '%c'
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
  # Useful symbols:
  # ☢ ⚙ ⚡ ☉ ✘ ❌ ⁂
  # More at: https://en.wikibooks.org/wiki/Unicode/List_of_useful_symbols
  local symbols
  symbols=()
  [[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}❌"
  [[ $UID -eq 0 ]] && symbols+="%{$fg_bold[yellow]%}☢"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}⚙"

  [[ -n "$symbols" ]] && prompt_segment black default "$symbols"
}

## Main prompt
build_prompt() {
  RETVAL=$?
  prompt_status
  prompt_context
  prompt_dir
  prompt_git
  prompt_end
}

PROMPT='%{%f%b%k%}$(build_prompt) '
RPROMPT=''

# Displays when in normal mode
# From: http://dougblack.io/words/zsh-vi-mode.html
function zle-line-init zle-keymap-select {
    VIM_PROMPT="%{$fg_bold[yellow]%} [% NORMAL]% %{$reset_color%}"
    RPS1="${${KEYMAP/vicmd/$VIM_PROMPT}/(main|viins)/} $EPS1"
    zle reset-prompt
}

zle -N zle-line-init
zle -N zle-keymap-select
