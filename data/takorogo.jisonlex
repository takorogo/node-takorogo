/* Takorogo Lexical Grammar */

id                          [a-zA-Z_"$"][a-zA-Z0-9_"$"]*
spc                         [\t \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]

%s EXPR
%s RELATION
%s ARRAY

%%

"data"                      return 'DATA';
"unique"                    return 'UNIQUE';
":"                         return 'COLON';
";"                         return 'SEMICOLON';
"!"                         return 'EXCLAMATION';

"|"                         return 'PIPE'
"=>"                        return 'AS'

[\.]{2,}                    return 'DOTS'
"."                         return 'DOT'

","                         return 'COMMA'
"/"                         return 'SLASH'

"("                         this.begin('EXPR'); return 'LPAREN';
")"                         this.popState(); return 'RPAREN';

"<--["                      this.begin('RELATION'); return 'IN_RELATION_START';
"--["                       this.begin('RELATION'); return 'RELATION_START';
"]-->"                      this.popState(); return 'RELATION_OUT_END';
"]--"                       this.popState(); return 'RELATION_END';

"<-->"                      return 'UNNAMED_RELATION_IN_OUT';
"-->"                       return 'UNNAMED_RELATION_OUT';
"<--"                       return 'UNNAMED_RELATION_IN';

"<"                         return 'LESS_THAN';
">"                         return 'GREATER_THAN';

"="                         return 'EQUALS'

"*"                         return 'STAR'

"["                         this.begin('ARRAY'); return 'LARRBR';
"]"                         this.popState(); return 'RARRBR';

\"[^\"]*\"|\'[^\']*\'       yytext = yytext.substr(1,yyleng-2); return 'STRING';
\`[^\`]*\`                  yytext = yytext.substr(1,yyleng-2); return 'ESCAPED_ID';

"+"                         return 'PLUS';
"-"                         return 'MINUS';

"@"{id}                     yytext = yytext.substr(1,yyleng-1); return 'METAID';
{id}                        return 'ID';

\d+                         return 'NATLITERAL';

<<EOF>>                     return "EOF";

<INITIAL>\s*<<EOF>>         %{
                                // remaining DEDENTs implied by EOF, regardless of tabs/spaces
                                var tokens = [];

                                while (0 < _iemitstack[0]) {
                                    this.popState();
                                    tokens.unshift("DEDENT");
                                    _iemitstack.shift();
                                }

                                if (tokens.length) return tokens;
                            %}

[\n\r]+{spc}*/![^\n\r]      /* eat blank lines */

<INITIAL>[\n\r]{spc}*       %{
                                var indentation = yytext.length - yytext.search(/\s/) - 1;
                                if (indentation > _iemitstack[0]) {
                                    _iemitstack.unshift(indentation);
                                    return 'INDENT';
                                }

                                var tokens = [];

                                while (indentation < _iemitstack[0]) {
                                    this.popState();
                                    tokens.unshift("DEDENT");
                                    _iemitstack.shift();
                                }

                                // Add end of line after DEDENT:
                                tokens.unshift('EOL');
                                return tokens;
                            %}

{spc}+                      /* ignore all other whitespace */

"#".*\n                     /* skip inline comments */
"#".*<<EOF>>                /* skip inline comments */

%%

/* initialize the pseudo-token stack with 0 indents */
_iemitstack = [0];