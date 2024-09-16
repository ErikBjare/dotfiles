" Erik Bjäreholt's .vimrc
"
" Part of my dotfiles:  https://github.com/ErikBjare/dotfiles
"
" > "Look again at that dot. That's here. That's home. That's us."
"
" Summary:
"  This .vimrc file sources configurations from separate files:
"  - basic.vim: Basic Vim settings
"  - keymaps.vim: Key mappings
"  - plugins.vim: Plugin configurations
"  - theme.vim: Theme and UI settings
"  - languages.vim: Language-specific settings
"
" See individual files in ~/.vim/config/ for more detailed summaries.
"
" TODOs:
"   - Fix proper pane/window/buffer config
"   - Split into seperate files: one base, one for keys, one for theme, one for syntax, one for plugins
"   - Make pageup/pagedown move half page and center view

" Source configuration files
source ~/.vim/config/basic.vim
source ~/.vim/config/keymaps.vim
source ~/.vim/config/plugins.vim
source ~/.vim/config/theme.vim
source ~/.vim/config/languages.vim

" Load Lua plugins only for Neovim
if has('nvim')
  lua require('plugins')
endif
