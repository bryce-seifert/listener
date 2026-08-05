// Command gen-ico wraps one or more PNG files into a single Windows .ico,
// storing each image as a PNG payload (valid on Windows Vista and later).
//
//	go run ./tools/gen-ico out.ico 16.png 32.png ... 256.png
//
// It is invoked by tools/gen-icons.sh and is not part of the main build.
package main

import (
	"bytes"
	"encoding/binary"
	"fmt"
	"image/png"
	"os"
)

func main() {
	if len(os.Args) < 3 {
		fmt.Fprintln(os.Stderr, "usage: gen-ico <out.ico> <png>...")
		os.Exit(1)
	}
	outPath := os.Args[1]
	pngPaths := os.Args[2:]

	type entry struct {
		w, h uint8
		data []byte
	}
	entries := make([]entry, 0, len(pngPaths))
	for _, p := range pngPaths {
		data, err := os.ReadFile(p)
		check(err)
		cfg, err := png.DecodeConfig(bytes.NewReader(data))
		check(err)
		// The ICONDIRENTRY width/height are single bytes; 256 is encoded as 0.
		entries = append(entries, entry{
			w:    dim(cfg.Width),
			h:    dim(cfg.Height),
			data: data,
		})
	}

	var buf bytes.Buffer
	// ICONDIR header.
	put16(&buf, 0)                    // reserved
	put16(&buf, 1)                    // type: 1 = icon
	put16(&buf, uint16(len(entries))) // image count

	// ICONDIRENTRY for each image. Payloads follow all entries.
	offset := uint32(6 + 16*len(entries))
	for _, e := range entries {
		buf.WriteByte(e.w)
		buf.WriteByte(e.h)
		buf.WriteByte(0) // color palette count (0 = no palette)
		buf.WriteByte(0) // reserved
		put16(&buf, 1)   // color planes
		put16(&buf, 32)  // bits per pixel
		put32(&buf, uint32(len(e.data)))
		put32(&buf, offset)
		offset += uint32(len(e.data))
	}
	for _, e := range entries {
		buf.Write(e.data)
	}

	check(os.WriteFile(outPath, buf.Bytes(), 0o644))
	fmt.Printf("wrote %s (%d images)\n", outPath, len(entries))
}

func dim(v int) uint8 {
	if v >= 256 {
		return 0
	}
	return uint8(v)
}

func put16(b *bytes.Buffer, v uint16) { binary.Write(b, binary.LittleEndian, v) }
func put32(b *bytes.Buffer, v uint32) { binary.Write(b, binary.LittleEndian, v) }

func check(err error) {
	if err != nil {
		fmt.Fprintln(os.Stderr, "gen-ico:", err)
		os.Exit(1)
	}
}
