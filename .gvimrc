if has('unix')
  set guifont=Fira\ Mono\ for\ Powerline\ 11
endif

if has('kaoriya')
  set guifont=Ricty\ Diminished\ Discord:h13
endif

if has('mac')
  set guifont=Ricty:h13
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

" function! GuiTabLabel()
"   let l:label = ''
"   let l:bufnrlist = tabpagebuflist(v:lnum)
"   let l:bufname = fnamemodify(bufname(l:bufnrlist[tabpagewinnr(v:lnum) - 1]), ':t')
"   let l:label .= l:bufname == '' ? 'No title' : l:bufname
"   for bufnr in l:bufnrlist
"     if getbufvar(bufnr, "&modified")
"       let l:label .= ' ☆彡 '
"       break
"     endif
"   endfor
"   return l:label
" endfunction
