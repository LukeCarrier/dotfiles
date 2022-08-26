set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
  Plugin 'gmarik/Vundle.vim'

  Plugin 'editorconfig/editorconfig-vim'

  Plugin 'vim-airline/vim-airline'
  Plugin 'vim-airline/vim-airline-themes'

  Plugin 'ctrlpvim/ctrlp.vim'

  Plugin 'preservim/tagbar'

  Plugin 'preservim/nerdtree'
  Plugin 'ryanoasis/vim-devicons'
  Plugin 'Xuyuanp/nerdtree-git-plugin'
call vundle#end()

filetype plugin indent on

set encoding=utf8

syntax on

set mouse=a

let &t_SI = "\e[6 q"
let &t_EI = "\e[2 q"

let g:airline_theme='wombat'
let g:airline#extensions#tabline#enabled = 1

let NERDTreeShowHidden=1

set number
set ruler

let mapleader = ","
map <silent> <Leader>t :NERDTreeToggle<CR>
