/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
        if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
                YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */
int nested=0;
%}
%x string
%x COMMENT

CHAR [a-zA-Z]
DIGIT [0-9] 
CLASS		   ?i:class
ELSE           ?i:else
FI             ?i:fi
IF             ?i:if
IN             ?i:in
INHERITS       ?i:inherits
LET            ?i:let
LOOP           ?i:loop
POOL           ?i:pool
THEN           ?i:then
WHILE          ?i:while
CASE           ?i:case
ESAC           ?i:esac
OF             ?i:of
NEW            ?i:new
ISVOID         ?i:isvoid
NOT            ?i:not

TRUE			t[Rr][Uu][Ee]     
FALSE			f[Aa][Ll][Ss][Ee]

DARROW			=>
ASSIGN			<-
LE				<=
MISC_CHAR		[{};:,\.()<=\+\-~@\*/]
TYPE_ID			[A-Z][a-zA-Z0-9_]*
OBJECT_ID		[a-z][a-zA-Z0-9_]*
WHITESPACE		[ \t\n\f\r\v]*
SINGLELINECOM	--.*\n

%x singlecomment
%%
--		{ BEGIN(singlecomment); }
<singlecomment>[^\n]  {}
<singlecomment>\n { BEGIN(INITIAL);}
<singlecomment><<EOF>> {
                                BEGIN(INITIAL);
                                cool_yylval.error_msg = "EOF in comment";
                                return ERROR;
                        }

"*)"	{
		cool_yylval.error_msg = "Unmatched *)";
		return ERROR;
	}
"(*" {
		BEGIN(COMMENT);
	 }

<COMMENT>"(*"		{
			nested++;
			}
<COMMENT>"*"+")" 		{
				if(nested)
					nested--;
				else
					BEGIN(INITIAL);
			}

<COMMENT><<EOF>> 	{
						BEGIN(INITIAL);
						cool_yylval.error_msg = "EOF in comment";
						return ERROR;
					}
<COMMENT>\n 	{  }
<COMMENT>. { }
			
{DARROW}		{ return (DARROW); }
{CLASS}			{ return (CLASS);  }
{ELSE}          { return (ELSE);  }
{FI}             { return (FI);  }
{IF}             { return (IF);  }
{IN}            { return (IN);  }
{INHERITS}       { return (INHERITS);  }
{LET}            { return (LET);  }
{LOOP}           { return (LOOP);  }
{POOL}           { return (POOL);  }
{THEN}           { return (THEN);  }
{WHILE}          { return (WHILE);  }
{CASE}           { return (CASE);  }
{ESAC}           { return (ESAC);  }
{OF}             { return (OF);  }
{NEW}            { return (NEW);  }
{ISVOID}         { return (ISVOID);  }
{NOT}            { return (NOT);  }
{ASSIGN}  		{ return (ASSIGN); }
{LE}			{ return (LE); }

{DIGIT}+		{
					cool_yylval.symbol = inttable.add_string(yytext);
					return (INT_CONST);
				}
				
{TRUE}			{ cool_yylval.boolean = 1; return (BOOL_CONST); }
{FALSE}			{ cool_yylval.boolean = 0; return (BOOL_CONST); }


{TYPE_ID}		{ 
					cool_yylval.symbol = stringtable.add_string(yytext); 
					return TYPEID;
				} 	
{OBJECT_ID}     {  
					cool_yylval.symbol = stringtable.add_string(yytext); 
                    return OBJECTID;
				}
				
"\""			{
					BEGIN(string);
					string_buf_ptr=string_buf;
					
				}
<string>"\""	{	
					BEGIN(INITIAL);
					if(string_buf_ptr - string_buf + 1 > MAX_STR_CONST){
						*string_buf = '\0';
						cool_yylval.error_msg = "String too long";
						return ERROR;
					}
					*string_buf_ptr='\0';
					cool_yylval.symbol = stringtable.add_string(string_buf);
					return STR_CONST;
		}				
<string><<EOF>>	{	
					BEGIN(INITIAL);
					*string_buf = '\0';
					cool_yylval.error_msg = "EOF present in string";
					return ERROR;
				}

<string>\\[^ntbf] 		{
 				    *string_buf_ptr++ = yytext[1];
				}
<string>\\\n		{	}
<string>\0		{	
					BEGIN(INITIAL);
					*string_buf = '\0';
					cool_yylval.error_msg = "Null value present in string";
					return ERROR;
				}
<string>\\n  	{
					*string_buf_ptr++='\n';
				}
<string>\\b  	{
					*string_buf_ptr++='\b';
				}
<string>\\t  	{
					*string_buf_ptr++='\t';
				}
<string>\\f  	{
					*string_buf_ptr++='\f';
				}				
<string>\n 		{
					BEGIN(INITIAL);
					*string_buf = '\0';
					cool_yylval.error_msg = "String not terminated";
					return ERROR;
				}
<string>.		{
					*string_buf_ptr++ = *yytext;
				}
				
{MISC_CHAR}		{ return *yytext; }
{WHITESPACE}     { }


.			{
				cool_yylval.error_msg = yytext;
				return ERROR;
			}
%%
