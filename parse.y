/*
	Copyright 2014 Brian Sturgill

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

			http://www.apache.org/licenses/LICENSE-2.0

			Unless required by applicable law or agreed to in writing, software
			distributed under the License is distributed on an "AS IS" BASIS,
			WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
			See the License for the specific language governing permissions and
			limitations under the License.
*/

%{
package main

import (
	"log"
	"unicode"
)
%}

%union {
  str string
}

%token ID, NEW, STRING, NUMBER

%type <str> expr, opt_expr_list, opt_expr_list_tail, opt_nl, ID, NEW, STRING, NUMBER

%right '?' ':'
%left OR_OR
%left AND_AND
%left EQ_EQ EQ_EQ_EQ NOT_EQ NOT_EQ_EQ
%left '<' LT_EQ '>' GT_EQ
%left '-' '+'
%left '*' '/' '%'
%right UMINUS UPLUS UNOT
%left '(' NEW
%left '.' '['

%left '\n' // Must be last

%%

start:
  expr
  {
    rw.putString($1)
  }
;

expr:
  ID
  {
    $$ = $1
  }
|	STRING
  {
    $$ = $1
  }
|	NUMBER
  {
    $$ = $1
  }
| '(' expr ')'
	{
		$$ = "(" + $2 + ")"
	}
| expr '.' opt_nl ID
	{
		$$ = $1 + "." + $3 + $4
	}
| expr '[' expr ']'
	{
		$$ = $1 + "[" + $3 + "]"
	}
| expr '(' opt_expr_list ')'
	{
		$$ = $1 + "(" + $3 + ")"
	}
| NEW expr 
	{
		$$ = "new " + $2
	}
| '+' NUMBER %prec UPLUS
  {
    $$ = "+" + $2
  }
| '-' NUMBER %prec UMINUS
  {
    $$ = "-" + $2
  }
| '!' expr %prec UNOT
  {
    $$ = "!" + $2
  }
| expr '+' opt_nl expr
  {
    $$ = $1 + "." + $3 + "add(" + $4 + ")"
  }
| expr '-' opt_nl expr
  {
    $$ = $1 + "." + $3 + "sub(" + $4 + ")"
  }
| expr '*' opt_nl expr
  {
    $$ = $1 + "." + $3 + "mul(" + $4 + ")"
  }
| expr '/' opt_nl expr
  {
    $$ = $1 + "." + $3 + "div(" + $4 + ")"
  }
| expr '%' opt_nl expr
  {
    $$ = $1 + "." + $3 + "mod(" + $4 + ")"
  }
| expr '<' opt_nl expr
  {
    $$ = $1 + "." + $3 + "lt(" + $4 + ")"
  }
| expr LT_EQ opt_nl expr
  {
    $$ = $1 + "." + $3 + "le(" + $4 + ")"
  }
| expr '>' opt_nl expr
  {
    $$ = $1 + "." + $3 + "gt(" + $4 + ")"
  }
| expr GT_EQ opt_nl expr
  {
    $$ = $1 + "." + $3 + "ge(" + $4 + ")"
  }
| expr EQ_EQ opt_nl expr
  {
    $$ = $1 + "." + $3 + "eq(" + $4 + ")"
  }
| expr NOT_EQ opt_nl expr
  {
    $$ = $1 + "." + $3 + "ne(" + $4 + ")"
  }
| expr EQ_EQ_EQ opt_nl expr
  {
    $$ = $1 + "." + $3 + "eq(" + $4 + ")"
  }
| expr NOT_EQ_EQ opt_nl expr
  {
    $$ = $1 + "." + $3 + "ne(" + $4 + ")"
  }
| expr AND_AND opt_nl expr
  {
    $$ = $1 + "&&" + $3 + $4
  }
| expr OR_OR opt_nl expr
  {
    $$ = $1 + "||" + $3 + $4
  }
| expr '?' opt_nl expr ':' opt_nl expr
  {
    $$ = $1 + "?" + $3 + $4 + ":" + $6 + $7
  }
;

opt_expr_list:
	expr opt_expr_list_tail
	{
		$$ = $1 + $2
	}
| /*Empty*/
	{
		$$ = ""
	}
;

