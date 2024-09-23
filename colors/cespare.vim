" ============================================================================
" Name:     cespare's personal color scheme
" Author:   Caleb Spare
" Version:  0.0.1
" ----------------------------------------------------------------------------

" This is a hack-up of LuciusDark.

set background=dark
hi clear
if exists("syntax_on")
    syntax reset
endif
let g:colors_name = "cespare"

let s:normal_items = [
      \ "ColorColumn",
      \ "Comment",
      \ "Constant",
      \ "Cursor",
      \ "CursorColumn",
      \ "CursorIM",
      \ "CursorLine",
      \ "CursorLineNr",
      \ "DiffAdd",
      \ "DiffChange",
      \ "DiffDelete",
      \ "Directory",
      \ "Error",
      \ "ErrorMsg",
      \ "Function",
      \ "Identifier",
      \ "IncSearch",
      \ "LineNr",
      \ "MatchParen",
      \ "ModeMsg",
      \ "MoreMsg",
      \ "NonText",
      \ "Pmenu",
      \ "PmenuSbar",
      \ "PmenuSel",
      \ "PmenuThumb",
      \ "PreProc",
      \ "Question",
      \ "Search",
      \ "SignColumn",
      \ "Special",
      \ "SpecialKey",
      \ "Statement",
      \ "TabLine",
      \ "TabLineFill",
      \ "Todo",
      \ "Type",
      \ "VertSplit",
      \ "Visual",
      \ "WarningMsg",
      \ "WildMenu",
      \ ]

let s:bold_items = [
      \ "DiffText",
      \ "FoldColumn",
      \ "Folded",
      \ "TabLineSel",
      \ "Title",
      \ ]

let s:underline_items = [
      \ "Underlined",
      \ "VisualNOS"
      \ ]

" Clear default settings
for s:item in s:normal_items + s:bold_items + s:underline_items
    exec "hi " . s:item . " guifg=NONE guibg=NONE gui=none"
                \ . " ctermfg=NONE ctermbg=NONE cterm=none term=none"
endfor

hi clear Normal
hi Normal       ctermfg=NONE  ctermbg=NONE  guifg=#f0f0f0 guibg=#141414
hi IncSearch    ctermfg=NONE  ctermbg=24    guifg=fg      guibg=#005f87
hi Search       ctermfg=NONE  ctermbg=24    guifg=bg      guibg=#b0b0b0
hi CurSearch                                guifg=fg      guibg=#005f87
hi Comment      ctermfg=246   cterm=NONE    guifg=#949494 guibg=NONE
hi MatchParen   ctermfg=NONE  ctermbg=237   guifg=NONE    guibg=#2c5475
hi Error        ctermfg=NONE  ctermbg=239   guifg=NONE    guibg=#4e4e4e
hi LineNr       ctermfg=245   ctermbg=235   guifg=#8a8a8a guibg=#282828
hi ColorColumn  ctermfg=NONE  ctermbg=237   guifg=NONE    guibg=#3a3a3a
hi String       ctermfg=150                 guifg=#afd787
hi CursorLine   ctermfg=NONE  ctermbg=238   guifg=NONE    guibg=#444444
hi QuickFixLine ctermfg=150   ctermbg=NONE  guifg=#87c8e5 guibg=NONE
hi Visual       ctermfg=NONE  ctermbg=24    guifg=NONE    guibg=#005f87
hi Title        ctermfg=74    ctermbg=NONE  guifg=#5fafd7 guibg=NONE
hi Todo         ctermfg=185   ctermbg=NONE  guifg=#d7d75f guibg=NONE
hi Pmenu        ctermfg=235   ctermbg=252   guifg=fg      guibg=#262626
hi PmenuSel     ctermfg=NONE  ctermbg=24    guifg=fg      guibg=#005f87
hi PmenuSbar    ctermfg=249   ctermbg=252   guifg=#b2b2b2 guibg=#d0d0d0
hi PmenuThumb   ctermfg=NONE  ctermbg=244   guifg=fg      guibg=#808080
hi NormalFloat  ctermfg=NONE  ctermbg=NONE  guifg=#d7d7d7 guibg=#191919
hi StatusLine   ctermfg=245   ctermbg=235   guifg=#c0c0c0 guibg=#282828

hi LspReferenceRead  ctermbg=24 guibg=#00afd7
hi LspReferenceText  ctermbg=24 guibg=#00afd7
hi LspReferenceWrite ctermbg=24 guibg=#00afd7
