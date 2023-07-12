" https://github.com/ThePrimeagen/vim-be-good
" docker run -it --rm brandoncc/vim-be-good:latest

set number
set relativenumber

nnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz

nnoremap <C-f> <C-f>zz
nnoremap <C-b> <C-b>zz

nnoremap n nzzzv
nnoremap N Nzzzv

" Copy to clipboard
set clipboard=unnamed,unnamedplus

" Only way to set smartcase
set ignorecase
set smartcase
set hlsearch
" Hit enter to clear highlighting
nnoremap <CR> :noh<CR><CR>

" Better window moving
nnoremap <c-h> <c-w>h
nnoremap <c-l> <c-w>l
nnoremap <c-j> <c-w>j
nnoremap <c-k> <c-w>k

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
