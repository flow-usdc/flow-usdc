package main

import (
	"bytes"
	"fmt"
	"io/fs"
	"io/ioutil"
	"os"
	"path/filepath"
)

func walkingTransactionDir(path string, info fs.FileInfo, err error) error {
	if err != nil {
		return err
	}

	if info.IsDir() {
		fmt.Printf("# %s\n", info.Name())
		return nil
	}
	dat, err := ioutil.ReadFile(path)
	if err != nil {
		return err
	}

	// Split into lines
	lines := bytes.Split(dat, []byte("\n"))

	fmt.Printf("## %s\n", info.Name())
	for i := 0; i < len(lines); i++ {
		if len(lines[i]) == 0 {
			fmt.Print("\n")
			continue
		}

		// Close code blocks on single curly brace
		if len(lines[i]) == 1 && bytes.Equal(lines[i][0:1], []byte("}")) {
			fmt.Print(string(lines[i][:1]))
			fmt.Print("\n```\n")
			fmt.Print("\n")
			continue
		}

		// Strip comments and print like Markdown
		if len(lines[i]) > 1 && bytes.Equal(lines[i][0:2], []byte("//")) {
			fmt.Print(string(lines[i][2:]))
			fmt.Print("\n")
			continue
		}

		// Omit imports
		if len(lines[i]) > 5 && bytes.Equal(lines[i][0:6], []byte("import")) {
			continue
		}

		// Open code ticks
		if len(lines[i]) > 10 && bytes.Equal(lines[i][0:11], []byte("transaction")) {
			fmt.Print("```cadence\n")
			fmt.Print(string(lines[i]))
			fmt.Print("\n")
			continue
		}

		fmt.Print(string(lines[i]))
		fmt.Print("\n")
	}

	return nil
}

func walkingScriptDir(path string, info fs.FileInfo, err error) error {
	if err != nil {
		return err
	}

	if info.IsDir() {
		fmt.Printf("# %s\n", info.Name())
		return nil
	}
	dat, err := ioutil.ReadFile(path)
	if err != nil {
		return err
	}

	// Split into lines
	lines := bytes.Split(dat, []byte("\n"))

	fmt.Printf("## %s\n", info.Name())
	for i := 0; i < len(lines); i++ {
		if len(lines[i]) == 0 {
			fmt.Printf("\n")
			continue
		}

		// Close code blocks on single curly brace
		if len(lines[i]) == 1 && bytes.Equal(lines[i][0:1], []byte("}")) {
			fmt.Print(string(lines[i][:1]))
			fmt.Print("\n```\n")
			fmt.Print("\n")
			continue
		}

		// Strip comments and print like Markdown
		if len(lines[i]) > 1 && bytes.Equal(lines[i][0:2], []byte("//")) {
			fmt.Print(string(lines[i][2:]))
			fmt.Print("\n")
			continue
		}

		// Omit imports
		if len(lines[i]) > 5 && bytes.Equal(lines[i][0:6], []byte("import")) {
			continue
		}

		// Open code ticks
		if len(lines[i]) > 11 && bytes.Equal(lines[i][0:12], []byte("pub fun main")) {
			fmt.Print("```cadence\n")
			fmt.Print(string(lines[i]))
			fmt.Print("\n")
			continue
		}

		fmt.Print(string(lines[i]))
		fmt.Print("\n")
	}

	return nil
}
func main() {
	fmt.Print("<!-- markdownlint-disable -->\n")
	switch doc := os.Args[1]; doc {
	case "transactions":
		err := filepath.Walk("./transactions/", walkingTransactionDir)
		if err != nil {
			panic(err)
		}
	case "scripts":
		err := filepath.Walk("./scripts/", walkingScriptDir)
		if err != nil {
			panic(err)
		}
	default:
		panic("no doc type")
	}
}
