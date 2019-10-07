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
WHITESPACE		[ \t\f\r\v\n]*
SINGLELINECOM	--.*\n
%option yylineno
%x singcmmt
%x nullcheck
%%
\n { }

"--"    BEGIN(singcmmt);
<singcmmt>[^\n]*	{ }
<singcmmt>\n      { 
	 		curr_lineno = yylineno;
			BEGIN(INITIAL);
		 }
<singcmmt><<EOF>> {
                	curr_lineno = yylineno;
                	BEGIN(INITIAL);

        	  }


"*)"	{	curr_lineno = yylineno;
		cool_yylval.error_msg = "Unmatched *)";
		return ERROR;
	}
"(*" {		curr_lineno = yylineno;
		BEGIN(COMMENT);
	 }
	
<COMMENT>"(*"		{curr_lineno = yylineno;
			nested++;
			}
<COMMENT>"*"+")" 		{curr_lineno = yylineno;
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
<COMMENT>\n 	{ curr_lineno = yylineno;}
<COMMENT>. {curr_lineno = yylineno; }
			
{DARROW}		{ curr_lineno = yylineno;return (DARROW); }
{CLASS}			{ curr_lineno = yylineno;return (CLASS);  }
{ELSE}          { curr_lineno = yylineno;return (ELSE);  }
{FI}             { curr_lineno = yylineno;return (FI);  }
{IF}             { curr_lineno = yylineno;return (IF);  }
{IN}            { curr_lineno = yylineno;return (IN);  }
{INHERITS}       {curr_lineno = yylineno; return (INHERITS);  }
{LET}            {curr_lineno = yylineno; return (LET);  }
{LOOP}           {curr_lineno = yylineno; return (LOOP);  }
{POOL}           { curr_lineno = yylineno;return (POOL);  }
{THEN}           { curr_lineno = yylineno;return (THEN);  }
{WHILE}          { curr_lineno = yylineno;return (WHILE);  }
{CASE}           { curr_lineno = yylineno;return (CASE);  }
{ESAC}           {curr_lineno = yylineno;return (ESAC);  }
{OF}             { curr_lineno = yylineno;return (OF);  }
{NEW}            { curr_lineno = yylineno;return (NEW);  }
{ISVOID}         { curr_lineno = yylineno;return (ISVOID);  }
{NOT}            { curr_lineno = yylineno;return (NOT);  }
{ASSIGN}  		{ curr_lineno = yylineno;return (ASSIGN); }
{LE}			{ curr_lineno = yylineno;return (LE); }

{DIGIT}+		{curr_lineno = yylineno;
					cool_yylval.symbol = inttable.add_string(yytext);
					return (INT_CONST);
				}
				
{TRUE}			{ curr_lineno = yylineno;cool_yylval.boolean = 1; return (BOOL_CONST); }
{FALSE}			{ curr_lineno = yylineno;cool_yylval.boolean = 0; return (BOOL_CONST); }


{TYPE_ID}		{ curr_lineno = yylineno;
					cool_yylval.symbol = stringtable.add_string(yytext); 
					return TYPEID;
				} 	
{OBJECT_ID}     {  curr_lineno = yylineno;
					cool_yylval.symbol = stringtable.add_string(yytext); 
                    return OBJECTID;
				}
				
\"		{	curr_lineno = yylineno;
			BEGIN(string);
			string_buf_ptr=string_buf;
		
		}


<string>\"	{	
			curr_lineno = yylineno;
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
<string>\\n     {
                        curr_lineno = yylineno;
                        *string_buf_ptr++='\n';
                }
<string>\\b     {
                        curr_lineno = yylineno;
                        *string_buf_ptr++='\b';
                }
<string>\\t     {
                        curr_lineno = yylineno;
                        *string_buf_ptr++='\t';
                }
<string>\\f     {
                        curr_lineno = yylineno;
                        *string_buf_ptr++='\f';
                }
<string>\\\0    {               curr_lineno = yylineno;
                                BEGIN(nullcheck);
                                *string_buf = '\0';
                                cool_yylval.error_msg = "String not terminated";
                                return ERROR;
                }

<string><<EOF>> {       
			curr_lineno = yylineno;
                        BEGIN(INITIAL);
                        *string_buf = '\0';
	                cool_yylval.error_msg = "EOF present in string";
                        return ERROR;
                }

<string>\\[^ntbf] {
			curr_lineno = yylineno;
 			*string_buf_ptr++ = yytext[1];
  		 }
	
<string>\n	{		curr_lineno = yylineno;
				BEGIN(INITIAL);
				*string_buf = '\0';
				cool_yylval.error_msg = "String not terminated";
				return ERROR;
		}


<string>\0     {               curr_lineno = yylineno;
                                BEGIN(nullcheck);
                                *string_buf = '\0';
                                cool_yylval.error_msg = "String not terminated";
                                return ERROR;
                }



<string>.	{
			curr_lineno = yylineno;
			*string_buf_ptr++ = *yytext;
		}
	
<nullcheck>[\n|"]		BEGIN(INITIAL);
<nullcheck>[^\n]         

				
{MISC_CHAR}		{curr_lineno = yylineno; return *yytext; }
{WHITESPACE}    { curr_lineno = yylineno;	}


.			{curr_lineno = yylineno;
				cool_yylval.error_msg = yytext;
				return ERROR;
			}
%%
