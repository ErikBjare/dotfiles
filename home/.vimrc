"
" Erik Bjäreholt's .vimrc
"
" Part of my dotfiles:  https://github.com/ErikBjare/dotfiles
"
" > "Look again at that dot. That's here. That's home. That's us. "
"

" Summary:
"  - <Space> is the leader key
"  - <Leader>-b opens buffer search (using Unite)
"  - <Leader>-f opens file search (using Unite)
"  - <Leader>-n opens nerdtree
"  - <Leader><Leader> triggers easymotion
"  - <C-{H,J,K,L}> changes panes
"  - Folds are enabled (in some languages) and uses default bindings
"  - q and wq only closes buffers, use qa to close vim entirely
"       - Looking for a better solution
"
" Navigation:
"  - gd: Go to definition
"  - gf: Go to file
"  - <C-]>: Go to definition (jumps to files)
"
" TODOs:
"   - Fix proper pane/window/buffer config
"   - Split into seperate files: one base, one for keys, one for theme, one for syntax, one for plugins
"   - Make pageup/pagedown move half page and center view

" Set leader key to space
let mapleader = "\<Space>"
set timeoutlen=300

" Set the title string to the current filename
set title
set titlestring="%t %{expand(\"%:p:h\")}"

" Easymotion
map <Leader><Leader> <Plug>(easymotion-prefix)

" NERDTree
map <Leader>n :NERDTreeToggle<CR>

" Split
map <Leader>h :sp<CR>
map <Leader>v :vsp<CR>

" Clipboard copying
noremap <Leader>y "+y
noremap <Leader>p "+p
" TODO: Only enable in insert-mode, otherwise will collide with other maps
"noremap <C-C> "+y
"noremap <C-V> "+p

" Window switching
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
nnoremap <C-Up> <C-W><C-K>
nnoremap <C-Down> <C-W><C-J>
nnoremap <C-Right> <C-W><C-L>
nnoremap <C-Left> <C-W><C-H>

" Move correctly in wrapped mode
map k gk
map j gj
map <Up> gk
map <Down> gj

" Use :Sw to save as root
command! -nargs=0 Sw w !sudo tee % > /dev/null

" ctrl+r in visual mode to replace
vnoremap <C-r> "hy:%s/<C-r>h//g<left><left>

nnoremap <Leader>b :Unite buffer<CR>
nnoremap <Leader>t :Unite tab<CR>
nnoremap <Leader>f :Unite file<CR>
nnoremap <Leader>ff :Unite -start-insert file_rec<CR>
nnoremap <Leader>cc :Unite grammarous

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

" vim-easy-align
" For example, to align a markdown table:
"   :EasyAlign*<Bar><Enter>
" Source: https://thoughtbot.com/blog/align-github-flavored-markdown-tables-in-vim
nmap ga <Plug>(EasyAlign)
xmap ga <Plug>(EasyAlign)

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

"let g:jedi#goto_command = "<leader>d"
"let g:jedi#goto_assignments_command = "<leader>g"
"let g:jedi#goto_stubs_command = "<leader>s"
"let g:jedi#goto_definitions_command = ""
"let g:jedi#documentation_command = "K"
let g:jedi#usages_command = "<leader>u"
"let g:jedi#completions_command = "<C-Space>"
"let g:jedi#rename_command = "<leader>r"
"let g:jedi#rename_command_keep_name = "<leader>R"

let g:grammarous#hooks = {}
function! g:grammarous#hooks.on_check(errs) abort
    nmap <buffer><C-n> <Plug>(grammarous-move-to-next-error)
    nmap <buffer><C-p> <Plug>(grammarous-move-to-previous-error)
endfunction

function! g:grammarous#hooks.on_reset(errs) abort
    nunmap <buffer><C-n>
    nunmap <buffer><C-p>
endfunction

"let g:grammarous#show_first_error = 1
" Disabled rules
"  - DASH_RULE
"  - WORD_CONTAINS_UNDERSCORE
" Below setting disables some rules for each filetype. * means all filetypes, help means vim help.
let g:grammarous#disabled_rules = {
\ '*' : ['WHITESPACE_RULE', 'EN_QUOTES'],
\ 'tex' : ['WHITESPACE_RULE', 'EN_QUOTES', 'SENTENCE_WHITESPACE', 'UPPERCASE_SENTENCE_START', 'DASH_RULE', 'WORD_CONTAINS_UNDERSCORE'],
\ }

