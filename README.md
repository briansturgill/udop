#udop - User defined operators
====
A preprocessor that gives Go, JavaScript, TypeScript and Java a form of user defined operators.

It is useful for things like business logic, where you have numerous expressions involving money, which needs to be encapsulated inside a class.

##Usage:
`udop [-d delimchar] [-o outfile] infile`

The default `delimchar` is `@`. Delimiter characters are always used in pairs.
##Format of `infile`
The characters set support is UTF/8. Use only those characters supported by your target language.

Inside your normal Go/JavaScript/TypeScript/Java file, enclose expressions which are using your user defined operators inside a pair of delimiter characters.
```javascript
var a = @@ b+c*d @@;
```
On output, udop will generate:
```javascript
var a = b.add(c.mul(d));
```
Personally, I prefer to use underscores for the delimiters (easier to read), but as `__` is valid in the identifiers of all the target languages, it did not seem to be a wise choice for a default.
```javascript
var a = __ b+c*d __;
```

`udop` has no sense of the semantics of the underlying language. It will simply perform the straight-forward transformation of your expression. The operators and other elements all have the same relative precendence and association as in the target languages. The following operators are transformed:

|Operator   |Method|
|:---------:|------|
|`+`        |.add  |
|`-`        |.sub  |
|`*`        |.mul  |
|`/`        |.div  |
|`%`        |.mod  |
|`<`        |.lt   |
|`<=`       |.le   |
|`==`, `===`|.eq   |
|`!=`, `!==`|.ne   |
|`>`        |.gt   |
|`>=`       |.ge   |


Other operators present in the target languages are not included because their precedence/associativity vary between the target languages.

The short names were chosen so that the code was still somewhat readable in the output.

For your convenience, the following are passed through unchanged:

|Language elements |Notes                                
|------------------|---------------
|Numbers           |1, 1.5, 3.7e5 May have +/-
|Strings           |Both single and double quote forms.
|Identifiers       |Make sure you only use characters valid in your target language.
|`&&`              |The logical "and" operator
|<code>&#124;&#124;</code>              |The logical "or" operator
|`!`               |The logical "not" operator
|`new expr`        |The new operator
|`expr[expr]`      |Subscript
|`expr(arg, ...)`  |Function call
|`( expr )`        |Parenthesis for clarity or to override associativity.
|`expr.id`         |Method/property reference
|`? :`             |Not available in Go

If you need to break an expression with a newline, do so immediately after an operator. The location of the newline is required due to the syntactic oddities of JavaScript, TypeScript and Go. We make it a part of the syntax of expressions so that we can make our output such that line numbers in error messages from the target languages will still be correct. Obviously column numbers may not be correct in such messages.

##Escaping delimiters
Because delimiters occur in pairs... escaping is a bit odd.
You do not need to escape a single delimiter, but if you need two delimiters in a row, you need to type three. Some examples will help:

|Example input         | output
|----------------------|---------
|"addr@host.com"       |"addr@host.com"
|@                     |@
|@@@                   |@@
|@@@@                  |@@@
|@@@@@@                |@@@@
|@@@@@@@               |@@@@@
|@@@@@@@@@             |@@@@@@

