" ---------------------------- Basic Settings ------------------------------ {{{
" Text-wrapping stuff.
set textwidth=80
let &wrapmargin = &textwidth
let &colorcolumn = &wrapmargin
" Don't hard-wrap long lines as you're typing (annoying), but allow gq to work.
set formatoptions=croql

set number
set wildmode=list:longest
set scrolloff=3 " Keep three lines of context when scrolling.
set expandtab
set tabstop=2
set shiftwidth=2
set ignorecase
set smartcase
set undofile
set splitright
set foldlevelstart=99

" When completing, don't automatically select the first choice, but instead just
" insert the longest common text.
set completeopt=menu,longest

let mapleader = ","

" For some reason I accidentally hit this shortcut all the time, so disable it.
" I usually don't look at man pages from within vim anyway.
noremap K <Nop>

" Disable ctrl-a; I press this accidentally because of tmux all the time.
noremap <C-a> <Nop>

" Unify vim's default register and the system clipboard
set clipboard=unnamedplus

" Don't save backup files. That's what git is for.
set nobackup
set nowritebackup

" Don't save other tabs in sessions (as I don't use tabs)
set sessionoptions-=tabpages
" Don't save help pages in sessions
set sessionoptions-=help
" Don't save hidden buffers -- only save the visible ones.
set sessionoptions-=buffers

" Shared data file settings:
" ! 	Save and restore uppercase globals
" '100	Save marks for the last 100 edited files
" /100	Save 100 searches
" :100	Save 100 lines of command-line history
" <500	Save max of 500 lines of each register
" f1	Store global marks
" h	Disable hlsearch when starting
" s100	Items that would use more than 100 KiB are skipped.
set shada=!,'100,/100,:100,<500,f1,h,s100

" }}}
" --------------------------- Colorscheme Settings ------------------------- {{{
colorscheme cespare

" Show extra whitespace
hi ExtraWhitespace guibg=#CCCCCC
hi ExtraWhitespace ctermbg=7
match ExtraWhitespace /\s\+$/
augroup highlight_whitespace
  au!
  au BufWinEnter * match ExtraWhitespace /\s\+$/
  au InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
  au InsertLeave * match ExtraWhitespace /\s\+$/
  au BufWinLeave * call clearmatches()
augroup END

" }}}
" ------------------------ Plugin-specific Settings ------------------------ {{{
" Gundo settings
nnoremap <leader>gu :GundoToggle<cr>

" fzf
nnoremap ; :Buffers<CR>
nnoremap <leader>d :Files<CR>

" rg (via vim-ripgrep)
nnoremap <leader>a :Rg 

" easy-align settings
vnoremap <leader>a :EasyAlign<Enter>

" Airline
let g:airline_theme = 'minimalist'
let g:airline_section_z='%3p%% • %l/%L • %v'
let g:airline_section_error = ''
let g:airline_section_warning = ''
let g:airline#extensions#wordcount#enabled = 0

" Tell SnipMate that we're aware of the new format.
let g:snipMate = { 'snippet_version' : 1 }

" Insertlessly
let g:insertlessly_insert_spaces = 0
let g:insertlessly_cleanup_trailing_ws = 0
let g:insertlessly_cleanup_all_ws = 0

" }}}
" ---------------------- Custom Commands and Functions --------------------- {{{
" A function to delete all trailing whitespace from a file. (From
" http://vimcasts.org/episodes/tidying-whitespace/)
function! <SID>DeleteTrailingWhitespace()
  " Preparation: save last search, and cursor position.
  let _s=@/
  let l = line(".")
  let c = col(".")
  " Do the business:
  %s/\s\+$//e
  " Clean up: restore previous search history, and cursor position
  let @/=_s
  call cursor(l, c)
endfunction

" Preview the current markdown file:
command! Markdownd !markdownd -w % >/dev/null &

" Toggle colorcolumn
function! ToggleColorColumn()
  if &colorcolumn == 0
    " Draw the color column wherever wrapmargin is set
    let &colorcolumn = &wrapmargin
  else
    let &colorcolumn = 0
  endif
