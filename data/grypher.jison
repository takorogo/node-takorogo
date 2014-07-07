/* description: Parses graphument rules. */

/* lexical grammar */
%lex

%%

\s+                   /* skip whitespace */

[0-9]+("."[0-9]+)?\b  return 'NUMBER'

"UNIQUE"              return 'UNIQUE'
\w+                   return 'ID'

"--["                 return 'RELATION_START'
"<"                   return 'IN'

"]--"                 return 'RELATION_END'
">"                   return 'OUT'

"|"                   return 'PIPE'
":"                   return ':'
"=>"                  return 'AS'
"="                   return 'IS'

";"                   return 'EOL'
<<EOF>>               return 'EOF'

/lex

/* operator associations and precedence */

%left  'RELATION_START', 'IN', 'UNIQUE'
%right 'RELATION_END', 'OUT'

%start file

%% /* language grammar */

file
  : rules EOF
    { return $1; }
  ;

rules
  : rule
    { $$ = [$1]; }
  | rules rule
    { $$ = $1.concat($2); }
  ;

rule
  : attribute relation class
    { $2.class = $3; $2.attribute = $1; $$ = $2; }
  | attribute UNIQUE
    { $$ = { _rule: 'index', index: $1, type: 'unique' } }
  ;

relation
  : RELATION_START relation_name RELATION_END OUT
    { $$ = { _rule: 'relation', out: $2 }; }
  | IN RELATION_START relation_name RELATION_END
    { $$ = { _rule: 'relation', in: $3 }; }
  | IN RELATION_START relation_name PIPE relation_name RELATION_END OUT
    { $$ = { _rule: 'relation', in: $3, out: $5 }; }
  ;

class
  : ':' ID
    { $$ = $2; }
  | { $$ = undefined; }
  ;

relation_name
  : ID
    { $$ = $1 }
  ;

attribute
  : ID
    { $$ = $1; }
  | ID AS ID
    { $$ = {old: $1, new: $3}; }
  ;