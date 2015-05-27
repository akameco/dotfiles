set nocompatible

" 文字コード, 改行コード
set encoding=utf-8
set fileformats=unix,dos,mac

" NeoBundle{{{
" NeoBundle setting {{{
if has('vim_starting')
  set runtimepath+=~/.vim/bundle/neobundle.vim/
endif

call neobundle#begin(expand('~/.vim/bundle/'))

filetype off

NeoBundleFetch 'Shougo/neobundle.vim'
NeoBundle 'Shougo/vimproc.vim', {
      \ 'build' : {
      \     'windows' : 'tools\\update-dll-mingw',
      \     'cygwin' : 'make -f make_cygwin.mak',
      \     'mac' : 'make -f make_mac.mak',
      \     'linux' : 'make',
      \     'unix' : 'gmake',
      \    },
      \ }
" }}}

" Unite {{{
NeoBundle 'Shougo/unite.vim'
NeoBundle 'Shougo/neomru.vim'
"}}}

" neocon{{{
NeoBundleLazy 'Shougo/neosnippet', { 'autoload' : {
      \   'insert' : 1,
      \ }}
NeoBundle 'Shougo/neosnippet-snippets'
NeoBundleLazy 'Shougo/neocomplete', { 'autoload' : {
      \   'insert' : 1,
      \ }}
"}}}

" colorschemes plugin {{{
NeoBundle 'morhetz/gruvbox'
NeoBundle 'altercation/vim-colors-solarized'
" }}}

" ruby rails{{{
NeoBundleLazy 'thinca/vim-quickrun',{ 'autoload':{ 'filetypes': 'ruby'}}
NeoBundleLazy 'scrooloose/syntastic',{ 'autoload':{ 'filetypes': ['ruby','javascript']}}
NeoBundleLazy 'vim-ruby/vim-ruby',{ 'autoload':{ 'filetypes': 'ruby'}}
NeoBundleLazy 'tpope/vim-rails',{ 'autoload':{ 'filetypes': 'ruby'}}
NeoBundleLazy 'tpope/vim-endwise',{ 'autoload':{ 'filetypes': 'ruby'}}
NeoBundleLazy 'kchmck/vim-coffee-script', {
      \ 'autoload':{ 'filetypes': 'coffee'}}
NeoBundleLazy 'basyura/unite-rails',{ 'autoload':{ 'filetypes': 'ruby'}}
NeoBundleLazy 'slim-template/vim-slim', {'autoload':{'filetypes': 'slim'}}
"}}}

" 編集 {{{
NeoBundle 'godlygeek/tabular'
NeoBundle 'vim-scripts/surround.vim'
NeoBundle 'godlygeek/tabular'
" NeoBundle 'cohama/lexima.vim'
NeoBundle 'scrooloose/nerdcommenter'
NeoBundle 'koron/imcsc-vim'             " IM制御
" }}}

" スタイル{{{
NeoBundle 'itchyny/lightline.vim'
NeoBundle 'nathanaelkane/vim-indent-guides'
NeoBundle 'LeafCage/foldCC'
"}}}

" git {{{
NeoBundle 'tpope/vim-fugitive'
NeoBundle 'gregsexton/gitv'
NeoBundle 'airblade/vim-gitgutter'
" }}}}

" javascript{{{
NeoBundleLazy 'moll/vim-node', {
      \'autoload': { 'filetypes': ['javascript'] }}
NeoBundleLazy 'jelera/vim-javascript-syntax',{
      \ 'autoload':{ 'filetypes':['javascript'] }}
"}}}

" html {{{
NeoBundleLazy 'othree/html5.vim', {
      \ 'autoload': { 'filetypes': 'html' }}
NeoBundleLazy 'mattn/emmet-vim', {
      \ 'autoload': { 'filetypes': 'html' }}
"}}}

" other plugin {{{
NeoBundleLazy 'lilydjwg/colorizer', {
      \ 'autoload': { 'filetypes': ['html', 'css', 'scss'] }}
NeoBundle 'vim-jp/vimdoc-ja'
NeoBundle 'mattn/yamada-vim'
" }}}

" textobj {{{
NeoBundle 'kana/vim-textobj-user'
NeoBundle 'kana/vim-niceblock'
NeoBundle "osyo-manga/vim-textobj-multiblock"
NeoBundleLazy 'nelstrom/vim-textobj-rubyblock', {
      \ 'autoload':{ 'filetypes': 'ruby' }}
