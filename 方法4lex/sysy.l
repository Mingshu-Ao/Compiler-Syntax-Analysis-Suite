%option noyywrap
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "sysy.tab.h"

int cur_line = 1;

void yyerror(const char *s);
%}

DIGIT       [0-9]
LETTER      [a-zA-Z_]
ID          {LETTER}({LETTER}|{DIGIT})*
DECIMAL     [1-9][0-9]*|0
OCTAL       0[0-7]+
HEX         0[xX][0-9a-fA-F]+
INT_CONST   {DECIMAL}|{OCTAL}|{HEX}
FLOAT_CONST {DIGIT}+"."{DIGIT}*|{DIGIT}*"."{DIGIT}+

%x COMMENT

%%

"//".* { }
"/*"            { BEGIN(COMMENT); }
<COMMENT>"*/"   { BEGIN(INITIAL); }
<COMMENT>\n     { cur_line++; }
<COMMENT>.      { }

"int"       { return INT; }
"float"     { return FLOAT; }
"void"      { return VOID; }
"const"     { return CONST; }
"return"    { return RETURN; }
"if"        { return IF; }
"else"      { return ELSE; }
"while"     { return WHILE; }
"break"     { return BREAK; }
"continue"  { return CONTINUE; }

"&&"        { return LAND; }
"||"        { return LOR; }
"<="        { return LTE; }
">="        { return GTE; }
"=="        { return EQ; }
"!="        { return NEQ; }

"+"|"-"|"*"|"/"|"%"|"<"|">"|"!"|"=" { return yytext[0]; }
";"|","|"("|")"|"["|"]"|"{"|"}"     { return yytext[0]; }

{INT_CONST}   { return INT_CONST; }
{FLOAT_CONST} { return FLOAT_CONST; }
{ID}          { return IDENT; }

\n            { cur_line++; }
[ \t\r]       { }

.             { printf("Error at Line %d: Unknown character '%s'\n", cur_line, yytext); }

%%