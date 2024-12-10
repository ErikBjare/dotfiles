" Plugin Configuration
"
" Summary:
"  - vim-plug is used for plugin management
"  - Plugins are organized by category
"  - Each section contains related configuration
"  - LSP support
"  - Linting and formatting (ALE)
"  - Navigation (NERDTree, fzf)
"  - Git integration (fugitive, signify)
"  - Language-specific plugins

" Pathogen
" Note: Consider removing Pathogen as vim-plug handles all plugin needs
let g:pathogen_disabled = []
if has('nvim')
    call add(g:pathogen_disabled, 'vim-geeknote')
    call add(g:pathogen_disabled, 'vim-colors-solarized')
endif
if !has('nvim')
    call add(g:pathogen_disabled, 'vim-geeknote')
    call add(g:pathogen_disabled, 'neovim-colors-solarized-truecolors-only')
endif
execute pathogen#infect()

" vim-plug
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')
    " My own plugins
    Plug 'ErikBjare/gptme.vim'

    " LSP
    Plug 'williamboman/mason.nvim', {'branch': 'main'}
    Plug 'williamboman/mason-lspconfig.nvim', {'branch': 'main'}
    Plug 'neovim/nvim-lspconfig'

    " A little bit of everything
    Plug 'echasnovski/mini.nvim', { 'branch': 'stable' }

    " Git
    Plug 'tpope/vim-fugitive'

    " Formatting and indentation
    Plug 'editorconfig/editorconfig-vim'
    Plug 'junegunn/vim-easy-align'

    " Fuzzy finding
    Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }

    " Linting, fixing, and completion
    Plug 'dense-analysis/ale'
    Plug 'rhysd/vim-grammarous'
    Plug 'preservim/vim-wordy'

    " Keys
    Plug 'folke/which-key.nvim'
    Plug 'tpope/vim-unimpaired'

    " Copilot/LLMs
    Plug 'github/copilot.vim', {'branch': 'release'}

    " Highlight
    Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

    " UI
    Plug 'Shougo/unite.vim'
    Plug 'Yggdroot/indentLine'
    Plug 'vim-airline/vim-airline'
    Plug 'vim-airline/vim-airline-themes'
    Plug 'frankier/neovim-colors-solarized-truecolor-only'
    Plug 'kshenoy/vim-signature'
    Plug 'ap/vim-css-color'

    " Language pack
    Plug 'sheerun/vim-polyglot'

    " Language specific
    Plug 'posva/vim-vue'
    Plug 'digitaltoad/vim-pug'
    Plug 'lervag/vimtex'

    " Tracking
    Plug 'ActivityWatch/aw-watcher-vim'

    " Navigation
    Plug 'haya14busa/incsearch.vim'
    Plug 'preservim/nerdtree'
    Plug 'Xuyuanp/nerdtree-git-plugin'
    Plug 'preservim/nerdcommenter'
    Plug 'christoomey/vim-tmux-navigator'

    " Auto import for JS/TS (with vue support)
    Plug 'kristijanhusak/vim-js-file-import', {'do': 'npm install'}

    " vim-signify
    if has('nvim') || has('patch-8.0.902')
      Plug 'mhinz/vim-signify'
    else
      Plug 'mhinz/vim-signify', { 'branch': 'legacy' }
    endif

    " Add nvim-web-devicons for better icon support
    Plug 'nvim-tree/nvim-web-devicons'
call plug#end()

" Copilot
let g:copilot_filetypes = {
\    'markdown': v:true,
\    'vue': v:true,
\    'yml': v:true,
\}

" vim-js-file-import
let g:js_file_import_from_root = 1
let g:js_file_import_root = getcwd().'/src'
let g:js_file_import_root_alias = '@/'
let g:js_file_import_no_mappings = 1
set tagfunc=jsfileimport#tagfunc

" IndentLine
let g:indentLine_char = '▏'
let g:indentLine_conceallevel = 2
let g:indentLine_concealcursor = "n"

" Airline
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1
let g:airline_theme='simple'

" Ale
let g:ale_linters = {
\   'python': ['bandit', 'flake8', 'mypy', 'ruff'],
\   'javascript': ['jshint', 'eslint'],
\   'typescript': ['eslint', 'tslint'],
\}

let g:ale_fixers = {
\   'python': ['autoflake', 'autoimport', 'reorder-python-imports', 'isort', 'black', 'ruff', 'ruff_format'],
\   'javascript': ['prettier'],
\   'javascriptreact': ['prettier'],
\   'typescript': ['prettier'],
\   'typescriptreact': ['prettier'],
\   'vue': ['prettier'],
\   'rust': ['rustfmt'],
\}

let g:ale_fix_on_save=1
let g:ale_rust_cargo_use_clippy = executable('cargo-clippy')
let g:ale_python_flake8_options='--ignore=E203,E225,E265,E402,E501,W503 --builtins=Analysis,PYZ,EXE,BUNDLE,MERGE,COLLECT'
let g:ale_python_mypy_options='--ignore-missing-imports --check-untyped-defs --disable-error-code name-defined'
let g:ale_python_autoflake_options='--remove-unused-variables --ignore-init-module-imports --ignore-pass-after-docstring --in-place'
let g:ale_python_autoimport_options=''
let g:ale_python_reorderpythonimports_options='--py38-plus'
let g:ale_python_isort_options='--profile black --force-grid-wrap 4'
let g:ale_python_bandit_options='--skip B101'

" UltiSnips
let g:UltiSnipsExpandTrigger="<c-s>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"

" NERD Commenter
let g:NERDCreateDefaultMappings = 1
let g:NERDCompactSexyComs = 1
let g:NERDDefaultAlign = 'left'

" Incsearch
let g:incsearch#auto_nohlsearch = 1
