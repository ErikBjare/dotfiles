" Basic Settings
"
" Summary:
"  - <Space> is the leader key
"  - Folds are enabled (in some languages) and uses default bindings
"  - q and wq only closes buffers, use qa to close vim entirely
"       - Looking for a better solution

set nocompatible
set ruler
set ttyfast
set mouse=a
set timeoutlen=300

if !has('nvim')
    set ttymouse=xterm2
endif

if (has("termguicolors"))
 set termguicolors
endif

set splitbelow
set splitright
set laststatus=2
set t_Co=256

set number
set cindent
set expandtab
set shiftwidth=4
set softtabstop=4
set nowrap

filetype plugin indent on

set rtp+=~/.vim/

set shell=sh
let g:python3_host_prog = '/usr/bin/python3'

set hlsearch

" Conceal config
set conceallevel=2
set concealcursor="n"

" Enable syntax highlighting
syntax on

" Auto-detect poetry
let g:ale_python_auto_poetry = 1

" Highlight occurences of selected word
autocmd CursorMoved * exe printf('match IncSearch /\V\<%s\>/', escape(expand('<cword>'), '/\'))

" Show the git diff in vim when commiting
autocmd FileType gitcommit DiffGitCached | wincmd p

" File type associations
au BufNewFile,BufRead *.md set filetype=markdown
au BufNewFile,BufRead *.pyi set filetype=python
au BufNewFile,BufRead *.ipy set filetype=python
au BufNewFile,BufRead *.abi set filetype=json
au BufNewFile,BufRead *.jrag set filetype=java
au BufNewFile,BufRead *.env.* set filetype=sh
