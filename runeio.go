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
	"bufio"
	"io"
	"log"
	"os"
)

const eof = '\000'

type RuneReader struct {
	peekRune rune
	rdr     *bufio.Reader
	file    string
	curLine int
}

func NewRuneReader(file string) *RuneReader {
	f, err := os.Open(file)
	if err != nil {
		log.Fatalf("Error opening %v: %v\n", file, err)
	}
	rdr := bufio.NewReader(f)
	return &RuneReader{peekRune: eof, rdr: rdr, file: file, curLine: 1}
}

func (rr *RuneReader) getRune() rune {
	if rr.peekRune != eof {
		tmp := rr.peekRune
		rr.peekRune = eof
		if tmp == '\n' {
		  rr.curLine++;
		}
		return tmp
	}
	rune, _, err := rr.rdr.ReadRune()
	if err == io.EOF {
		return eof
	}
	if err != nil {
		log.Fatalf("Error reading %v: %v\n", rr.file, err)
	}
	if rune == '\n' {
		rr.curLine++;
	}
	return rune
}

func (rr *RuneReader) ungetRune(r rune) {
	if rr.peekRune != eof {
		log.Fatalf("Double ungetRune reading: %v\n", rr.file)
	}
	if r == '\n' {
	  rr.curLine--
	}
	rr.peekRune = r
}

type RuneWriter struct {
	wtr     *bufio.Writer
	file    string
}

func NewRuneWriter(file string) *RuneWriter {
	var f *os.File
	var err error
	if file != "" {
		f, err = os.Create(file)
		if err != nil {
			log.Fatalf("Error creating %v: %v\n", file, err)
		}
	} else {
		f = os.Stdout
	}
	wtr := bufio.NewWriter(f)
	return &RuneWriter{wtr: wtr, file: file}
}

func (rw *RuneWriter) putRune(rune rune) {
	_, err := rw.wtr.WriteRune(rune)
	if err != nil {
		log.Fatalf("Error writing %v: %v\n", rw.file, err)
	}
}

func (rw *RuneWriter) putString(str string) {
	_, err := rw.wtr.WriteString(str)
	if err != nil {
		log.Fatalf("Error writing %v: %v\n", rw.file, err)
	}
}

func (rw *RuneWriter) Flush() {
	rw.wtr.Flush()
}
