/* description: Parses Grypher rules. */

/* lexical grammar */
%lex

%%

\s+                   /* skip whitespace */

"UNIQUE"              return 'UNIQUE'
"def"                 return 'DEFINE'
"+"                   return 'ATTR'
\w+                   return 'SYMNAME'

"--["                 return 'RELATION_START'
"<"                   return 'IN'
"]--"                 return 'RELATION_END'
">"                   return 'OUT'
"-->"                 return 'RELATION_OUT'

"[]"                  return 'AS_ARRAY'

"|"                   return 'PIPE'
":"                   return ':'
"=>"                  return 'AS'
"="                   return 'IS'

"("                   return '('
")"                   return ')'

"["                   return '['
"]"                   return ']'

"{"                   return '{'
"}"                   return '}'

"."                   return 'ACCESSOR'
","                   return ','

"\n"                  return 'EOL'
<<EOF>>               return 'EOF'

#.*\n                 /* skip comments */
//.*\n                /* skip comments */
#.*<<EOF>>            /* skip comments */
//.*<<EOF>>           /* skip comments */

/lex

/* operator associations and precedence */

%left  'RELATION_START', 'IN', 'UNIQUE'
%right 'RELATION_END', 'OUT'

%start file

%% /* language grammar */

file
  : rules EOF
    { return $1; }
  | EOF
    { return []; }
  ;

rules
  : rule
    { $$ = [$1]; }
  | rules rule
    { $$ = $1.concat($2); }
  ;

rule
  : relation attribute
    { $$ = $1; $$.attribute = $2; }
  | UNIQUE "(" keys ")"
    { $$ = { _rule: 'index', index: $3, type: 'unique' }; }
  | ATTR attribute_with_type
      { $$ = { _rule: 'attribute', attribute: $2 }; }
  | DEFINE class
    { $$ = $2; $$._rule = 'definition'; }
  | DEFINE class '[' properties ']'
    { $$ = $2; $$._rule = 'enumeration'; $$.elements = $4; }
  | rule '{' rules '}'
    { $$ = $1; $$.rules = $$.rules = $3.concat($$.rules || []); }
  ;

relation
  : RELATION_START relation_obj RELATION_END OUT
    { $$ = { _rule: 'relation', out: $2 }; }
  | IN RELATION_START relation_obj RELATION_END
    { $$ = { _rule: 'relation', in: $3 }; }
  | IN RELATION_START relation_obj PIPE relation_obj RELATION_END OUT
    { $$ = { _rule: 'relation', in: $3, out: $5 }; }
  | RELATION_OUT
    { $$ = { _rule: 'relation', type: 'embed' }; }
  ;

type
  : class
    { $$ = $1; }
  | type AS_ARRAY
    { $$ = [$1]; }
  ;

class
  : SYMNAME
    { $$ = { _type: 'class', name: $1 }; }
  | class '(' ')'
    { $$ = $1; $$.rules = []; }
  | class '(' keys ')'
    { $$ = $1; $$.rules = [{ _rule: 'index', index: $3, type: 'unique' }]; }
  ;

relation_obj
  : SYMNAME
    { $$ = {name: $1} }
  | relation_obj '(' keys ')'
      { $$ = $1; $$.keys = $3 }
  ;
  
attribute
  : attribute_without_type
    { $$ = $1; }
  | attribute_with_type
    { $$ = $1; }
  ;

attribute_without_type
  : property
    { $$ = $1; }
  | property '[' keys ']'
    { $$ = $1; $$.keys = $3; }
  | property AS_ARRAY
    { $$ = $1; $1.isArray = true; }
  | property AS attribute
    { $$ = $3; $$.aliasOf = $1; }
  ;

attribute_with_type
  : attribute ':' type
      { $$ = $1; $$.type = $3; }
  ;

property
  : SYMNAME
    { $$ = { name: $1 }; }
  | property ACCESSOR SYMNAME
      { $$ = $1; $$.name += '.' + $3; }
  ;

properties
  : property
    { $$ = [$1]; }
  | properties ',' property
    { $$ = $1; $$.push($3); }
  ;

keys
  : attribute
    { $$ = [$1]; }
  | keys ',' attribute
    { $$ = $1; $$.push($3); }
  ;