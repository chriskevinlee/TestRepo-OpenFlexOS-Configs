" Show absolute line number on the current line
" and relative line numbers on all other lines
set number relativenumber

" Highlight all search matches
set hlsearch

" Enable syntax highlighting
syntax on

" Always display the status line
set laststatus=2

" Show search matches as you type
set incsearch

" Make search case-insensitive
set ignorecase

" Automatically indent new lines
set autoindent
set smartindent
filetype plugin indent on


set statusline=%f\ [%{ModeName()}]\ %l:%c
function! ModeName()
  let l:m = mode()
  return l:m ==# 'n'  ? 'NORMAL'  :
        \ l:m ==# 'i'  ? 'INSERT'  :
        \ l:m ==# 'v'  ? 'VISUAL'  :
        \ l:m ==# 'V'  ? 'V-LINE'  :
        \ l:m ==# "\<C-v>" ? 'V-BLOCK' :
        \ l:m ==# 'R'  ? 'REPLACE' :
        \ 'OTHER'
endfunction
