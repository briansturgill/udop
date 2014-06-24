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

package main

import (
	"flag"
	"log"
	"os"
)

var rr *RuneReader
var rw *RuneWriter

var outFile = flag.String("o", "", "output filename (defaults to stdout)")
var delimiterString = flag.String("d", "@", "delimiter character")
var delimiter rune

var Expr_start = 0

func main() {
	flag.Usage = func() {
		log.Printf("Usage: udop -d delimeter_char [-o out_file] in_file\n")
	}
  flag.Parse()
	args := flag.Args()
	if len(args) != 1 {
		flag.Usage()
		os.Exit(1)
	}
	delimiter = rune((*delimiterString)[0])
	rr = NewRuneReader(args[0])
	rw = NewRuneWriter(*outFile)
	defer rw.Flush()
	in_expr := false
	runes := make([]rune, 0, 100)
	for {
		r := rr.getRune()
		if r == eof {
			if in_expr {
				log.Fatalf("Unterminated udop expression, starting at line %d\n", Expr_start)
			}
			break
		}
		if in_expr {
			if r == delimiter {
				r = rr.getRune()
				if r == delimiter {
					yyParse(&ExprLex{runes: runes})
					in_expr = false
					continue
				} else {
					rr.ungetRune(r)
					r = delimiter
				}
			}
			runes = append(runes, r)
		} else {
			if r == delimiter {
				r = rr.getRune()
				if r == delimiter {
					Expr_start = rr.curLine
					r = rr.getRune()
					if r != delimiter {
						in_expr = true
						runes = runes[0:0]
						continue
					} else {
						rw.putRune(delimiter) // Will result in output of two delimiters
					}
				} else {
					rw.putRune(delimiter)
				}
			}
			rw.putRune(r)
		}
	}
}
