"""""""""""""""""""""""""""""""""""""""""""""""""""""""
" General configuration
"

" Enable file type detection.
" Also load indent files, to automatically do language-dependent indenting.
"filetype plugin indent on
"filetype plugin on


" Use Vim settings, rather then Vi settings (much better!).
" This must be first, because it changes other options as a side effect.
set nocompatible
set autoindent
syntax on
set hlsearch
set incsearch		" do incremental searching
" Press Space to turn off highlighting and clear any message already displayed.
nnoremap <silent> <Space> :nohlsearch<Bar>:echo<CR>
colo desert
set number
set tabstop=4
set shiftwidth=4
set expandtab
inoremap jj <Esc>
inoremap jf <Esc>
inoremap <S-Tab> <C-V><Tab>

" Make backspace back up a tabstop. Especailly handy for editing Python
set smarttab

" allow backspacing over everything in insert mode
set backspace=indent,eol,start

set history=50		" keep 50 lines of command line history
set ruler		" show the cursor position all the time
set noshowcmd		" display incomplete commands
"set ignorecase          " case insensitive searching
set hidden		" allow hidden buffers
"in normal mode wrap lines and break at work boundries
set wrap
set linebreak

set showmatch           "show matching brackets
"
"Make <Tab> complete work like bash command line completion
set wildmode=longest,list

" Don't have the scratch buffer show up when there are multiple matches.
set completeopt=

" Turn on a fancy status line
set statusline=%m\ [File:\ %f]\ [Type:\ %Y]\ [ASCII:\ %03.3b]\ [Col:\ %03v]\ [Line:\ %04l\ of\ %L]
set laststatus=2 " always show the status line

"map killws to a command to remove trailing whitespace
command! Killws :% s/\s\+$//g

