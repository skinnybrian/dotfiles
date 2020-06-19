"--------------------
" 保存系
"--------------------

" スワップファイルを作成しない
set noswapfile

" Buffer切り替え時に保存警告をしない
set hidden

"--------------------
" 表示系
"--------------------

" タイムアウト設定して表示高速化
set timeout timeoutlen=150

" 表示更新時間
set updatetime=250

" :intro 画面非表示
set shortmess+=I

" 行番号表示
set number

" シンタックスハイライト
syntax on

" 不可視文字表示
set list
set listchars=tab:»-,trail:·,eol:¬,extends:»,precedes:«,nbsp:%

" Enable Sign Column
set signcolumn=yes

" 言語を英語にする
language C

"--------------------
" 入力系
"--------------------

" "jj"でエスケープ(すばやく)
inoremap <silent> jj <ESC>

" 方向キー無効化
noremap <Up> <Nop>
noremap <Down> <Nop>
noremap <Left> <Nop>
noremap <Right> <Nop>

" タブ幅のスペース数
set tabstop=4

" 入力モードでTabキー押下時に半角スペースを挿入
set expandtab

" 自動インデント
set autoindent

" 自動インデントの空白数
set shiftwidth=4

" ヤンクでクリップボードにコピー
set clipboard=unnamed,autoselect

"" カーソルの形
" 挿入モード時に非点滅の縦棒タイプのカーソルで表示
let &t_SI .= "\e[6 q"
" ノーマルモード時に非点滅のブロックタイプのカーソルで表示
let &t_EI .= "\e[2 q"
" 置換モード時に非点滅の下線タイプのカーソルで表示
let &t_SR .= "\e[4 q"

" 現在の行を強調表示
set cursorline

" (USキーボード向け)コロンとセミコロン入れ替え
noremap ; :

" Gitで何も変更がないのにdiffが出てしまうのを回避。(No newline at end of file対策。set binary noeol だと改行時のインデントがタブになってしまうためnofixeolにした)
set nofixeol

" ペーストモード自動化
if &term =~ "xterm"
    let &t_ti .= "\e[?2004h"
    let &t_te .= "\e[?2004l"
    let &pastetoggle = "\e[201~"

    function XTermPasteBegin(ret)
        set paste
        return a:ret
    endfunction

    noremap <special> <expr> <Esc>[200~ XTermPasteBegin("0i")
    inoremap <special> <expr> <Esc>[200~ XTermPasteBegin("")
    cnoremap <special> <Esc>[200~ <nop>
    cnoremap <special> <Esc>[201~ <nop>
endif

"--------------------
" 検索系
"--------------------

" 検索するときに大文字小文字を区別しない
set ignorecase

" 小文字で検索すると大文字と小文字を無視して検索
set smartcase

" インクリメンタル検索(即座にいける)
set incsearch

" 検索結果ハイライト
set hlsearch

"--------------------
" 画面分割系
"--------------------

"--------------------
" 操作系
"--------------------

" <leader>を'\'から' 'へ
let mapleader = "\<Space>"

" fzf
nnoremap <silent> ,f :GFiles<CR>
nnoremap <silent> ,F :GFiles?<CR>
nnoremap <silent> ,b :Buffers<CR>
nmap <leader><tab> <plug>(fzf-maps-n)
xmap <leader><tab> <plug>(fzf-maps-x)
omap <leader><tab> <plug>(fzf-maps-o)

" git grep
command! -bang -nargs=* GGrep
    \ call fzf#vim#grep(
        \ 'git grep --line-number '.shellescape(<q-args>), 0,
        \ { 'dir': systemlist('git rev-parse --show-toplevel')[0] }, <bang>0)

" ctags
let g:fzf_tags_command = 'ctags -R'

"--------------------
" プラグイン系
"--------------------

" ファイル形式別プラグインのロード有効化
filetype plugin on

"--------------------
" Vim-Plug
"--------------------

call plug#begin()
" Status Bar
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" Vim Theme
Plug 'morhetz/gruvbox'
" fzf
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
" Markdown
Plug 'suan/vim-instant-markdown', {'for': 'markdown'}
Plug 'godlygeek/tabular'
Plug 'plasticboy/vim-markdown'
" Emmet
Plug 'mattn/emmet-vim'
" Git
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'
" Comment Out
Plug 'tomtom/tcomment_vim'

" deoplete
if has('nvim')
  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
else
  Plug 'Shougo/deoplete.nvim'
  Plug 'roxma/nvim-yarp'
  Plug 'roxma/vim-hug-neovim-rpc'
endif

" 括弧の補完
Plug 'cohama/lexima.vim'

" PHP Doc
Plug 'vim-scripts/PDV--phpDocumentor-for-Vim'

" CSS Color Highlights
Plug 'gorodinskiy/vim-coloresque'

" window resizing
Plug 'simeji/winresizer'

" WakaTime
Plug 'wakatime/vim-wakatime'

" vim-vue
Plug 'posva/vim-vue'

" surround.vim
Plug 'tpope/vim-surround'

" vim-slim
Plug 'slim-template/vim-slim'
call plug#end()

" --- suan/vim-instant-markdown --- 
" Disable Folding
let g:vim_markdown_folding_disabled = 1

" --- mattn/emmet-vim ---
" メインのキー変更
let g:user_emmet_leader_key = ','
let g:user_emmet_settings = {
    \ 'lang' : 'ja',
        \ 'php' : {
            \ 'extends' : 'html'
        \ }
    \ }

" --- airblade/vim-gitgutter ---
" サインカラムの背景色を無色にする
let g:gitgutter_override_sign_column_highlight = 1

" --- Shougo/deoplete.nvim ---
" deoplete有効化
" let g:deoplete#enable_at_startup = 1
" let g:deoplete#auto_complete_delay = 0

" --- tomtom/tcomment_vim ---

" --- vim-airline/vim-airline ---
" airlineテーマの指定
let g:airline_theme = 'gruvbox'
" Powerline Font有効化
let g:airline_powerline_fonts = 1
" タブ有効化
let g:airline#extensions#tabline#enabled = 1
" タブにちっちゃい番号表示
" let g:airline#extensions#tabline#buffer_idx_mode = 1
" タブのフォーマット
let g:airline#extensions#tabline#formatter = 'unique_tail'

" --- vim-scripts/PDV--phpDocumentor-for-Vim ---
inoremap <C-P> <Esc>:call PhpDocSingle()<CR>i
nnoremap <C-P> :call PhpDocSingle()<CR>
vnoremap <C-P> :call PhpDocSingle()<CR>

" --- posva/vim-vue ---
autocmd FileType vue syntax sync fromstart

"--------------------
" Vim Theme Settings
"--------------------

" カラースキーム設定
colorscheme gruvbox

" gruvbox Settings
set background=dark
let g:gruvbox_contrast_dark = 'hard'

" 指定のデータをレジスタに登録する
function! s:Clip(data)
    let @*=a:data
    echo "clipped: " . a:data
endfunction

" 現在開いているファイルのパスをレジスタへ
command! -nargs=0 ClipPath call s:Clip(expand('%:p'))
