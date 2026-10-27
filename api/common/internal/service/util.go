package service

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"regexp"
	"strconv"
	"strings"

	"github.com/cuesoftinc/apparule/api/common/internal/repository"
	"github.com/cuesoftinc/apparule/api/common/internal/ticket"
)

var nameRe = regexp.MustCompile(`^[a-z][a-z0-9_]*$`)

// encodeOffset and DecodeOffset are the opaque cursor of unranked lists.
func encodeOffset(n int) string { return base64.RawURLEncoding.EncodeToString([]byte(strconv.Itoa(n))) }

func DecodeOffset(cursor string) int {
	raw, err := base64.RawURLEncoding.DecodeString(strings.TrimRight(cursor, "="))
	if err != nil {
		return 0
	}
	n, err := strconv.Atoi(string(raw))
	if err != nil || n < 0 {
		return 0
	}
	return n
}

// minimalPDF writes text lines as a plain PDF: Helvetica, uncompressed
// streams, byte-accurate xref, 36 lines per US-Letter page (ported from
// the web mock's export so both produce the same document).
func minimalPDF(lines []string) []byte {
	escape := strings.NewReplacer(`\`, `\\`, `(`, `\(`, `)`, `\)`).Replace
	const perPage = 36
	var chunks [][]string
	for i := 0; i < max(len(lines), 1); i += perPage {
		chunks = append(chunks, lines[i:min(i+perPage, len(lines))])
	}
	kids := make([]string, len(chunks))
	for i := range chunks {
		kids[i] = fmt.Sprintf("%d 0 R", 4+2*i)
	}
	objects := []string{
		"<< /Type /Catalog /Pages 2 0 R >>",
		fmt.Sprintf("<< /Type /Pages /Kids [%s] /Count %d >>", strings.Join(kids, " "), len(chunks)),
		"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
	}
	for i, chunk := range chunks {
		text := make([]string, len(chunk))
		for j, line := range chunk {
			text[j] = fmt.Sprintf("1 0 0 1 72 %d Tm (%s) Tj", 720-j*18, escape(winAnsi(line)))
		}
		stream := "BT\n/F1 12 Tf\n" + strings.Join(text, "\n") + "\nET"
		objects = append(objects,
			fmt.Sprintf("<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 3 0 R >> >> /Contents %d 0 R >>", 5+2*i),
			fmt.Sprintf("<< /Length %d >>\nstream\n%s\nendstream", len(stream), stream))
	}
	var b bytes.Buffer
	b.WriteString("%PDF-1.4\n")
	offsets := make([]int, len(objects))
	for i, obj := range objects {
		offsets[i] = b.Len()
		fmt.Fprintf(&b, "%d 0 obj\n%s\nendobj\n", i+1, obj)
	}
	xref := b.Len()
	fmt.Fprintf(&b, "xref\n0 %d\n0000000000 65535 f \n", len(objects)+1)
	for _, off := range offsets {
		fmt.Fprintf(&b, "%010d 00000 n \n", off)
	}
	fmt.Fprintf(&b, "trailer\n<< /Size %d /Root 1 0 R >>\nstartxref\n%d\n%%%%EOF", len(objects)+1, xref)
	return b.Bytes()
}

// winAnsi keeps a line within the base font's encoding: the dashes and
// dots the copy uses become ASCII, anything else outside Latin-1 drops.
func winAnsi(s string) string {
	s = strings.NewReplacer("—", "-", "–", "-", "·", "-").Replace(s)
	var b strings.Builder
	for _, r := range s {
		if r < 256 {
			b.WriteRune(r)
		}
	}
	return b.String()
}

func ticketRequest(accountID, kind, id string, count int, maxBytes int64) ticket.Request {
	return ticket.Request{AccountID: accountID, Target: ticket.Target{Kind: kind, ID: id}, MaxFiles: count, MaxBytes: maxBytes}
}

func jsonUnmarshal(raw []byte, v any) error { return json.Unmarshal(raw, v) }

// hidden turns "blocked" into not_found, keeping real errors.
func hidden(blocked bool, err error) error {
	if err != nil {
		return err
	}
	if blocked {
		return repository.ErrNotFound
	}
	return nil
}