" }}}

" vimshell, vimfiler {{{
NeoBundleLazy 'Shougo/vimfiler', {
      \   'depends' : 'Shougo/unite.vim',
      \   'autoload' : {
      \       'commands' : [ 'VimFilerTab', 'VimFiler', 'VimFilerExplorer', 'VimFilerBufferDir' ],
      \       'mappings' : ['<Plug>(vimfiler_switch)'],
      \       'explorer' : 1,
      \   }}

NeoBundleLazy 'Shougo/vimshell', {
      \ 'depends' : 'Shougo/vimproc',
      \ 'autoload' : {
      \   'commands' : ['VimShell', 'VimShellExecute', 'VimShellPop', 'VimShellBufferDir'],
      \ }}
" }}}

call neobundle#end()
filetype plugin indent on
syntax enable

NeoBundleCheck
"}}}

" augroup init (from tyru's vimrc){{{
augroup vimrc
  autocmd!
augroup END

command!
      \ -bang -nargs=*
      \ MyAutocmd
      \ autocmd<bang> vimrc <args>
"}}}

" vimrc{{{
" vimrcを素早く読み込み
nnoremap <Space>. :<C-u>edit $MYVIMRC<CR>
nnoremap <Space>, :<C-u>source $MYVIMRC<CR>
"}}}

" Edit {{{
set autoindent            " 改行時に前のindentを継続する
set bs=indent,eol,start   " バックスペースが色々消せるように
set nowritebackup         " バックアップを取らない
set nobackup              " バックアップを取らない
set noswapfile            " バックアップを取らない
set autoread              " 外部で変更された時自動読み込み
set infercase             " 補完時大/小文字修正
set virtualedit=block       " カーソル移動の制限をなくす
set tabstop=2             " タブを何文字として表示するか
set shiftwidth=2          " タブの幅
set shiftround            " swの分の倍数で丸め込み
set smarttab              " shiftwidthの分だけスペース挿入
set expandtab             " タブをスペースに
set incsearch             " 即時検索
set ignorecase            " 検索で大/小文字区別しない
set smartcase             " 検索で大文字で区別
set wrapscan              " 検索末尾で先頭に戻る
set hlsearch              " 検索をハイライト
set scrolloff=5           " 5行余裕を持ってスクロール
set noshowmode            " modeによるメッセージを非表示
set wildmenu              " command-lineでのタブ補完
set wildmode=list:full    " 補完時の一覧表示有効化
set showcmd               " 入力中のコマンドを表示
set cmdheight=2           " メッセージ表示欄を2行表示
set laststatus=2          " ステータスラインを常に表示
set history=200           " command-line history
set showmatch             " 開き括弧を表示
set matchtime=1           " 対応する括弧を1秒のみ表示
set modeline              " modelineを有効にする
set hidden                " 保存されていないファイルを開く
set display=uhex          " 表示できない文字を16進数で表示
set splitbelow            " 新しく開くときに下に開く
set splitright            " 新しく開くときに右に開く
set switchbuf=useopen     " 同じウィンドウを使って開く
set textwidth=0           " 自動的な改行無効
set wildoptions=tagfile   " command-lineの補完にtagを追加
set ambiwidth=double      " 2バイト文字を正しく表示
set showtabline=2         " tablineを常に表示
set visualbell t_vb=      " ビープ音を無効にする
set noerrorbells          " エラー時にビープを鳴らさない
nohlsearch                " vimrcのhighlightをリセット

" コメントアウトを継続しない
MyAutocmd FileType * setlocal formatoptions-=ro 

" 編集履歴を保存して終了する{{{
" if has('persistent_undo') && isdirectory($HOME.'/.vim/undo')
  " set undodir=~/.vim/undo
  " set undofile
" endif
"}}}

" windows環境では.un~を一箇所にまとめる{{{
if has('kaoriya')
  set undodir=~/.vim/undo
endif
"}}}

" 最後に編集した場所にカーソルを移動する{{{
" MyAutocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif
"}}}

" ファイルの位置をカレントディレクトリに{{{
" gitvでエラー出るので除外設定したい
if has('unix')
  " MyAutocmd BufEnter * execute 'lcd ' fnameescape(expand('%:p:h'))