opt_expr_list_tail:
	',' expr opt_expr_list_tail
	{
		$$ = "," + $2 + $3
	}
| /*Empty*/
	{
		$$ = ""
	}
;

opt_nl:
	'\n'
  {
    $$ = "\n"
  }
| /*Empty*/
	{
		$$ = ""
	}
;

%%

type ExprLex struct {
	runes [] rune
	peekch rune // Will autoinit to eof.
}

func (el *ExprLex) getch() rune {
	var ret rune
	if el.peekch != eof {
		ret = el.peekch
		el.peekch = eof
		return ret
	}
	if len(el.runes) == 0 {
		return eof
	}
	ret = el.runes[0]
	el.runes = el.runes[1:]
	return ret
}

func (el *ExprLex) ungetch(rune rune) {
	if el.peekch != eof {
		log.Panic("Double ungetch attempted")
	}
	el.peekch = rune
}

func (el *ExprLex) Lex(lval *yySymType) int {
	for {
		r := el.getch()
		if r == '\n' {
			return int(r)
		}
		if unicode.IsSpace(r) {
			continue
		}
		if r == '_' || unicode.IsLetter(r) {
			id := make([]rune, 0, 100)
			for {
				if r == '_' || unicode.IsLetter(r) || unicode.IsDigit(r) {
					id = append(id, r)
					r = el.getch()
				} else {
					break
				}
			}
			el.ungetch(r)
			lval.str = string(id)
			if lval.str == "new" {
				return NEW
			}
			return ID
		}
		if unicode.IsDigit(r) { // Does not detect malformed numbers
			num := make([]rune, 0, 100)
			number_loop: for {
				if r == '.' || r == 'e' || r == 'E' || unicode.IsDigit(r) {
					num = append(num, r)
					if (r == 'e' || r =='E') {
						r = el.getch()
						if r == '+' || r == '-' {
							num = append(num, r)
							r = el.getch()
						}
						for {
							if unicode.IsDigit(r) {
								num = append(num, r)
							} else {
								break number_loop;
							}
							r = el.getch()
						}
					}
				} else {
					break
				}
				r = el.getch()
			}
			el.ungetch(r)
			lval.str = string(num)
			return NUMBER
		}
		if r == '"' || r == '\'' {
			quote := r
			str := make([]rune, 0, 100)
			str = append(str, r)
			r = el.getch()
			for {
				if r == eof {
					log.Fatal("Unterminated string in expression starting at line: %d",
						Expr_start)
				}
				str = append(str, r)
				if r == quote {
					break
				}
				if r == '\\' {
					r = el.getch()
					str = append(str, r)
				}
				r = el.getch()
			}
			lval.str = string(str)
			return STRING
		}
		switch r {
		case eof, '+', '-', '*', '/', '(', ')', '.', '[', ']', ':', '?', '%', ',':
				return int(r)
		case '<':
			r = el.getch()
			if r == '=' {
				return LT_EQ
			} else {
				el.ungetch(r)
				return '<'
			}
		case '>':
			r = el.getch()
			if r == '=' {
				return GT_EQ
			} else {
				el.ungetch(r)
				return '>'
			}
		case '=':
			r = el.getch()
			if r == '=' {
				r = el.getch()
				if r == '=' {
					return EQ_EQ_EQ
				} else {
					return EQ_EQ
				}
			} else {
				log.Fatal("Invalid use of '=' in expression starting at line: %d",
					Expr_start)
			}
		case '!':
			r = el.getch()
			if r == '=' {
				r = el.getch()
				if r == '=' {
					return NOT_EQ_EQ
				} else {
					el.ungetch(r)
					return NOT_EQ
				}
			} else {
				el.ungetch(r)
				return '!'
			}
		case '&':
			r = el.getch()
			if r == '&' {
				return AND_AND
			} else {
				log.Fatal("Invalid use of '&' in expression starting at line: %d",
					Expr_start)
			}
		case '|':
			r = el.getch()
			if r == '|' {
				return OR_OR
			} else {
				log.Fatal("Invalid use of '|' in expression starting at line: %d",
					Expr_start)
			}
		}
	}
}

func (el *ExprLex) Error(str string) {
	log.Fatalf("Error(%d): %s\n", rr.curLine, str)
}

//function call arg list
