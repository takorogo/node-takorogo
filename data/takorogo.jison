/* Takorogo Grammar */

%start schema

%ebnf

%options token-stack

%% /* language grammar */


/* Top level rules */

schema
    : schema_script EOF
        { return yy.scope.create('schema', $schema_script); }
    ;

schema_script
    : top_level_statement
        { $$ = [$top_level_statement]; }
    | schema_script top_level_statement
        { $$ = [$top_level_statement].concat($schema_script); }
    ;

top_level_statement
    : statement
    ;

statement
    : class_definition_rule
    | class_definition
    | meta_statement
    ;

/* Metadata */

meta_statement
    : context_meta_entry
        { $$ = $context_meta_entry; }
    | meta_entry statement
        { $$ = yy.scope.create('meta_extension', $statement, $meta_entry);  }
    ;

meta_entry
    : METAID
        { $$ = yy.scope.create('meta', $1); }
    | METAID STRING
        { $$ = yy.scope.create('meta', $1, $2); }
    ;

context_meta_entry
    : METAID EXCLAMATION
        { $$ = yy.scope.create('meta', $1); }
    | METAID EXCLAMATION STRING
        { $$ = yy.scope.create('meta', $1, $3); }
    ;

/* Class level rules */

class_definition
    : DEF symname COLON INDENT statement_list DEDENT
        { $$ = yy.scope.create('class', $symname, $statement_list); }
    ;

statement_list
    : statement
        { $$ = [$statement]; }
    | statement_list statement
        { $$ = $statement_list.concat($statement); }
    ;

class_definition_rule
    : class_definition_rule_statement
        { $$ = yy.scope.create('class_definition_rule', $class_definition_rule_statement); }
    ;

class_definition_rule_statement
    : index
    | link
    | attribute
    | relation
    | embedded
    ;


/* Embedded objects */
embedded
    : attribute INDENT statement_list DEDENT
        { $$ = yy.scope.create('embedded', $attribute, $statement_list); }
    ;


/* Symbolic names, nodes and paths */

symname
    : ID
    | ESCAPED_ID
    ;

node
    : symname
    | node DOT symname
        { $$ = [$1, $2, $3].join(''); }
    ;

path
    : node
    | SLASH node
        { $$ = '/' + $node; }
    | DOTS node
        { $$ = $1 + $node; }
    ;


/* Types and arrays */

array_definition
    : LARRBR RARRBR
        { $$ = Infinity; }
    | LARRBR unsigned_int_number RARRBR
        { $$ = $unsigned_int_number; }
    ;

type
    : path
        { $$ = yy.scope.create('type', $path) }
    | array
    ;

array
    : type array_definition
        { $$ = yy.scope.create('array', $type, $array_definition); }
    ;


/* Properties, attributes and keys */

property
    : property_expression
        { $$ = yy.scope.create('property', $property_expression); }
    ;

property_expression
    : node
        { $$ = { node: $node }; }
    | node COLON type
        { $$ = { node: $node, type: $type }; }
    | LPAREN property LPAREN
        { $$ = $property; }
    ;

attribute
    : attribute_expression
        { $$ = yy.scope.create('attribute', $1); }
    ;

attribute_expression
    : property
    | property AS property
        { $$ = yy.scope.create('renaming', $1, $2); }
    | node LARRBR key RARRBR
        { $$ = yy.scope.create('destructure', $node, $key); }
    ;

key
    : property
        { $$ = yy.scope.create('key', $property); }
    | key COMMA property
        { $$ = $key.add($property); }
    ;


/* Batch renames */

batch_rename
    : tuple AS tuple
        { $$ = yy.scope.create('batch_rename', $1, $2); }
    ;


/* Tuples */

tuple
    : LPAREN tuple_items RPAREN
        { $$ = $tuple_items; }
    ;

tuple_items
    : tuple_item
        { $$ = yy.scope.create('tuple', $tuple_item); }
    | tuple_items COMMA tuple_item
        { $$ = $tuple_items.add($tuple_item); }
    ;

tuple_item
    : attribute
    | tuple
    ;


/* Indexes */

index
    : UNIQUE index_key
        { $$ = yy.scope.create('index', $index_key); }
    ;

index_key
    : attribute
    | tuple
    ;


/* Relations */

relation
    : relation_body attribute
        { $$ = yy.scope.create('relation', $relation_body, $attribute); }
    ;

link
    : link_key relation_body type
        { $$ = yy.scope.create('link', $link_key, $relation_body, $type); }
    ;

link_key
    : tuple
    | batch_rename
    ;

relation_body
    : RELATION_START relation_options RELATION_OUT_END
        { $$ = yy.scope.create('relation_body', 'out', $relation_options); }
    | IN_RELATION_START relation_options RELATION_END
        { $$ = yy.scope.create('relation_body', 'in', $relation_options); }
    | IN_RELATION_START relation_options RELATION_OUT_END
        { $$ = yy.scope.create('relation_body', 'bilateral', $relation_options); }
    | unnamed_relation_body
        { $$ = yy.scope.create('relation_body', $unnamed_relation_body, null); }
    ;

unnamed_relation_body
    : UNNAMED_RELATION_IN_OUT
        { $$ = 'bilateral'; }
    | UNNAMED_RELATION_OUT
        { $$ = 'out'; }
    | UNNAMED_RELATION_IN
        { $$ = 'in'; }
    ;

relation_options
    : relation_definition
        { $$ = yy.scope.create('relation_options', $relation_definition); }
    | relation_definition PIPE relation_definition
        { $$ = yy.scope.create('relation_options', $1, $3); }
    ;

relation_definition
    : symname
        { $$ = yy.scope.create('relation_definition', $symname); }
    | symname tuple
        { $$ = yy.scope.create('relation_definition', $symname, $tuple); }
    ;


/* Numbers */

number
    : float_number
    | int_number
    ;

unsigned_int_number
    : NATLITERAL
        { $$ = parseInt($1); }
    ;

int_number
    : unsigned_int_number
    | MINUS int_number
        { $$ = 0 - $int_number; }
    ;

float_number
    : NATLITERAL DOT NATLITERAL
        { $$ = parseFloat($1 + $2 + $3); }
    | MINUS float_number
        { $$ = 0 - $float_number; }
    ;