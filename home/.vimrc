"
"
"Erik Bjäreholts .vimrc
"


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

nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" Mappings to access buffers (don't use "\p" because a
" delay before pressing "p" would accidentally paste).
" \l       : list buffers
" \b \f \g : go back/forward/last-used
" \1 \2 \3 : go to buffer 1/2/3 etc
nnoremap <Leader>l :ls<CR>
nnoremap <Leader>b :bp<CR>
nnoremap <Leader>f :bn<CR>
nnoremap <Leader>g :e#<CR>
nnoremap <Leader>1 :1b<CR>
nnoremap <Leader>2 :2b<CR>
nnoremap <Leader>3 :3b<CR>
nnoremap <Leader>4 :4b<CR>
nnoremap <Leader>5 :5b<CR>
nnoremap <Leader>6 :6b<CR>
nnoremap <Leader>7 :7b<CR>
nnoremap <Leader>8 :8b<CR>
nnoremap <Leader>9 :9b<CR>
nnoremap <Leader>0 :10b<CR>
" It's useful to show the buffer number in the status line.
set laststatus=2 statusline=%02n:%<%f\ %h%m%r%=%-14.(%l,%c%V%)\ %P

" First line needed since 7.4 to indent HTML properly:
"   http://askubuntu.com/questions/392573/how-do-i-get-vim-to-indent-all-html-tags
let g:html_indent_inctags = "html,body,head,tbody,p,li,a,span,header,footer,small,b,i"

" Set indentation settings automatically depending on filetype plugin
filetype plugin indent on

" Set markdown for .md files
au BufRead,BufNewFile *.md set filetype=markdown

set rtp+=~/.vim/


" Run pathogen
execute pathogen#infect()

" Enable syntax highlighting
syntax on
" Use lighter color scheme
let g:solarized_termcolors=256
let g:solarized_termtrans=1
set background=dark
colorscheme solarized
set number

" Use Python 3 for syntastic highlighting
let g:syntastic_python_python_exec = 'python3'
let g:syntastic_javascript_checkers = ['jshint']