" GoToDefinition for key
"map <leader>g  :YcmCompleter GoToDefinitionElseDeclaration<CR>

"
" Here ends the keyconfig
" Here starts some basic settings
"

" Necessary if using fish
" https://github.com/Xuyuanp/nerdtree-git-plugin/blob/1f3fe773bbc3d8bdd0096e19c26481dddab7cdfc/README.md#faq
set shell=sh

" Use python3 for neovim
let g:python3_host_prog = '/usr/bin/python3'

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

" Install vim-plug if not installed
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Register plugins with vim-plug
call plug#begin('~/.vim/plugged')
    " LSP
    Plug 'williamboman/mason.nvim'
    Plug 'williamboman/mason-lspconfig.nvim'
    Plug 'neovim/nvim-lspconfig'

    " Formatting and indentation
    Plug 'editorconfig/editorconfig-vim'
    Plug 'junegunn/vim-easy-align'

    " Fuzzy finding
    Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }

    " Linting, fixing, and completion
    "Plug 'neoclide/coc.nvim', {'branch': 'release'}
    Plug 'dense-analysis/ale'
    Plug 'davidhalter/jedi-vim'  " Python autocompletion
    Plug 'rhysd/vim-grammarous'  " LanguageTool
    Plug 'preservim/vim-wordy'   " Pure-vimscript grammar checker

    " Keys
    Plug 'tpope/vim-unimpaired'

    " Copilot/LLMs
    Plug 'github/copilot.vim', {'branch': 'release'}

    " Highlight
    Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

    " Snippets
    "Plug 'SirVer/ultisnips'

    " UI
    Plug 'Shougo/unite.vim'
    Plug 'Yggdroot/indentLine'

    Plug 'vim-airline/vim-airline'
    Plug 'vim-airline/vim-airline-themes'

    Plug 'frankier/neovim-colors-solarized-truecolor-only'
    Plug 'kshenoy/vim-signature'
    Plug 'ap/vim-css-color'

    " Language pack
    " Contains lots of stuff like:
    "  - python-syntax
    "  - vim-javascript
    "  - vim-markdown
    "  - vim-solidity
    "  - rust.vim
    "  - vim-ruby
    "  - vim-go
    "  - and many many more...
    Plug 'sheerun/vim-polyglot'

    " Language specific
    Plug 'posva/vim-vue'
    Plug 'digitaltoad/vim-pug'
    Plug 'lervag/vimtex'

    " Tracking
    Plug 'ActivityWatch/aw-watcher-vim'
    "Plug 'wakatime/vim-wakatime'

    " Navigation
    Plug 'haya14busa/incsearch.vim'
    Plug 'preservim/nerdtree'
    Plug 'Xuyuanp/nerdtree-git-plugin'
    Plug 'preservim/nerdcommenter'
    Plug 'christoomey/vim-tmux-navigator'

    " Makes everything slow/refuses to exit when processing a lot of stuff...
    "Plug 'ludovicchabant/vim-gutentags'

    " Auto import for JS/TS (with vue support)
    Plug 'kristijanhusak/vim-js-file-import', {'do': 'npm install'}

    " vim-signify
    if has('nvim') || has('patch-8.0.902')
      Plug 'mhinz/vim-signify'
    else
      Plug 'mhinz/vim-signify', { 'branch': 'legacy' }
    endif
call plug#end()

" Config copilot
let g:copilot_filetypes = {
\    'markdown': v:true,
\    'vue': v:true,
\    'yml': v:true,
\}

" Set up vim-js-file-import
let g:js_file_import_from_root = 1
let g:js_file_import_root = getcwd().'/src'
let g:js_file_import_root_alias = '@/'
let g:js_file_import_no_mappings = 1
nmap <C-i> <Plug>(JsFileImport)
nmap <C-u> <Plug>(PromptJsFileImport)
nmap <C-g> <Plug>(JsGotoDefinition)
set tagfunc=jsfileimport#tagfunc

" Enable syntax highlighting
syntax on

" Conceal config
set conceallevel=2
set concealcursor="n"  " Always disable conceal on current line, regardless of mode
"let g:indentLine_setConceal = 0
let g:indentLine_conceallevel = 2
let g:indentLine_concealcursor = "n"
" default ''.
" n for Normal mode
" v for Visual mode
" i for Insert mode
" c for Command line editing, for 'incsearch'

