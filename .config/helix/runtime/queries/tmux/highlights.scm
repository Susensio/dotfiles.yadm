(comment) @comment

[
  "'"
  (str_single_quotes)
  (str_double_quotes)
] @string

(backslash_escape) @constant.character.escape

(path) @string.special.path

(int) @constant.numeric

[
  (option)
  (name)
] @variable

(command_line_option) @variable.builtin

((option) @variable.builtin
  (#not-match? @variable.builtin "^@"))

[
  (if_keyword)
  (elif_keyword)
  (else_keyword)
  (endif_keyword)
] @keyword.control.conditional

[
  (hidden_keyword)
  (command)
] @keyword

(source_file_directive
  (command) @keyword.control.import)

(attribute) @attribute

(function_name) @function

"=" @operator

[
  ";"
  "';'"
  ","
  ":"
] @punctuation.delimiter

[
  "#"
  "?"
] @punctuation.special

[
  "#{"
  "}"
  "#["
  "]"
  "["
  "{"
] @punctuation.bracket