endif
" 編集中のファイルのディレクトリに移動
nnoremap ,d :execute ":lcd" . expand("%:p:h")<CR>
"}}}

" 折り畳み設定 {{{
set foldmethod=marker
nnoremap <silent> ,fc :<C-u>%foldclose<CR>
nnoremap <silent> ,fo :<C-u>%foldopen<CR>
set foldtext=FoldCCtext()
"}}}

" クリップボード{{{
set clipboard^=unnamedplus,unnamed
" set paste
" nnoremap <silent> <F1> :<C-u>set paste!<CR>:<C-U>echo("Toggle PasteMode => " . (&paste == 0 ? "Off" : "On"))<CR>
"}}}

" ファイルを整形 {{{
function! s:format_file()
  let view = winsaveview()
  normal gg=G
  silent call winrestview(view)
endfunction
nnoremap <Space>i :call <SID>format_file()<CR>
"}}}

" Tab {{{
" nnoremap <silent> gc :tablast <bar> tabnew<CR>
" nnoremap <silent> gl :tabnext<CR>
" nnoremap <silent> gh :tabprevious<CR>
" nnoremap <silent> gs :tab split<CR>
"}}}
"}}}

" File別シンタックス設定{{{
" MyAutocmd BufRead,BufNewFile,BufReadPre *.slim setlocal filetype=slim
" MyAutocmd FileType slim setlocal sw=2 sts=2 ts=2 et
" MyAutocmd BufRead,BufNewFile,BufReadPre *.coffee setlocal filetype=coffee
MyAutocmd FileType coffee,javascript setlocal shiftwidth=2 softtabstop=2 tabstop=2 expandtab
" MyAutocmd FileType coffee setlocal sw=2 sts=2 ts=2 et
" MyAutocmd FileType yaml setlocal expandtab ts=2 sw=2 fenc=utf-8
" MyAutocmd BufNewFile,BufRead *.md setlocal filetype=markdown
" markdown で改行がおかしくなるので(謎)
" MyAutocmd FileType markdown setlocal indentkeys-=o,O
"}}}

" key mapping {{{

nnoremap <silent> j gj
nnoremap <silent> k gk
vnoremap <silent> j gj
vnoremap <silent> k gk

" vvで文末まで選択
vnoremap v $h

inoremap '' ''<Esc>i
inoremap "" ""<Esc>i

" ハイライトを消す
nnoremap <silent> <ESC><ESC> :nohlsearch<CR><Esc>

nnoremap <Space>w <C-w>

"search center
nnoremap G Gzz
nnoremap <C-o> <C-o>zz

" tab
nnoremap <silent> gc :tablast <bar> tabnew<CR>
nnoremap <silent> gl :tabnext<CR>
nnoremap <silent> gh :tabprevious<CR>
nnoremap <silent> gs :tab split<CR>

" ,.変換
nnoremap ,. :%s/\./。/g<CR>
nnoremap ,, :%s/\,/、/g<CR>

