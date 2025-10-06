" https://github.com/ThePrimeagen/vim-be-good
" docker run -it --rm brandoncc/vim-be-good:latest

" Options
set number
set relativenumber
set clipboard=unnamed,unnamedplus " Copy to clipboard
set ignorecase
set smartcase
set hlsearch

" Experimental Options
set nocompatible                  " disable compatibility to old-time vi
set showmatch                     " show matching brackets.
set mouse=v                       " middle-click paste with mouse
set autoindent                    " indent a new line the same amount as the line just typed
set wildmode=longest,list         " get bash-like tab completions
" set cc=88                       " set colour columns for good coding style
filetype plugin indent on         " allows auto-indenting depending on file type
set tabstop=4                     " number of columns occupied by a tab character
set expandtab                     " convert tabs to white space
set shiftwidth=4                  " width for autoindents
set softtabstop=4                 " see multiple spaces as tabstops so <BS> does the right thing
set nrformats+=alpha              " include alphabetic characters when doing CTRL-A and CTRL-X

nnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz
nnoremap <C-f> <C-f>zz
nnoremap <C-b> <C-b>zz
nnoremap n nzzzv
nnoremap N Nzzzv

" Hit enter to clear highlighting
nnoremap <CR> :noh<CR><CR>

" Better window moving
nnoremap <c-h> <c-w>h
nnoremap <c-l> <c-w>l
nnoremap <c-j> <c-w>j
nnoremap <c-k> <c-w>k
" Similar to i3 split horizontal
nnoremap <C-w>b <C-w>s

" Purpose: deleting after yanking outside of vim without overrwriting buffer
" blackhole register
let mapleader = " "

nmap <leader>y "_y
vmap <leader>y "_y

nmap <leader>d "_d
vmap <leader>d "_d

nmap <leader>p "_p
vmap <leader>p "_p

nmap <leader>P "_P
vmap <leader>P "_P

nmap <leader>D "_D
vmap <leader>D "_D

nmap <leader>C "_C
vmap <leader>C "_C

nmap <leader>x "_x
vmap <leader>x "_x

nmap <leader>s "_s
vmap <leader>s "_s
