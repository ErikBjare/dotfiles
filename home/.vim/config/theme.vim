" Theme and UI Configuration
"
" Summary:
"  - Solarized dark theme is used
"  - Airline is configured for status line
"  - Custom statusline configuration

" Solarized theme
let g:solarized_termcolors=256
let g:solarized_termtrans=1
set background=dark
colorscheme solarized

" Status line
set statusline+=%#warningmsg#
set statusline+=%*

" Syntastic (commented out as you're using ALE)
" set statusline+=%{SyntasticStatuslineFlag()}

" Autopep8
let g:autopep8_disable_show_diff=1

" Show syntax highlight group under cursor
nnoremap <Leader>hi <cmd>echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<'
    \ . synIDattr(synID(line("."),col("."),0),"name") . "> lo<"
    \ . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"<cr>