" visual mode 括弧入力  {{{
" from http://vim-users.jp/2011/04/hack214/
vnoremap ( t(
vnoremap ) t)
vnoremap ] t]
vnoremap [ t[
onoremap ( t(
onoremap ) t)
onoremap ] t]
onoremap [ t[
" }}}

"}}}

" Display{{{
set title
set number         " 行数を表示 
set wrap           " 表示を改行
set colorcolumn=80 " 80行目にライン
set list           " 不可視文字表示
set ruler          " カーソルを常に表示

" デフォルト不可視文字は美しくないのでUnicodeで綺麗に
set listchars=tab:»-,trail:-,extends:»,precedes:«,nbsp:%,eol:↲

" background切り替え
nnoremap ,bl :<C-u>set background=light<CR>
nnoremap ,bd :<C-u>set background=dark<CR>

if has('gui_running')
  set t_Co=256
endif

" 全角スペースをハイライト{{{
if has('gui_running')
  " MyAutocmd ColorScheme * highlight ZenkakuSpace ctermbg=239 guibg=#405060
  " MyAutocmd VimEnter,WinEnter * call matchadd('ZenkakuSpace', '　')
endif
"}}}
"}}}

" Unite {{{
" nnoremap [unite] <Nop>
nmap <Space>f [unite]

" 最近閉じたファイル
nnoremap <silent> [unite]m   :<C-u>Unite file_mru<CR>
nnoremap <silent> [unite]a   :<C-u>Unite file_mru -buffer-name=files directory_mru file<CR>

nnoremap <silent> [unite]l   :<C-u>Unite -buffer-name=lines line<CR>
" nnoremap <silent> [unite]e   :<C-u>Unite file_rec/async:!<CR>
nnoremap <silent> [unite]f   :<C-u>UniteWithBufferDir -buffer-name=files file file/new<CR>
nnoremap <silent> [unite]c   :<C-u>Unite -buffer-name=commands history/command<CR>
nnoremap <silent> [unite]o   :<C-u>Unite -vertical -winwidth=45 -wrap -no-quit -toggle -buffer-name=outline outline<CR>
nnoremap <silent> [unite]b   :<C-u>Unite -buffer-name=bookmark -prompt=bookmark> bookmark<CR>
nnoremap <silent> [unite]r   :<C-u>Unite -buffer-name=register -prompt=">\  register<CR>
" nnoremap <silent> [unite]g   :<C-u>Unite -buffer-name=grep grep<CR>
" nnoremap <silent> [unite]i   :<C-u>Unite ref/refe -default-action=vsplit<CR>

let s:bundle = neobundle#get("unite.vim")
function! s:bundle.hooks.on_source(bundle)
  " 高速化
  let g:unite_source_file_mru_filename_format = ''
  " インサートモードで開始
  " let g:unite_enable_start_insert = 1
  let g:unite_enable_ignore_case = 1
  let g:unite_enable_smart_case = 1
  " windows環境
  let g:unite_source_grep_encoding='utf-8'

  let g:unite_winheight = 15
  let g:unite_winwidth = 45
  let g:unite_source_grep_max_candidates = 500
endfunction
unlet s:bundle
" }}}

" VimShell{{{
nnoremap <silent> <Space>vs :<C-u>VimShellBufferDir -split<CR>
nnoremap <silent> ,vs :<C-u>VimShell<CR>

" vimshllの時はwrapしていた方が見やすい
MyAutocmd FileType vimshell setlocal wrap
" MyAutocmd FileType vimshell AnsiEsc

let s:bundle = neobundle#get("vimshell")
function! s:bundle.hooks.on_source(bundle)
  let g:vimshell_prompt = "- "

  let g:vimshell_max_command_history = 3000
endfunction
unlet s:bundle
"}}}

" VimFiler{{{
nnoremap <silent> ,vf :<C-u>VimFilerBufferDir -simple<CR>
nnoremap <silent> <Space>e :<C-u>VimFilerBufferDir -split -simple -winwidth=35<CR>
let s:bundle = neobundle#get('vimfiler')
function! s:bundle.hooks.on_source(bundle)
  let g:vimfiler_safe_mode_by_default = 0
  let g:vimfiler_as_default_explorer = 1
  let g:vimfiler_max_directory_histories = 100
  " Like Textmate icons.
  let g:vimfiler_tree_leaf_icon = ' '
  let g:vimfiler_tree_opened_icon = '▾'
  let g:vimfiler_tree_closed_icon = '▸'
  let g:vimfiler_file_icon = '-'
  let g:vimfiler_marked_file_icon = '*'
endfunction
unlet s:bundle
"}}}

" rubycomplete.vim {{{
MyAutocmd FileType ruby setlocal omnifunc=rubycomplete#Complete
let g:rubycomplete_rails = 1
let g:rubycomplete_buffer_loading = 1
let g:rubycomplete_classes_in_global = 1
let g:rubycomplete_include_object = 1
let g:rubycomplete_include_object_space = 1
" let ruby_operators = 1
" }}}

" Rails {{{
" nnoremap [rails] <Nop>
nmap ,j [rails]

" unite rails
nnoremap <silent> [rails]m :<C-u>Unite rails/model<CR>
nnoremap <silent> [rails]v :<C-u>Unite rails/view<CR>
nnoremap <silent> [rails]c :<C-u>Unite rails/controller<CR>
nnoremap <silent> [rails]h :<C-u>Unite rails/helper<CR>
nnoremap <silent> [rails]l :<C-u>Unite rails/lib<CR>
nnoremap <silent> [rails]d :<C-u>Unite rails/db<CR>
nnoremap <silent> [rails]s :<C-u>Unite rails/spec<CR>
nnoremap <silent> [rails]r :<C-u>Unite rails/route<CR>
"}}}

" neosnippet {{{
let g:neosnippet#snippets_directory='~/.vim/bundle/neosnippet-snippets/neosnippets,~/.vim/snippets'
imap <C-k> <Plug>(neosnippet_expand_or_jump)
smap <C-k> <Plug>(neosnippet_expand_or_jump)
xmap <C-k> <Plug>(neosnippet_expand_target)
xmap <C-l> <Plug>(neosnippet_start_unite_snippet_target)

" http://qiita.com/alpaca_taichou/items/ab2ad83ddbaf2f6ce7fb
" http://qiita.com/muran001/items/4a8ffafb9c6564313893
" enable ruby & rails snippet

" function! s:RailsSnippet()
  " if exists("b:rails_root")
    " let s:current_file_path = expand("%:p:h")
    " app/modlesフォルダ内
    " if ( s:current_file_path =~ "app/models" )
      " NeoSnippetSource ~/.vim/snippets/ruby.rails.model.snip
      " app/controllersフォルダ内
    " elseif ( s:current_file_path =~ "app/controllers" )
      " NeoSnippetSource ~/.vim/snippets/ruby.action_controller.snip
      " NeoSnippetSource ~/.vim/snippets/ruby.abstract_controller.snip
      " app/viewsフォルダ内
    " elseif ( s:current_file_path =~ "app/views" )
      " NeoSnippetSource ~/.vim/snippets/ruby.action_view.snip
      " configフォルダ内
    " elseif ( s:current_file_path =~ "config" )
      " NeoSnippetSource ~/.vim/snippets/ruby.rails.route.snip
      " dbフォルダ内
    " elseif ( s:current_file_path =~ "db" )
      " NeoSnippetSource ~/.vim/snippets/ruby.active_record.migration.snip
    " endif
  " endif
" endfunction

" MyAutocmd BufEnter *.rb call s:RailsSnippet()
MyAutocmd BufEnter *rb NeoSnippetSource ~/.vim/snippets/ruby.snip
" MyAutocmd BufEnter *_spec.rb NeoSnippetSource ~/.vim/snippets/rspec.snip
" MyAutocmd BufEnter Gemfile NeoSnippetSource ~/.vim/snippets/Gemfile.snip
"}}}

" neocomplete {{{

" Enable omni completion.
MyAutocmd FileType css,scss setlocal omnifunc=csscomplete#CompleteCSS
MyAutocmd FileType html setlocal omnifunc=htmlcomplete#CompleteTags
MyAutocmd FileType sql setlocal omnifunc=sqlcomplete#Complete

if has('lua')
  let s:bundle = neobundle#get('neocomplete')
  function! s:bundle.hooks.on_source(bundle)
    " Disable AutoComplPop.
    let g:acp_enableAtStartup = 0
    " Enable at startup
    let g:neocomplete#enable_at_startup = 1
    " Use smartcase.
    let g:neocomplete#enable_smart_case = 1

    " length need to start completion  
    let g:neocomplete#auto_completion_start_length = 2
    let g:neocomplete#manual_completion_start_length = 0
    " 3文字からキャッシュ
    let g:neocomplete#sources#syntax#min_keyword_length = 3
    let g:neocomplete#enable_prefetch = 1

    let g:neocomplete#lock_buffer_name_pattern = '\*ku\*'

    " Define dictionary.
    let g:neocomplete#sources#dictionary#dictionaries = {
          \ 'default' : '',
          \ 'vimshell' : $HOME . '/.vimshell/command-history',
          \ }

    " キャッシュしないファイル名
    let g:neocomplete#sources#buffer#disabled_pattern = '\.log\|\.log\.\|\.jax'
    " 自動補完を行わないバッファ名
    let g:neocomplete#lock_buffer_name_pattern = '\.log\|\.log\.\|.*quickrun.*\|.jax'

    " Define keyword.
    if !exists('g:neocomplete#keyword_patterns')
      let g:neocomplete#keyword_patterns = {}
    endif
    let g:neocomplete#keyword_patterns['default'] = '\h\w*'

    " Plugin key-mappings.
    inoremap <expr><C-l> neocomplete#complete_common_string()

    " Recommended key-mappings.
    " <C-h>, <BS>: close popup and delete backword char.
    inoremap <expr><C-h> neocomplete#smart_close_popup()."\<C-h>"
    inoremap <expr><BS>  neocomplete#smart_close_popup()."\<C-h>"
    inoremap <expr><C-y> neocomplete#close_popup()
    inoremap <expr><C-n> pumvisible() ? "\<C-n>" : "\<C-x>\<C-u>\<C-p>"

    " Enable heavy omni completion.
    if !exists('g:neocomplete#sources#omni#input_patterns')
      let g:neocomplete#sources#omni#input_patterns = {}
    endif
    let g:neocomplete#sources#omni#input_patterns.ruby =
          \ '[^. *\t]\.\w*\|\h\w*::'
    " if !exists('g:neocomplete#force_omni_input_patterns')
    " let g:neocomplete#force_omni_input_patterns = {}
    " endif
    " let g:neocomplete#force_omni_input_patterns.ruby =
    " \ '[^. *\t]\.\w*\|\h\w*::'

    "インクルード文のパターンを指定
    let g:neocomplete#include_patterns = {
          \ 'ruby' : '^\s*require',
          \ 'javascript' : '^\s*require',
          \ }

    "インクルード先のファイル名の解析パターン
    let g:neocomplete#include_exprs = {
          \ 'ruby' : substitute(v:fname,'::','/','g')
          \ }

    " ファイルを探す際に、この値を末尾に追加したファイルも探す。
    let g:neocomplete#include_suffixes = {
          \ 'ruby' : '.rb',
          \ }
  endfunction
