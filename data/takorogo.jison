/* Takorogo Grammar */

%start schema

%ebnf

%options token-stack

%% /* language grammar */


/***************************************
 * Top level rules
 ***************************************/

schema
    : statements EOF
        { return yy.scope.create('schema', $statements); }
    ;

statements
    : statement
        { $$ = [$statement]; }
    | statement eols statements
        { $$ = [$statement].concat($statements); }
    ;


/***************************************
 * Line endings
 ***************************************/

eols
    : EOL
    | eols EOL
    ;

optional_eol
    : eols
    |
    ;


/***************************************
 * Statements
 ***************************************/

statement
    : detailed_type
    | simple_type
    | member
    | meta
    ;


/***************************************
 * Type definition rules
 ***************************************/

meta
    : metatag statement
        { $$ = yy.scope.create('meta_extension', $statement, $metatag);  }
    | metatag meta_properties eols statement
        { $$ = yy.scope.create('meta_extension', $statement, $metatag, $meta_properties);  }
    | metatag EXCLAMATION meta_properties
        { $$ = yy.scope.create('meta', $metatag, $meta_properties);  }
    ;

metatag
    : METAID
    ;

meta_properties
    : EQUALS meta_option
        { $$ = $meta_option; }
    |
    ;

meta_option
    : distinct_type
    | number
    | STRING
    ;


/***************************************
 * Type definition rules
 ***************************************/

detailed_type
    : type_hierarchy_expression EQUALS INDENT statements DEDENT
        { $$ = yy.scope.create('class', $type_hierarchy_expression, $statements); }
    ;

simple_type
    : type_hierarchy_expression EQUALS type
        { $$ = yy.scope.create('alias', $type_hierarchy_expression, $type); }
    | strict_type_hierarchy_expression
        { $$ = yy.scope.create('class', $strict_type_hierarchy_expression); }
    ;

type_hierarchy_expression
    : symname optional_inheritance_rule
        { $$ = yy.scope.create('type_hierarchy_expression', $symname, $optional_inheritance_rule); }
    ;

strict_type_hierarchy_expression
    : symname inheritance_rule
        { $$ = yy.scope.create('type_hierarchy_expression', $symname, $inheritance_rule); }
    ;

optional_inheritance_rule
    : inheritance_rule
    |
    ;

inheritance_rule
    : LESS_THAN path_list
        { $$ = $path_list; }
    ;


/***************************************
 * Members rule
 ***************************************/

member
    : member_statement
        { $$ = yy.scope.create('member', $member_statement); }
    ;

member_statement
    : attribute_expression_or_link
    | relation
    | embedded
    ;


/***************************************
 * Embedded objects
 ***************************************/

embedded
    : node INDENT statements DEDENT
        { $$ = yy.scope.create('embedded', $node, $statements); }
    ;


/***************************************
 * Symbolic names, nodes and paths
 ***************************************/

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
    | path_prefix node
        { $$ = yy.scope.create('path', $node, $path_prefix); }
    ;

path_prefix
    : SLASH
    | DOTS
    ;

path_list
    : path
        { $$ = [$path]; }
    | path_list COMMA path
        { $$ = $path_list; $$.push($path); }
    ;


/***************************************
 * Types and arrays
 ***************************************/

array_definition
    : LARRBR RARRBR
        { $$ = Infinity; }
    | LARRBR unsigned_int_number RARRBR
        { $$ = $unsigned_int_number; }
    ;

type
    : distinct_type
    | mixed_type
    ;

distinct_type
    : STAR
        { $$ = yy.scope.create('any_type'); }
    | path
        { $$ = yy.scope.create('type', $path); }
    | array
    ;

mixed_type
    : distinct_type PIPE type
        { $$ = yy.scope.create('type_variations', $distinct_type); $$.add($type); }
    ;

array
    : distinct_type array_definition
        { $$ = yy.scope.create('array', $distinct_type, $array_definition); }
    | LPAREN mixed_type RPAREN array_definition
        { $$ = yy.scope.create('array', $mixed_type, $array_definition); }
    ;


/***************************************
 * Properties, attributes and keys
 ***************************************/

property
    : node optional_type_assignment
        { $$ = yy.scope.create('property', $node, $optional_type_assignment); }
    ;

property_with_type
    : node type_assignment
        { $$ = yy.scope.create('property', $node, $type_assignment); }
    ;

type_assignment
    : COLON type
        { $$ = $type; }
    ;

optional_type_assignment
    : type_assignment
    |
    ;

attribute_expression_or_link
    : attribute_expression
    | link
    ;

attribute_expression
    : attribute
    | batch_rename
    | tuple
    ;

attribute
    : property
        { $$ = yy.scope.create('attribute', $1); }
    | renaming
    | destructure
    ;

destructure
    : node LARRBR key RARRBR
        { $$ = yy.scope.create('destructure', $node, $key); }
    ;

renaming
    : property AS property
        { $$ = yy.scope.create('renaming', $1, $3); }
    ;

key
    : property
        { $$ = yy.scope.create('key', $property); }
    | key COMMA property
        { $$ = $key.add($property); }
    ;


/***************************************
 * Methods
 ***************************************/

method
    : symname LPAREN method_params RPAREN method_return_type
        { $$ = yy.scope.create('method', $symname, $method_params, $method_return_type); }
    ;


method_params
    : key
    |
        { $$ = undefined; }
    ;

method_return_type
    : COLON type
        { $$ = $type; }
    |
        { $$ = undefined; }
    ;


/***************************************
 * Batch renames
 ***************************************/

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


/***************************************
 * Indexes
 ***************************************/

index
    : UNIQUE index_key
        { $$ = yy.scope.create('index', $index_key); }
    ;

index_key
    : attribute
    | tuple
    ;


/***************************************
 * Relations
 ***************************************/

relation
    : relation_body attribute
        { $$ = yy.scope.create('relation', $relation_body, $attribute); }
    ;

link
    : attribute_expression link_body
        { $$ = yy.scope.create('link', $attribute_expression, $link_body); }
    ;

link_body
    : relation_body type
        { $$ = yy.scope.create('link_body', $relation_body, $type); }
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


/***************************************
 * Numbers
 ***************************************/

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