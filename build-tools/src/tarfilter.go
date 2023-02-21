// Copyright (c) 2023 Zededa, Inc.
// SPDX-License-Identifier: Apache-2.0

package main

import (
	"archive/tar"
	"fmt"
	"io"
	"log"
	"os"
	"regexp"
)

// Currently exists to solve one problem in the SuSE Linux EVE
//  proof of concept build.  A `tar` file is generated by
//  `linuxkit` which includes two problematic directories/links
//  There were two problems with it, 1) string components in
//  UTF-8 (set environment `LANG=en_US.UTF-8` to compensate,
//  and 2) multiple entries in the archive for directories
//  that are replaced with a fully qualified soft link.  This
//  had no simple fix.  In the `tools/makerootfs.sh` function
//  `do_tar`:
//	extract the contents excluding `"dev/*"`
//	move the children of the directory objects into the link targets
//	filter *all* of the directory entries in a copy of the archive
//		(uses this program)
//	add the links, and target locations to the archive copy
//	move the archive copy, replacing the orignal archive
//		(renane of the file)
//	remove the extracted directory

//  The functionality may be moved into this program over time,
//  and other command options added.

// tarfilter <input file name> <output file name> <entry> ... <entry>

// entries are of the form expected in the tar file,
//  (may be fully qualified; howver, not in this use-case.)
//  a path or file name with its base at the relative root
//  of the tar creation.  For example `var/lock` will remove
//  all entries which start with `var/lock`

func main() {
	// command line input handling
	verbose := false
	arFileIn := os.Args[1]
	arFileOut := os.Args[2]
	rmFiles := os.Args[3:]

	if verbose {
		fmt.Println("processing tar file", arFileIn)
		fmt.Println("to remove")
		for i := range rmFiles {
			fmt.Println(" ", rmFiles[i])
		}
		fmt.Println("in output file", arFileOut)
	}

	// open read and write files, and create required
	//  refereces
	fOut, err := os.Create(arFileOut)
	if err != nil {
		log.Fatalln(err)
	}
	defer fOut.Close()
	wr := tar.NewWriter(fOut)

	fIn, err := os.Open(arFileIn)
	if err != nil {
		log.Fatalln(err)
	}
	defer fIn.Close()
	rd := tar.NewReader(fIn)

	for true {
		// read archive entry header, assume we keep the entry
		skip := false
		hdr, err := rd.Next()
		if err == io.EOF {
			break
		}
		if err != nil {
			log.Fatalln(err)
		}
		// process list of directories to skip
		if verbose {
			fmt.Printf("%+v\n", hdr)
		}
		for _, s := range rmFiles {
			match, _ := regexp.MatchString("^"+s+"/*",
				hdr.Name)
			if match {
				skip = true
			}
		}
		// write header, and contents if entry is a regular file
		if !skip {
			err := wr.WriteHeader(hdr)
			if err != nil {
				log.Fatalln(err)
			}
		}
		if  hdr.Typeflag == tar.TypeReg {
			if !skip {
				// write file contents if needed
				cnt, err := io.Copy(wr, rd)
				if err != nil {
					log.Fatalln(err)
				}
				if verbose {
					fmt.Println("file size =", cnt)
				}
			}
		}
		if !skip {
			err := wr.Flush()
			if err != nil {
				log.Fatalln(err)
			}
		}
	}
}