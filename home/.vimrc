"
"Erik Bjäreholts .vimrc
"


"Enable syntax highlighting
syntax on

set rtp+=~/.vim/

" Always show statusline
set laststatus=2

" Use 256 colours (Use this setting only if your terminal supports 256 colours)
set t_Co=256

"Basics from vimrc_example.vim
set nocompatible
set ruler

"Indentation
set cindent
set expandtab
set shiftwidth=4
set softtabstop=4

"Set indentation settings automatically depending on filetype plugin
filetype plugin indent on

"Set markdown for .md files
au BufRead,BufNewFile *.md set filetype=markdown

execute pathogen#infect()
