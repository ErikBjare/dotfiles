"
" Erik Bjareholts .vimrc
"
" TODO: Split into seperate files: one base, one for keys, one for theme, one for syntax
" TODO: Make pageup move half page and center view (the equivalent of `z.`)

" Set leader key to space
let mapleader = "\<Space>"
nnoremap <Leader><Leader> :

" Enable mouse
" Send more characters for redraws
set ttyfast

" Enable mouse use in all modes
set mouse=a

if !has('nvim')
    " Set this to the name of your terminal that supports mouse codes.
    " Must be one of: xterm, xterm2, netterm, dec, jsbterm, pterm
    set ttymouse=xterm2
endif

" Always show statusline
set laststatus=2

" Use 256 colours (Use this setting only if your terminal supports 256 colours)
set t_Co=256

" Basics from vimrc_example.vim
set nocompatible
set ruler

" Relative line numbers toggle
function! NumberToggle()
  if(&relativenumber == 1)
    set norelativenumber
  else
    set relativenumber
  endif
endfunc
nnoremap <C-n> :call NumberToggle()<cr>

" Sets relative line numbers with current line showing absolute line number,
" should be disabled by default on remote SSH sessions as it can cause
" significant slowdown.
set number

" <C-C> and <C-V> for copy and paste
vmap <C-C> :!xclip -f -sel clip<CR>
" TODO: Doesn't work
"map <C-V> :set paste; -1r !xclip -o -sel clip; set nopaste<CR>

" Indentation
set cindent
set expandtab
set shiftwidth=4
set softtabstop=4

" Don't wrap by default (you might want to wrap in non-code files)
set nowrap

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

" First line needed since 7.4 to indent HTML properly:
"   http://askubuntu.com/questions/392573/how-do-i-get-vim-to-indent-all-html-tags
let g:html_indent_inctags = "html,body,head,tbody,p,li,a,span,header,footer,small,b,i"

" Set indentation settings automatically depending on filetype plugin
filetype plugin indent on

" Set markdown for .md files
au BufRead,BufNewFile *.md set filetype=markdown

set rtp+=~/.vim/

" vim-airline config
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1
let g:airline_theme='simple'

" To disable a plugin, add it's bundle name to the following list
let g:pathogen_disabled = []

if has('nvim')
    call add(g:pathogen_disabled, 'vim-geeknote')
endif

" Run pathogen
execute pathogen#infect()

" Enable syntax highlighting
syntax on

" Enable conceal
set cole=2

" Enable search highlighting
set hlsearch

" Better incsearch with incsearch.vim
map /  <Plug>(incsearch-forward)
map ?  <Plug>(incsearch-backward)
map g/ <Plug>(incsearch-stay)

let g:incsearch#auto_nohlsearch = 1
map n  <Plug>(incsearch-nohl-n)
map N  <Plug>(incsearch-nohl-N)
map *  <Plug>(incsearch-nohl-*)
map #  <Plug>(incsearch-nohl-#)
map g* <Plug>(incsearch-nohl-g*)
map g# <Plug>(incsearch-nohl-g#)

" Use lighter color scheme
let g:solarized_termcolors=256
let g:solarized_termtrans=1
set background=dark
colorscheme solarized

" Use Python 3 for syntastic highlighting
let g:syntastic_python_python_exec = 'python3'

" Use jshint for JS checking
let g:syntastic_javascript_checkers = ['jshint']

" HTML Tidy stuff
let g:syntastic_html_tidy_ignore_errors = ['proprietary attribute', 'trimming empty <span>', 'ng-', '"href" lacks value', 'trimming empty <li>', "isn't allowed in <head>"]
let g:syntastic_html_tidy_blocklevel_tags = ['slides', 'slide', 'hgroup']

" C++ syntastic stuff
let g:syntastic_cpp_compiler = "g++"
let g:syntastic_cpp_compiler_options = " -std=c++11"

" YouCompleteMe close window after completion
let g:ycm_autoclose_preview_window_after_completion=1
" GoToDefinition for key
map <leader>g  :YcmCompleter GoToDefinitionElseDeclaration<CR>

" Show the git diff in vim when commiting
" Stolen from:
"   https://github.com/Coornail/coornails_dotfiles/blob/master/.vimrc#L131
autocmd FileType gitcommit DiffGitCached | wincmd p

" Wrap lines on whitespace in markdown
autocmd FileType markdown setlocal wrap linebreak nolist