" Sets indentLine
let g:indentLine_char = '▏'
" let g:indentLine_char_list = ['|', '¦', '┆', '┊']

" Enable search highlighting
set hlsearch

" Use lighter color scheme
let g:solarized_termcolors=256
let g:solarized_termtrans=1
set background=dark
colorscheme solarized
"colorscheme tender
"highlight Normal guibg=black guifg=white ctermbg=None

" Syntastic config

set statusline+=%#warningmsg#
"set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

" Ale linters

let g:ale_linters = {
\   'python': ['bandit', 'flake8', 'mypy', 'ruff'],
\   'javascript': ['jshint', 'eslint'],
\   'typescript': ['eslint', 'tslint'],
\}

" Auto-detect poetry
let g:ale_python_auto_poetry = 1

" E225: Missing whitespace around operator
" E265: Block comment should start with '# '
" E402: Module level import not at top of file
" E501: Line too long
" W503: Line break occurred before a binary operator
let g:ale_python_flake8_options='--ignore=E203,E225,E265,E402,E501,W503 --builtins=Analysis,PYZ,EXE,BUNDLE,MERGE,COLLECT'
let g:ale_python_mypy_options='--ignore-missing-imports --check-untyped-defs --disable-error-code name-defined'
let g:ale_python_autoflake_options='--remove-unused-variables --ignore-init-module-imports --ignore-pass-after-docstring --in-place'
let g:ale_python_autoimport_options=''
let g:ale_python_reorderpythonimports_options='--py38-plus'
let g:ale_python_isort_options='--profile black --force-grid-wrap 4'
let g:ale_python_bandit_options='--skip B101'

"let black_args='--skip-string-normalization'
"let g:ale_python_black_options=black_args

" Ale fixers

" NOTE: There is also https://github.com/hadialqattan/pycln which only removes unused imports (subset of autoimport)
let g:ale_fixers = {
\   'python': ['autoflake', 'autoimport', 'reorder-python-imports', 'isort', 'autopep8', 'black', 'ruff'],
\   'javascript': ['prettier'],
\   'javascriptreact': ['prettier'],
\   'typescript': ['prettier'],
\   'typescriptreact': ['prettier'],
\   'vue': ['prettier'],
\   'rust': ['rustfmt'],
\}
let g:ale_rust_cargo_use_clippy = executable('cargo-clippy')
let g:ale_fix_on_save=1


" Disable showing diff after :Autopep8
let g:autopep8_disable_show_diff=1

" UltiSnip
let g:UltiSnipsExpandTrigger="<c-s>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"

" NERD Commenter
" Use compact syntax for prettified multi-line comments
let g:NERDCompactSexyComs = 1
" Align line-wise comment delimiters flush left instead of following code indentation
let g:NERDDefaultAlign = 'left'

" Thing to make .vue linting less slow (at the cost of disabling highlighting)
" https://github.com/posva/vim-vue/blob/3cc4ac7b02b4ee76a5f16d8b39bf559042f6b266/readme.md#vim-slows-down-when-using-this-plugin-how-can-i-fix-that
" let g:vue_disable_pre_processors=1

" Disables polyglot for .vue files, potentially fixing slowness (https://github.com/posva/vim-vue/issues/95#issuecomment-538705061)
" After testing, there was no significant difference...
"let g:polyglot_disabled = ['vue']

" Show the git diff in vim when commiting
" Stolen from:
"   https://github.com/Coornail/coornails_dotfiles/blob/master/.vimrc#L131
autocmd FileType gitcommit DiffGitCached | wincmd p

" Highlight occurences of selected word
autocmd CursorMoved * exe printf('match IncSearch /\V\<%s\>/', escape(expand('<cword>'), '/\'))

" Needed to make .pyi files highlight as Python files
au BufNewFile,BufRead *.pyi set filetype=python
au BufNewFile,BufRead *.ipy set filetype=python

" .abi files are probably JSON files
au BufNewFile,BufRead *.abi set filetype=json

au BufNewFile,BufRead *.jrag set filetype=java

au BufNewFile,BufRead *.env.* set filetype=sh

" Show the syntax highlight group under cursor
nnoremap <Leader>hi <cmd>echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<'
    \ . synIDattr(synID(line("."),col("."),0),"name") . "> lo<"
    \ . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"<cr>

" fails on erb-main2-arch
lua require('plugins')
