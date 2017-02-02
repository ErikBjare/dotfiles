"
" Erik Bjareholts .vimrc
" https://github.com/ErikBjare/dotfiles
"

" Summary:
"   - <Space> is the leader key
"   - <Leader>-b opens buffer search (using Unite)
"   - <Leader>-f opens file search (using Unite)
"   - <Leader>-n opens nerdtree
"   - <Leader><Leader> triggers easymotion
"   - <C-{H,J,K,L}> changes panes
"   - Folds are enabled (in some languages) and uses default bindings
"   - q and wq only closes buffers, use qa to close vim entirely
"       - Looking for a better solution
"
" TODOs:
"   - Fix proper pane/window/buffer config
"   - Split into seperate files: one base, one for keys, one for theme, one for syntax
"   - Make pageup/pagedown move half page and center view
"

" Set leader key to space
let mapleader = "\<Space>"
set timeoutlen=300

" Easymotion
map <Leader><Leader> <Plug>(easymotion-prefix)

" NERDTree
map <Leader>n :NERDTreeToggle<CR>

map <Leader>h :sp<CR>
map <Leader>v :vsp<CR>

" Window switching
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
nnoremap <C-Up> <C-W><C-K>
nnoremap <C-Down> <C-W><C-J>
nnoremap <C-Right> <C-W><C-L>
nnoremap <C-Left> <C-W><C-H>

nnoremap <Leader>b :Unite buffer<CR>
nnoremap <Leader>t :Unite tab<CR>
nnoremap <Leader>f :Unite file<CR>
nnoremap <Leader>ff :Unite -start-insert file_rec<CR>

" Better incsearch with incsearch.vim
map /  <Plug>(incsearch-forward)
map ?  <Plug>(incsearch-backward)
map g/ <Plug>(incsearch-stay)

" Remove search highlight when non-search movement happens
let g:incsearch#auto_nohlsearch = 1
map n  <Plug>(incsearch-nohl-n)
map N  <Plug>(incsearch-nohl-N)
map *  <Plug>(incsearch-nohl-*)
map #  <Plug>(incsearch-nohl-#)
map g* <Plug>(incsearch-nohl-g*)
map g# <Plug>(incsearch-nohl-g#)

" fugitive git bindings
nnoremap <Leader>ga :Git add %:p<CR><CR>
nnoremap <Leader>gs :Gstatus<CR>
nnoremap <Leader>gc :Gcommit -v -q<CR>
nnoremap <Leader>gt :Gcommit -v -q %:p<CR>
nnoremap <Leader>gd :Gdiff<CR>
nnoremap <Leader>ge :Gedit<CR>
nnoremap <Leader>gr :Gread<CR>
nnoremap <Leader>gw :Gwrite<CR><CR>
nnoremap <Leader>gl :silent! Glog<CR>:bot copen<CR>
nnoremap <Leader>gp :Ggrep<Space>
nnoremap <Leader>gm :Gmove<Space>
nnoremap <Leader>gb :Git branch<Space>
nnoremap <Leader>go :Git checkout<Space>
nnoremap <Leader>gps :Dispatch! git push<CR>
nnoremap <Leader>gpl :Dispatch! git pull<CR>

" GoToDefinition for key
"map <leader>g  :YcmCompleter GoToDefinitionElseDeclaration<CR>

"
" Here ends the keyconfig
" Here starts some basic settings
"

" Necessary if using fish
" https://github.com/Xuyuanp/nerdtree-git-plugin/blob/1f3fe773bbc3d8bdd0096e19c26481dddab7cdfc/README.md#faq
set shell=sh

" Basics from vimrc_example.vim
set nocompatible
set ruler

" Send more characters for redraws
set ttyfast

" Enable mouse use in all modes
set mouse=a

if !has('nvim')
    " Set this to the name of your terminal that supports mouse codes.
    " Must be one of: xterm, xterm2, netterm, dec, jsbterm, pterm
    set ttymouse=xterm2
endif

if (has("termguicolors"))
 set termguicolors
endif

" More 'natural' splits
set splitbelow
set splitright

" Always show statusline
set laststatus=2

" Use 256 colours (Use this setting only if your terminal supports 256 colours)
set t_Co=256

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

" Don't wrap by default
set nowrap

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
    call add(g:pathogen_disabled, 'vim-colors-solarized')
endif
if !has('nvim')
    call add(g:pathogen_disabled, 'vim-geeknote')
    call add(g:pathogen_disabled, 'neovim-colors-solarized-truecolors-only')
endif

" Run pathogen
execute pathogen#infect()

" Enable syntax highlighting
syntax on

" Enable conceal
set cole=2

" Enable search highlighting
set hlsearch

" Use lighter color scheme
let g:solarized_termcolors=256
let g:solarized_termtrans=1
set background=dark
colorscheme solarized
"colorscheme tender
"highlight Normal guibg=black guifg=white ctermbg=None

"
" Syntastic config
"

set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
"let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

" Use Python 3 for syntastic highlighting
let g:syntastic_python_python_exec = 'python3'
let g:syntastic_python_checkers=['flake8']
let g:syntastic_python_flake8_args='--ignore=E225,E402,E501'

" Use jshint for JS checking
let g:syntastic_javascript_checkers = ['jshint']

" HTML Tidy stuff
let g:syntastic_html_tidy_ignore_errors = ['proprietary attribute', 'trimming empty <span>', 'ng-', '"href" lacks value', 'trimming empty <li>', "isn't allowed in <head>"]
let g:syntastic_html_tidy_blocklevel_tags = ['slides', 'slide', 'hgroup']

" C++ syntastic stuff
let g:syntastic_cpp_compiler = "g++"
let g:syntastic_cpp_compiler_options = " -std=c++11"

" Disable showing diff after :Autopep8
let g:autopep8_disable_show_diff=1

" YouCompleteMe close window after completion
let g:ycm_autoclose_preview_window_after_completion=1

" NERD Commenter
" Use compact syntax for prettified multi-line comments
let g:NERDCompactSexyComs = 1
" Align line-wise comment delimiters flush left instead of following code indentation
let g:NERDDefaultAlign = 'left'

" Show the git diff in vim when commiting
" Stolen from:
"   https://github.com/Coornail/coornails_dotfiles/blob/master/.vimrc#L131
autocmd FileType gitcommit DiffGitCached | wincmd p

" Highlight occurences of selected word
autocmd CursorMoved * exe printf('match IncSearch /\V\<%s\>/', escape(expand('<cword>'), '/\'))

" Needed to make .pyi files highlight as Python files
au BufNewFile,BufRead *.pyi set filetype=python
au BufNewFile,BufRead *.ipy set filetype=python

au BufNewFile,BufRead *.jrag set filetype=java

