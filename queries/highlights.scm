;; Type

; Type identifiers

(type_identifier) @type
(qualified_type_identifier) @type

; Type definitions

(enum_definition (identifier) @type.definition)
(struct_definition (identifier) @type.definition)

; Builtin types

((type_identifier) @type.builtin
 (#any-of? @type.builtin
           "Bool"
           "String"
           "Int"
           "Int64"
           "Float64"
           "Array"
           "List"))

; Variable identifiers

(parameter (lowercase_identifier) @parameter)

(pattern (simple_pattern (lowercase_identifier) @variable))

(qualified_identifier) @variable

(dot_identifier) @property

;; Functions

; Function calls

(apply_expression (simple_expression (qualified_identifier) @function.call))

; Function definitions

(function_definition (function_identifier) @function)

; Builtin Functions

((qualified_identifier) @function.builtin
 (#any-of? @function.builtin
           "println"
           "print"))

;; Constructors

(constructor_expression (uppercase_identifier) @constructor)

(enum_constructor) @constructor

;; Operators

[
	"+" "-" "*" "/" "%"
  ":="
  "="
  ">=" "<=" "=="
  "&&" "||"
] @operator

; Keywords

[
  "let"
  "var"
  "while"
  "break"
  "continue"
  "struct"
  "enum"
  "type"
] @keyword

[ "func" "fn" ] @keyword.function
"return" @keyword.return
"while" @report

[
  "if"
  "else"
  "match"
] @conditional

; Delimiters

[
  ";"
  ":"
  ","
] @punctuation.delimiter

[
  "(" ")"
  "{" "}"
  "[" "]"
] @punctuation.bracket

; Literals

(string_interpolatioin (string_fragment) @string)
(string_literal) @string
(escape_sequence) @string.escape
(integer_literal) @number
(float_literal) @float
(boolean_literal) @boolean

; Comments

(comment) @comment @spell

; Errors

(ERROR) @error
