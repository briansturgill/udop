GOFILES=udop.go \
runeio.go \
parse.go

test: udop test_udop_go test_udop_go_underscore test_udop_js.js
	./test_udop_go
	./test_udop_go_underscore
	node test_udop_js.js

udop: $(GOFILES)
	go build $(GOFILES)

parse.go: parse.y
	go tool yacc -o parse.go parse.y

test_udop_go: udop test_udop_go.udop
	./udop -o test_udop_go.go test_udop_go.udop
	go build test_udop_go.go

test_udop_go_underscore: udop test_udop_go.udop
	sed -e 's/@/_/g' <test_udop_go.udop > test_udop_go_underscore.udop
	./udop -d _ -o test_udop_go_underscore.go test_udop_go_underscore.udop
	go build test_udop_go_underscore.go

test_udop_js.js: udop test_udop_js.udop
	./udop -o test_udop_js.js test_udop_js.udop

clean:
	rm -f udop parse.go y.output
	rm -f test_udop_go test_udop_go.go
	rm -f test_udop_go_underscore test_udop_go_underscore.go test_udop_go_underscore.udop
	rm -f test_udop_js.js
