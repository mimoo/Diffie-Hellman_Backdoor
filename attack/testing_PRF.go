package main

import(
	"fmt"
	"crypto/hmac"
	"crypto/sha256"
	"hash"
	"encoding/hex"
)

func pHash(result, secret, seed []byte, hash func() hash.Hash) {
	h := hmac.New(hash, secret)
	h.Write(seed)
	a := h.Sum(nil)
	
	j := 0
	for j < len(result) {
		h.Reset()
		h.Write(a)
		h.Write(seed)
		b := h.Sum(nil)
		todo := len(b)

		if j+todo > len(result) {
			todo = len(result) - j
			}
		copy(result[j:j+todo], b)
		j += todo
		
		h.Reset()
		h.Write(a)
		a = h.Sum(nil)
	}
}

func test_PRF() {
	// test vectors from: https://www.ietf.org/mail-archive/web/tls/current/msg03416.html
	// testing TLS1.2PRF-SHA256

	Secret, _ := hex.DecodeString("9bbe436ba940f017b17652849a71db35")
	Seed_, _ := hex.DecodeString("a0ba9f936cda311827a6f796ffd5198c")
	Label := "test label"

	/*
	Output (100 bytes):
	0000    e3 f2 29 ba 72 7b e1 7b    ....r...
		0008    8d 12 26 20 55 7c d4 53    ... U..S
	0010    c2 aa b2 1d 07 c3 d4 95    ........
		0018    32 9b 52 d4 e6 1e db 5a    2.R....Z
	0020    6b 30 17 91 e9 0d 35 c9    k0....5.
		0028    c9 a4 6b 4e 14 ba f9 af    ..kN....
		0030    0f a0 22 f7 07 7d ef 17    ........
		0038    ab fd 37 97 c0 56 4b ab    ..7..VK.
		0040    4f bc 91 66 6e 9d ef 9b    O..fn...
		0048    97 fc e3 4f 79 67 89 ba    ...Oyg..
		0050    a4 80 82 d1 22 ee 42 c5    ......B.
		0058    a7 2e 5a 51 10 ff f7 01    ..ZQ....
		0060    87 34 7b 66                .4.f
*/
	// seed
	seed := make([]byte, 0, len(Label) + len(Seed_))
	seed = append(seed, Label...)
	seed = append(seed, Seed_...)

	// PRF!
	output := make([]byte, 100)
	pHash(output, Secret, seed, sha256.New)

	fmt.Printf("%x", output)
}

func main() {
	test_PRF()
}
