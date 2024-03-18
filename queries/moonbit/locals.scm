;; Definitions

; Functions

(function_definition (function_identifier) @definition.function)

; Variables

(value_definition (lowercase_identifier) @definition.var)
(parameter (lowercase_identifier) @definition.parameter)
(let_expression (pattern (simple_pattern (lowercase_identifier)) @definition.var))
(let_mut_expression (lowercase_identifier) @definition.var)

; Types

(struct_definition (identifier) @definition.type)
(enum_definition (identifier) @definition.enum)
(type_definition (identifier) @definition.type)
(type_identifier) @definition.type

;; References

; Values
(qualified_identifier) @reference

; Types
(qualified_type_identifier) @reference

;; Scopes

[
 (structure)
 (function_definition)
 (anonymous_lambda_expression)
 (named_lambda_expression)
 (block_expression)
] @scope
