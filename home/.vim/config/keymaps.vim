" Key Mappings
"
" Summary:
"  - <Space> is the leader key
"  - <Leader>-b opens buffer search (using Unite)
"  - <Leader>-f opens file search (using Unite)
"  - <Leader>-n opens nerdtree
"  - <Leader><Leader> triggers easymotion
"  - <C-{h,j,k,l}> changes panes
"
" Navigation:
"  - gd: Go to definition
"  - gD: Go to declaration
"  - gi: Go to implementation
"  - gr: Find references
"  - gt: Go to type definition
"  - gf: Go to file
"  - K: Show hover information
"  - <C-k>: Show signature help
"  - <leader>rn: Rename symbol
"  - <leader>ca: Code action
"  - [d and ]d: Navigate to previous/next diagnostic
"  - <leader>f: Format document
"  - <C-]>: Go to definition (ctags)
"  - <C-t>: Jump back from definition
"  - <C-o> and <C-i>: Navigate through jump list (back and forward)
"  - %: Jump between matching brackets
"  - * and #: Search for word under cursor (forward and backward)


let mapleader = "\<Space>"

" Easymotion
map <Leader><Leader> <Plug>(easymotion-prefix)

" NERDTree
noremap <Leader>n :NERDTreeToggle<CR>

" LSP
" See ~/.config/nvim/plugin/lspconfig.lua

" Window config
" Split pane
noremap <Leader>ws :sp<CR>
noremap <Leader>wv :vsp<CR>

" Close pane
noremap <Leader>wc <C-W>c

" Clipboard copying
noremap <Leader>y "+y
noremap <Leader>p "+p

" Window switching with vim-tmux-navigator
nnoremap <silent> <C-J> :TmuxNavigateDown<CR>
nnoremap <silent> <C-K> :TmuxNavigateUp<CR>
nnoremap <silent> <C-L> :TmuxNavigateRight<CR>
nnoremap <silent> <C-H> :TmuxNavigateLeft<CR>
nnoremap <silent> <C-Up> :TmuxNavigateUp<CR>
nnoremap <silent> <C-Down> :TmuxNavigateDown<CR>
nnoremap <silent> <C-Right> :TmuxNavigateRight<CR>
nnoremap <silent> <C-Left> :TmuxNavigateLeft<CR>

" Terminal mode mappings for vim-tmux-navigator
tnoremap <silent> <C-J> <C-\><C-N>:TmuxNavigateDown<CR>
tnoremap <silent> <C-K> <C-\><C-N>:TmuxNavigateUp<CR>
tnoremap <silent> <C-L> <C-\><C-N>:TmuxNavigateRight<CR>
tnoremap <silent> <C-H> <C-\><C-N>:TmuxNavigateLeft<CR>
tnoremap <silent> <C-Up> <C-\><C-N>:TmuxNavigateUp<CR>
tnoremap <silent> <C-Down> <C-\><C-N>:TmuxNavigateDown<CR>
tnoremap <silent> <C-Right> <C-\><C-N>:TmuxNavigateRight<CR>
tnoremap <silent> <C-Left> <C-\><C-N>:TmuxNavigateLeft<CR>

" Move correctly in wrapped mode
noremap k gk
noremap j gj
noremap <Up> gk
noremap <Down> gj

" Use :Sw to save as root
command! -nargs=0 Sw w !sudo tee % > /dev/null

" ctrl+r in visual mode to replace
vnoremap <C-r> "hy:%s/<C-r>h//g<left><left>

" Unite mappings (legacy)
nnoremap <Leader>t :Unite tab<CR>
nnoremap <Leader>cc :Unite grammarous

" fzf mappings
nnoremap <C-p> :Files<CR>
nnoremap <Leader>b :Buffers<CR>
nnoremap <Leader>f :Files<CR>
nnoremap <Leader>ff :GFiles<CR>
nnoremap <Leader>rg :Rg<CR>
nnoremap <Leader>h :History<CR>

" Better incsearch with incsearch.vim
map /  <Plug>(incsearch-forward)
map ?  <Plug>(incsearch-backward)
map g/ <Plug>(incsearch-stay)

" Remove search highlight when non-search movement happens
map n  <Plug>(incsearch-nohl-n)
map N  <Plug>(incsearch-nohl-N)
map *  <Plug>(incsearch-nohl-*)
map #  <Plug>(incsearch-nohl-#)
map g* <Plug>(incsearch-nohl-g*)
map g# <Plug>(incsearch-nohl-g#)

" vim-easy-align
nmap ga <Plug>(EasyAlign)
xmap ga <Plug>(EasyAlign)

" fugitive git bindings
nnoremap <Leader>gs :Git<CR>
nnoremap <Leader>ga :Git add %:p<CR><CR>
nnoremap <Leader>gc :Gcommit -v -q<CR>
nnoremap <Leader>gt :Gcommit -v -q %:p<CR>
nnoremap <Leader>gd :Gvdiffsplit<CR>
nnoremap <Leader>ge :Gedit<CR>
nnoremap <Leader>gr :Gread<CR>
nnoremap <Leader>gw :Gwrite<CR><CR>
nnoremap <Leader>gl :Git log<CR>
nnoremap <Leader>gp :Ggrep<Space>
nnoremap <Leader>gm :Gmove<Space>
nnoremap <Leader>gb :Git branch<Space>
nnoremap <Leader>go :Git checkout<Space>
nnoremap <Leader>gps :Git push<CR>
nnoremap <Leader>gpl :Git pull<CR>

" Relative line numbers toggle
function! NumberToggle()
  if(&relativenumber == 1)
    set norelativenumber
  else
    set relativenumber
  endif
endfunc
nnoremap <C-n> :call NumberToggle()<cr>

" vim-js-file-import
nmap <C-i> <Plug>(JsFileImport)
nmap <C-u> <Plug>(PromptJsFileImport)
nmap <C-g> <Plug>(JsGotoDefinition)

" Show the syntax highlight group under cursor
nnoremap <Leader>hi <cmd>echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<'
    \ . synIDattr(synID(line("."),col("."),0),"name") . "> lo<"
    \ . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"<cr>
" GPTme mapping
vnoremap <Leader>g :w !gptme --non-interactive<Space>
