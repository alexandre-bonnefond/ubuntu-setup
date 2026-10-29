" Minimal vim, no plugins. Leader is , (and Space).

" #{ basics

set nocompatible
set encoding=utf-8
syntax enable
filetype plugin indent on

" colors from the terminal (kitty palette), background from the active palette ($mod2+c)
colorscheme default
silent! source ~/.config/ubuntu-setup/palette/vim.vim

" running vims follow a palette switch, the colorscheme script sends them SIGUSR1
" (the redraw goes through feedkeys, a redraw! in the signal autocommand is not shown)
augroup palette
  au!
  au SigUSR1 * silent! source ~/.config/ubuntu-setup/palette/vim.vim | call feedkeys("\<Cmd>redraw!\<CR>", "n")
augroup end

set clipboard=unnamedplus       " shared clipboard with the system (needs vim-gtk3)
set number relativenumber
set splitbelow splitright
set expandtab shiftwidth=2 softtabstop=2 tabstop=2
set autoindent smartindent
set scrolloff=10
set showmatch
set title
set ignorecase smartcase hlsearch incsearch
set lazyredraw synmaxcol=400
set wrap linebreak nolist
set listchars=eol:$,tab:->,trail:~,extends:>,precedes:<,space:.
set backspace=indent,eol,start

" file names: wildmenu, and :find (Ctrl+P) searches the subfolders
set wildmenu wildmode=full
set path=.,,**
set wildignore+=*/build/**,*/.git/**,*/Downloads/**,*/Desktop/**

" folding on the "# #{" / "# #}" markers used in the configs and scripts
au FileType sh,conf,python,yaml,tmux set foldmethod=marker foldmarker=#\ #{,#\ #}
au FileType vim set foldmethod=marker foldmarker=\"\ #{,\"\ #}
au FileType c,cpp set foldmethod=marker foldmarker=//{,//}

" #}

" #{ mappings

nnoremap , <NOP>
let mapleader = ","
nmap <Space> ,

" jk leaves insert mode
inoremap jk <Esc>l

" H / L jump to the line start / end
nnoremap H ^
vnoremap H ^
nnoremap L $
vnoremap L $

" Ctrl+H/J/K/L move between splits (and tmux panes, see ~/.tmux.conf)
nnoremap <C-H> <C-W><C-H>
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>

" Shift+J / Shift+K next / previous tab
nnoremap <S-J> :tabn<CR>
nnoremap <S-K> :tabp<CR>

" Ctrl+P: open a file from the subfolders (Tab completes)
nnoremap <C-P> :find *

" ,g reindents the whole file and trims trailing spaces
nnoremap <leader>g mggg=G'g:delmarks g<CR>zt:%s/\s\+$//ge<CR>

" ,d deletes without overwriting the yanked text
nnoremap <leader>d "_d
vnoremap <leader>d "_d

" ,fr / ,frl find and replace in the file / on the line
nnoremap <leader>fr :%s///g<Left><Left>
nnoremap <leader>frl :s///g<Left><Left>

" * highlights the word without jumping, // in visual mode searches the selection
nnoremap * *N
vnoremap // y/<C-R>"<CR>

" :w!! saves with sudo
cnoremap w!! w !sudo tee % > /dev/null

" :W, :Q, :Wq, :WQ typos
command! W w
command! Q q
command! Wq wq
command! WQ wq

" #}

" #{ toggles: ,r relative numbers, ,p paste mode, ,a highlight the word under the cursor

nnoremap <leader>r :set relativenumber!<CR>
nnoremap <leader>p :set paste!<CR>

function! AutoHighlightToggle()
  let @/ = ''
  if exists('#auto_highlight')
    au! auto_highlight
    augroup! auto_highlight
    setl updatetime=4000
    echo 'Highlight current word: off'
  else
    augroup auto_highlight
      au!
      au CursorHold * let @/ = '\V\<'.escape(expand('<cword>'), '\').'\>'
    augroup end
    setl updatetime=500
    echo 'Highlight current word: ON'
  endif
endfunction
nnoremap <leader>a :call AutoHighlightToggle()<CR>

" #}
