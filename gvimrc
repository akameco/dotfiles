if has('unix')
  set guifont=Fira\ Mono\ for\ Powerline\ 11
endif

if has('kaoriya')
  set guifont=Ricty\ Diminished\ Discord:h13
endif

if has('mac')
  set guifont=Ricty\ for\ Powerline:h13
endif

colorscheme gruvbox

set background=dark

set guioptions-=T
set guioptions-=r
set guioptions-=l
set guioptions-=m
set visualbell t_vb=

source $VIMRUNTIME/delmenu.vim
set langmenu=ja_jp.utf-8
source $VIMRUNTIME/menu.vim

