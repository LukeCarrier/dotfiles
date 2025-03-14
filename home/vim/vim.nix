{ pkgs, ... }:
{
  programs.vim = {
    enable = true;

    plugins = with pkgs.vimPlugins; [
      editorconfig-vim

      vim-airline
      vim-airline-themes

      ctrlp-vim

      tagbar

      nerdtree
      nerdtree-git-plugin
      vim-devicons
    ];

    extraConfig = ''
      set nocompatible

      set nobackup
      set noswapfile

      filetype off
      filetype plugin indent on

      set encoding=utf8

      syntax on

      set mouse=a

      let &t_SI = "\e[6 q"
      let &t_EI = "\e[2 q"

      let g:airline_theme='wombat'
      let g:airline#extensions#tabline#enabled = 1

      let g:ctrlp_show_hidden = 1

      let NERDTreeShowHidden=1

      set number
      set relativenumber

      set wrap
      set linebreak

      set ruler

      set showmatch
      set autoindent
      set copyindent
      set shiftround

      nnoremap / /\v
      vnoremap / /\v
      set gdefault
      set ignorecase
      set smartcase
      set hlsearch
      set incsearch

      cmap w!! w !sudo tee >/dev/null %

      autocmd FocusLost * :wa

      nnoremap ; :
      nnoremap : ;

      nnoremap <space> <nop>
      let mapleader = " "

      map <silent> <Leader>t ;NERDTreeToggle<CR>

      set listchars=eol:¬,tab:>·,trail:~,extends:>,precedes:<,space:.
      noremap <F5> :set list!<CR>
      inoremap <F5> <C-o>:set list!<CR>
      cnoremap <F5> <C-c>:set list!<CR>
    '';
  };
}
