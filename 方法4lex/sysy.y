%{
#include <stdio.h>
#include <stdlib.h>

extern int yylex();
extern int cur_line;
extern char* yytext;

void yyerror(const char *s);
%}

%token INT FLOAT VOID CONST
%token IF ELSE WHILE BREAK CONTINUE RETURN
%token IDENT INT_CONST FLOAT_CONST
%token LAND LOR LTE GTE EQ NEQ

/* 优先级定义 */
%left LOR
%left LAND
%left EQ NEQ
%left '<' '>' LTE GTE
%left '+' '-'
%left '*' '/' '%'
%right '!' UMINUS
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

CompUnit
    : Elements
    ;

Elements
    : Element
    | Elements Element
    ;

Element
    : Decl
    | FuncDef
    ;

/* --- 1. 核心修改：统一类型定义 --- */
/* 将 BType 和 FuncType 合并，解决 int main() 识别为变量的冲突 */
Type
    : INT
    | FLOAT
    | VOID
    ;

/* --- 声明 Decl --- */
Decl
    : ConstDecl
    | VarDecl
    ;

/* --- 常量声明 --- */
ConstDecl
    : CONST Type ConstDefList ';'
    ;

ConstDefList
    : ConstDef
    | ConstDefList ',' ConstDef
    ;

ConstDef
    : IDENT ArrayIndices '=' ConstInitVal
    ;

ArrayIndices
    : 
    | ArrayIndices '[' ConstExp ']'
    ;

ConstInitVal
    : ConstExp
    | '{' ConstInitValList '}'
    | '{' '}'
    ;

ConstInitValList
    : ConstInitVal
    | ConstInitValList ',' ConstInitVal
    ;

/* --- 变量声明 --- */
VarDecl
    : Type VarDefList ';'
    ;

VarDefList
    : VarDef
    | VarDefList ',' VarDef
    ;

VarDef
    : IDENT ArrayIndices
    | IDENT ArrayIndices '=' InitVal
    ;

InitVal
    : Exp
    | '{' InitValList '}'
    | '{' '}'
    ;

InitValList
    : InitVal
    | InitValList ',' InitVal
    ;

/* --- 函数定义 --- */
/* 这里也使用 Type，确保 parser 看到 '(' 之前不进行归约 */
FuncDef
    : Type IDENT '(' FuncFParams ')' Block
    | Type IDENT '(' ')' Block
    ;

FuncFParams
    : FuncFParam
    | FuncFParams ',' FuncFParam
    ;

FuncFParam
    : Type IDENT
    | Type IDENT '[' ']' ArrayIndices
    ;

/* --- 语句块 --- */
Block
    : '{' BlockItems '}'
    ;

BlockItems
    : 
    | BlockItems BlockItem
    ;

BlockItem
    : Decl
    | Stmt
    ;

/* --- 语句 --- */
Stmt
    : LVal '=' Exp ';'
    | ';'
    | Exp ';'
    | Block
    | IF '(' Cond ')' Stmt %prec LOWER_THAN_ELSE
    | IF '(' Cond ')' Stmt ELSE Stmt
    | WHILE '(' Cond ')' Stmt
    | BREAK ';'
    | CONTINUE ';'
    | RETURN ';'
    | RETURN Exp ';'
    ;

/* --- 表达式 --- */
Exp
    : AddExp
    ;

Cond
    : LOrExp
    ;

LVal
    : IDENT ArrayIndices
    ;

PrimaryExp
    : '(' Exp ')'
    | LVal
    | INT_CONST
    | FLOAT_CONST
    ;

UnaryExp
    : PrimaryExp
    | IDENT '(' FuncRParams ')'
    | IDENT '(' ')'
    | '+' UnaryExp %prec UMINUS
    | '-' UnaryExp %prec UMINUS
    | '!' UnaryExp
    ;

FuncRParams
    : Exp
    | FuncRParams ',' Exp
    ;

MulExp
    : UnaryExp
    | MulExp '*' UnaryExp
    | MulExp '/' UnaryExp
    | MulExp '%' UnaryExp
    ;

AddExp
    : MulExp
    | AddExp '+' MulExp
    | AddExp '-' MulExp
    ;

RelExp
    : AddExp
    | RelExp '<' AddExp
    | RelExp '>' AddExp
    | RelExp LTE AddExp
    | RelExp GTE AddExp
    ;

EqExp
    : RelExp
    | EqExp EQ RelExp
    | EqExp NEQ RelExp
    ;

LAndExp
    : EqExp
    | LAndExp LAND EqExp
    ;

LOrExp
    : LAndExp
    | LOrExp LOR LAndExp
    ;

ConstExp
    : AddExp
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error at Line %d: %s at '%s'\n", cur_line, s, yytext);
}

int main(int argc, char** argv) {
    if (argc > 1) {
        extern FILE *yyin;
        if (!(yyin = fopen(argv[1], "r"))) {
            perror(argv[1]);
            return 1;
        }
    }
    
    if (yyparse() == 0) {
        printf("Success\n");
    } else {
        printf("Failed\n");
    }
    return 0;
}