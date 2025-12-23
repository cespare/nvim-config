if exists("b:current_syntax")
  finish
endif

syntax match todoHeading "^# .*$"
syntax match todoTag "^\s*\[\S\+\]"

highlight default link todoHeading Title
highlight default link todoTag Special

let b:current_syntax = "todo"
