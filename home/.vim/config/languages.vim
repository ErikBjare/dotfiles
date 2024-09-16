" Language-specific Settings
"
" Summary:
"  - Specific configurations for various languages:
"    - HTML indentation
"    - Python linting and formatting options
"    - JavaScript/TypeScript import settings
"    - Rust clippy integration
"  - File type associations for special extensions

" HTML indentation
let g:html_indent_inctags = "html,body,head,tbody,p,li,a,span,header,footer,small,b,i"

" Markdown
au BufRead,BufNewFile *.md set filetype=markdown

" Python
let g:ale_python_flake8_options='--ignore=E203,E225,E265,E402,E501,W503 --builtins=Analysis,PYZ,EXE,BUNDLE,MERGE,COLLECT'
let g:ale_python_mypy_options='--ignore-missing-imports --check-untyped-defs --disable-error-code name-defined'
let g:ale_python_autoflake_options='--remove-unused-variables --ignore-init-module-imports --ignore-pass-after-docstring --in-place'
let g:ale_python_autoimport_options=''
let g:ale_python_reorderpythonimports_options='--py38-plus'
let g:ale_python_isort_options='--profile black --force-grid-wrap 4'
let g:ale_python_bandit_options='--skip B101'

" JavaScript/TypeScript
let g:js_file_import_from_root = 1
let g:js_file_import_root = getcwd().'/src'
let g:js_file_import_root_alias = '@/'

" Vue
" let g:vue_disable_pre_processors=1  " Uncomment if needed for performance

" Rust
let g:ale_rust_cargo_use_clippy = executable('cargo-clippy')

" File type associations
au BufNewFile,BufRead *.pyi set filetype=python
au BufNewFile,BufRead *.ipy set filetype=python
au BufNewFile,BufRead *.abi set filetype=json
au BufNewFile,BufRead *.jrag set filetype=java
au BufNewFile,BufRead *.env.* set filetype=sh