endif
"}}}

" surround.vim {{{
nmap ,( csw(
nmap ,) csw)
nmap ,{ csw{
nmap ,} csw}
nmap ,[ csw[
nmap ,] csw]
nmap ,' csw'
nmap ," csw"
nmap <C-s> ysW"
"}}}

" indentguide {{{
let g:indent_guides_enable_on_vim_startup = 1
let g:indent_guides_guide_size =  1
let g:indent_guides_auto_colors = 0
let g:indent_guides_color_change_percent = 25
MyAutocmd VimEnter,Colorscheme * :hi IndentGuidesOdd  guibg=#2f4f4f ctermbg=darkgrey
MyAutocmd VimEnter,Colorscheme * :hi IndentGuidesEven guibg=#696969 ctermbg=12
" }}}

" other plugins{{{
" nerdcommenter
let g:NERDCreateDefaultMappings = 0
let g:NERDSpaceDelims = 1
nmap <Space>/ <Plug>NERDCommenterToggle
vmap <Space>/ <Plug>NERDCommenterToggle

" clever f
let g:clever_f_smart_case = 1
let g:clever_f_use_migemo = 1

" memo(これが最速)
nnoremap <Space>mm :edit ~/Dropbox/Memo/todo.md<CR>

" textobj
omap ab <Plug>(textobj-multiblock-a)
omap ib <Plug>(textobj-multiblock-i)
vmap ab <Plug>(textobj-multiblock-a)
vmap ib <Plug>(textobj-multiblock-i)
"}}}

