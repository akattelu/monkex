[
  "if"
  "else"
  "return"
  "let"
  "fn"
] @keyword

[
  "=="
  "!="
  "<"
  ">"
  "+"
  "-"
  "*"
  "/"
  "!"
] @operator

"true" @boolean
"false" @boolean

(number) @number

(string) @string

; Function calls and definitions
((function_call
  name: (identifier) @function)
 (function_definition
  name: (identifier) @function))

; Variables
(identifier) @variable

; Comments (assuming you'll add them in extras or elsewhere in your grammar)
(comment) @comment

; Arrays and objects
(array) @punctuation.bracket
(object) @punctuation.bracket
"[" "]" "{" "}" @punctuation.bracket

; Parameter and argument lists
"(" ")" @punctuation.delimiter

; Operators within infix expressions
(infix_expression operator: _ @operator)

; Key-value pairs in objects
(key_value_pair key: _ @property)
