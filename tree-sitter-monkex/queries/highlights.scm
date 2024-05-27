; Keywords
[
  "let"
  "if"
  "else"
  "return"
  "fn"
] @keyword

; Operators
[
  "=="
  "!="
  "+"
  "-"
  ">"
  "<"
  "*"
  "/"
] @operator


; Boolean literals
(boolean) @boolean

; Numeric literals
(number) @number

; String literals
(string) @string

; Function definitions
(let_statement name: (identifier) @constant)
(function_definition parameters: (identifier) @variable.parameter)
(function_call (identifier) @function)

; ; Arrays and objects, brackets and braces
[
  "["
  "]"
  "{"
  "}"
] @punctuation.bracket

[
  ","
] @punctuation.delimiter

; Object keys
(key_value_pair key: (_) @property)
