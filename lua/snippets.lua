-- Snippet bodies, keyed by filetype and trigger word.
--
-- Bodies use LSP snippet syntax: ${1:placeholder}, $1, $0 (final cursor),
-- ${1|a,b,c|} (choice), and ${1/foo/bar/} (regex transform).
-- See :h vim.snippet for details.
--
-- Notes for editing:
--
-- - Long-bracket strings ([[ ... ]]) take all characters literally, so
--   backslashes inside them are literal: [[\n]] is two characters (\, n) which
--   is what we want when the snippet inserts Go source containing a `\n` escape,
--   for example.
-- - Inside long-bracket strings the indentation in the source IS part of the
--   string; multi-line bodies start at column 0 deliberately. The leading
--   newline immediately after [[ is stripped by Lua.
-- - `vim.snippet.expand` automatically prepends the current line's leading
--   whitespace to every line of the body, so bodies should be written as if
--   expanded at column 0.

return {
  go = {
    deb    = [[fmt.Printf(">>>> ${1:var}: %v\n", $1)$0]],
    debc   = [[fmt.Printf("\033[01;34m>>>> ${1:var}: %v\x1B[m\n", $1)$0]],
    handle = [[func ${1:Name}(w http.ResponseWriter, r *http.Request) {$0]],

    er = [[
if err != nil {
	return $1
}]],
    ef = [[
if err != nil {
	log.Fatal(err)
}]],
    ep = [[
if err != nil {
	panic(err)
}]],
    efln = [[
if err != nil {
	log.Fatalln("${1:message}", err)
}]],
    eff = [[
if err != nil {
	log.Fatalf("${1:message}", err)
}]],
    gof = [[
go func() {
	$0
}()]],
    tf = [[
if err != nil {
	t.Fatal(err)
}]],
    tff = [[
if err != nil {
	t.Fatalf("${1:message}", err)
}]],
    wantgot = [[
if ${1:want} != ${2:got} {
	t.Fatalf("want %v; got %v", $1, $2)
}]],

    app = [[${1:slice} = append($1, ${2:element})]],
  },

  markdown = {
    link = [[[${1:name}](${2:url})$0]],
    href = [[[${1:url}]($1)$0]],
  },
}