" lightline {{{
command! -bar LightlineUpdate    call lightline#init()|
      \ call lightline#colorscheme()|
      \ call lightline#update()
let g:lightline = {
      \ 'colorscheme': 'wombat',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \           [ 'fugitive', 'filename', 'gitgutter']],
      \   'right': [ [ 'percent' , 'absolute'],
      \            [ 'fileformat', 'fileencoding', 'filetype']]
      \ },
      \ 'component_function': {
      \   'fugitive': 'MyFugitive',
      \   'filename': 'MyFilename',
      \   'fileformat': 'MyFileformat',
      \   'filetype': 'MyFiletype',
      \   'fileencoding': 'MyFileencoding',
      \   'mode': 'MyMode',
      \   'gitgutter': 'MyGitGutter', 
      \ },
      \ 'separator': { 'left': '', 'right': '' },
      \ 'subseparator': { 'left': '', 'right': '' }
      \ }

function! MyModified()
  return &ft =~ 'help\|vimfiler' ? '' : &modified ? '+' : &modifiable ? '' : '-'
endfunction

function! MyReadonly()
  return &ft !~? 'help\|vimfiler' && &readonly ? '' : ''
endfunction

function! MyFilename()
  let fname = expand('%:t')
  return fname == 'Tagbar' ? g:lightline.fname :
        \ &ft == 'vimfiler' ? vimfiler#get_status_string() :
        \ &ft == 'unite' ? unite#get_status_string() :
        \ &ft == 'vimshell' ? vimshell#get_status_string() :
        \ ('' != MyReadonly() ? MyReadonly() . ' ' : '') .
        \ ('' != fname ? fname : '[No Name]') .
        \ ('' != MyModified() ? ' ' . MyModified() : '')
