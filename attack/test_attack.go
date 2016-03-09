package main

import(
	"log"
	"github.com/mimoo/GoNTL"
	"math/big"
)

// the attack
func main() {

	// the backdoor parameters
	var dh1024_n = [39]byte{64, 150, 51, 112, 121, 135, 0, 85, 130, 105, 102, 2, 39, 121, 85, 40, 33, 71, 100, 48, 133, 38, 136, 1, 23, 116, 121, 18, 9, 105, 71, 50, 23, 153, 135, 84, 70, 0, 19}
	var dh1024_g = [38]byte{82, 71, 99, 49, 129, 98, 97, 53, 71, 98, 130, 116, 70, 53, 37, 17, 24, 101, 117, 89, 49, 36, 68, 120, 89, 22, 37, 54, 68, 41, 9, 70, 48, 152, 67, 87, 130, 89}
	var p string = "251153300769938074253856282383556425027"
	var q string = "1631010648600788382336119717304312773519"
	var p_small string = "244159"
	var q_small string = "1478123"

	// convert to big.Int
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

	// create the server public key
	secret := new(big.Int)
	secret.SetString("251153390699388953856282332983556425027", 10)
	y := new(big.Int)
	y.Exp(generator, secret, modulus)

	// divide the problem in p and q
	yp := new(big.Int)
	yp.Mod(y, prime1)

	yq := new(big.Int)
	yq.Mod(y, prime2)
	
	// Pollard Rho of each problem
	log.Println("y", y.String())
	log.Println("yp", yp.String())
	log.Println("yq", yq.String())
	xp := gontl.Pollard_Rho(yp, generator, prime1, order1, gontl.Big0, gontl.Big0)
	log.Println("xp", xp.String())

	xq := gontl.Pollard_Rho(yq, generator, prime2, order2, gontl.Big0, gontl.Big0)
	log.Println("xq", xq.String())

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
	/*
	y2 := new(big.Int)
	y2.SetBytes(clientPubkey)

	x1.Exp(y, x1, modulus) // first solution

	x2.Exp(y, x2, modulus) // second solution
*/
}


