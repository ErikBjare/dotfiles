"
"Erik Bjäreholts .vimrc
"


" Enable syntax highlighting
syntax on

" Enable mouse
" Send more characters for redraws
set ttyfast

" Enable mouse use in all modes
set mouse=a

" Set this to the name of your terminal that supports mouse codes.
" Must be one of: xterm, xterm2, netterm, dec, jsbterm, pterm
set ttymouse=xterm2

" Always show statusline
set laststatus=2

" Use 256 colours (Use this setting only if your terminal supports 256 colours)
set t_Co=256

" Basics from vimrc_example.vim
set nocompatible
set ruler

" Indentation
set cindent
set expandtab
set shiftwidth=4
set softtabstop=4

" Set indentation settings automatically depending on filetype plugin
filetype plugin indent on

" Set markdown for .md files
au BufRead,BufNewFile *.md set filetype=markdown

set rtp+=~/.vim/

execute pathogen#infect()