endfunction

function! MyFugitive()
  if &ft !~? 'vimfiler' && exists("*fugitive#head")
    let _ = fugitive#head()
    return strlen(_) ? ' '._ : ''
  endif
  return ''
endfunction

function! MyFileformat()
  return winwidth(0) > 80 ? &fileformat : ''
endfunction

function! MyFiletype()
  return winwidth(0) > 70 ? (strlen(&filetype) ? &filetype : 'no ft') : ''
endfunction

function! MyFileencoding()
  return winwidth(0) > 80 ? (strlen(&fenc) ? &fenc : &enc) : ''
endfunction

function! MyMode()
  let fname = expand('%:t')
  return fname == 'Tagbar' ? 'Tagbar' :
        \ &ft == 'unite' ? 'Unite' :
        \ &ft == 'vimfiler' ? 'VimFiler' :
        \ &ft == 'vimshell' ? 'VimShell' :
        \ winwidth(0) > 60 ? lightline#mode() : ''
endfunction

function! MyGitGutter()
  if ! exists('*GitGutterGetHunkSummary')
        \ || ! get(g:, 'gitgutter_enabled', 0)
        \ || winwidth('.') <= 90
    return ''
  endif
  let symbols = [
        \  g:gitgutter_sign_added . ' ' ,
        \  g:gitgutter_sign_modified . ' ' ,
        \  g:gitgutter_sign_removed . ' '
        \ ]
  let hunks = GitGutterGetHunkSummary()
  let ret = []
  for i in [0, 1, 2]
    if hunks[i] > 0
      call add(ret, symbols[i] . hunks[i])
    endif
  endfor
  return join(ret, ' ')
endfunction

let g:unite_force_overwrite_statusline = 0
let g:vimfiler_force_overwrite_statusline = 0
let g:vimshell_force_overwrite_statusline = 0
"}}}

" Fugitive {{{
" nnoremap [git] <Nop>
nmap ,g [git]
nnoremap [git]d :<C-u>Gdiff HEAD<CR>
nnoremap [git]s :<C-u>Gstatus<CR>
nnoremap [git]l :<C-u>Glog<CR>
nnoremap [git]a :<C-u>Gwrite<CR>
nnoremap [git]c :<C-u>Gcommit<CR>
nnoremap [git]C :<C-u>Git commit --amend<CR>
nnoremap [git]b :<C-u>Gblame<CR>
MyAutocmd BufEnter * if expand("%") =~ ".git/COMMIT_EDITMSG" | set ft=gitcommit | endif
MyAutocmd BufEnter * if expand("%") =~ ".git/rebase-merge" | set ft=gitrebase | endif
" }}}

" gitv {{{
nnoremap [git]v :<C-u>Gitv<CR>
MyAutocmd FileType gitv setlocal foldlevel=99
" }}}

" tabular {{{
nmap ,a= :<C-u>Tabularize /=<CR>
vmap ,a= :<C-u>Tabularize /=<CR>
nmap ,a: :<C-u>Tabularize /:\zs<CR>
vmap ,a: :<C-u>Tabularize /:\zs<CR>
" }}}

" 日本語{{{
" 日本語向け設定: Jで行をつなげた時に日本語の場合はスペースを入れない
set formatoptions+=Mm
" 。、に移動(f<C-K>._ を打つのは少し長いので)。cf<C-J>等の使い方も可。
function! s:MapFT(key, char)
  for cmd in ['f', 'F', 't', 'T']
    execute 'noremap <silent> ' . cmd . a:key . ' ' . cmd . a:char
  endfor
endfunction
call <SID>MapFT('<C-J>', '。')
call <SID>MapFT('<C-K>', '、')
"}}}