endfunction
command! ToggleColorColumn call ToggleColorColumn()

" Show the current highlight group underneath the cursor:
function! SynStack()
  if !exists("*synstack")
    return
  endif
  echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')
endfunc

" After running a command which alters the quickfix window, this function is
" useful for opening the window (if it's non-empty) and focus the first result.
function! FocusQuickfix()
  cwindow
  if len(getqflist()) > 0
    cfirst
  endif
endfunction
command! FocusQuickfix call FocusQuickfix()

" }}}
" ------------------------------- My Mappings ------------------------------ {{{
" Invoke omnicompletion with a single chord.
inoremap <C-o> <C-x><C-o>

" Quickly un-highlight search terms
noremap <leader>nn :noh<CR>

" Quickly delete trailing whitespace (with cursor position restore)
nnoremap <leader>$ :call <SID>DeleteTrailingWhitespace()<cr>

" Make Y be like C and D (yank to end of line), a mapping so obvious it's
" recommended by :help Y.
nnoremap Y y$

" Shortcuts for creating splits
nnoremap <leader>h :split<cr>
nnoremap <leader>v :vsplit<cr>

" Make it easier to move around through blocks of text:
noremap <C-j> gj
noremap <C-k> gk
noremap <expr> <C-h> (&scroll-2).'k'
noremap <expr> <C-l> (&scroll+2).'j'

" Close a buffer without messing with the windows.
nnoremap <silent> <leader>q :bp\|bd #<CR>

" No colon in command mode to enter an ex command; just use space
nnoremap <Space> :

" Shortcuts for using the quickfix window (partly copied from unimpaired):
nnoremap ]q :cnext<cr>
nnoremap [q :cprevious<cr>
nnoremap [Q :cfirst<cr>
nnoremap ]Q :clast<cr>
nnoremap <leader>x :cclose<cr>

"" Shortcuts for custom commands:
noremap <leader>m :Markdownd<cr><cr>
noremap <leader>l :ToggleColorColumn<cr>

"" Git blame shortcut (fugitive)
noremap <leader>bl :Git blame<cr>
" Open GitHub page in browser (fugitive/rhubarb)
noremap <leader>bb :GBrowse<cr>

" Quick fold toggling
noremap <leader>f za

" Get rid of Ex mode and map a useful command for reflowing text
nnoremap Q gqap

" Suggestions from Learn Vimscript the Hard Way
nnoremap <leader>ev :vsplit $MYVIMRC<cr>
nnoremap <leader>sv :source $MYVIMRC<cr>

" Quickly 'go run' the current file. Good for little scratch programs.
nnoremap <leader>gg :!go run %<cr>

" I usually want to evaluate the outermost s-expr in Clojure. This is often more
" handy than cpp (evaluate current expr).
nnoremap cpo :Eval<cr>

" }}}
" ------------------------- Language-specific Settings --------------------- {{{
" Go
lua require("go_lsp")
augroup go
  au!
  au BufWritePre *.go lua vim.lsp.buf.formatting()
  au BufWritePre *.go lua organize_imports(1000)
  au FileType go,asm,gomod setlocal noexpandtab
  au FileType go,asm,gomod setlocal ts=8
  au FileType go,asm,gomod setlocal sw=8
augroup END
"" TODO:
"" nnoremap <leader>gb <Plug>(go-build)
"" nnoremap <leader>gt <Plug>(go-test)
"" nnoremap <leader>gf <Plug>(go-test-func)
"" nnoremap <leader>gc <Plug>(go-coverage-toggle)

" Rust
let g:rustfmt_autosave = 1

" Markdown
augroup markdown
  au!
  au FileType markdown setlocal comments=b:*,b:-,b:+,n:>h
augroup END

" Vimscript
augroup filetype_vim
  au!
  au FileType vim setlocal foldmethod=marker
augroup END

" Git commit messages
augroup gitcommit
  au!
  au FileType gitcommit setlocal textwidth=72
augroup END

" JSON
" Override weird highlighting.
hi def link jsonKeyword String
" Turn off disruptive error highlighting.
let g:vim_json_warnings = 0
