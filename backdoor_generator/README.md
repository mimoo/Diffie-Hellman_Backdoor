# Ways to generate a non-prime DH modulus to create a NOBUS backdoor

**WORK IN PROGRESS** **I actually have reached different conclusions atm**

This `README` documents the different methods researched and implemented in [backdoor_generator.sage](backdoor_generator.sage) to build a DH backdoor.

The last section of this `README` is on [How to build an exploitable NOBUS backdoor](how-to-build-an-exploitable-nobus-backdoor) for the theory behind the numbers.

You can also use [dhparams_exporter.py](dhparams_exporter.py): a script to export your backdoored parameters to *go* code or an *ASN.1 DER* encoded file (for OpenSSL).

[test_backdoor.sage](test_backdoor.sage) is a script that tests the backdoored DH parameters you generated via [backdoor_generator.sage](backdoor_generator.sage).

## How to build an exploitable NOBUS backdoor

The obvious way is to ease the discrete logarithm problem of one of the public key. This can be achieved by making one of the following discrete logarithm easier:

* Pollard Rho (`O(sqrt(p))` with `p` the order of the base)
* NFS (depends on the modulus)
* SNFS (depends on the modulus as well)
* Pohlig-Hellman (`O(sqrt(q))` with `q` largest factor of the order)

### The NOBUS part

* Making Pollard Rho easy would mean making it easy for anyone.

* NFS/SNFS? (to be researched...)

* Pohlig-Hellman requires that the factorization of the order is known to you in order to be used. There is an obvious trapdoor here that could be used.

So to make a NOBUS backdoor, the obvious ways seems to be:

* use a prime modulus `p` s.t. `p-1` factorization is known only to you.
* use a composite modulus `n` whose factorization has to be known only to you.

This also means that in both case it cannot be easily factorable (by p-1, ECM, QS, NFS...):

* To counter against NFS and QS the size of the modulus is enough. Let's say 1024bits or even 2048bits.
* To counter against ECM the factors have to be greater than 300bits [record is 263bits](http://www.loria.fr/~zimmerma/records/factor.html).
* To counter against p-1 the (relevant to the base) factors should be either be B-smooth with B large enough. ([records](http://www.loria.fr/~zimmerma/records/Pminus1.html) are 10^10, so ~34bits) or it should contain at least one 'large' factor (record is 10^15, so ~50bits).

*Note* that NFS seems to be one of the possible answer if you're the NSA. In the logjam paper, months of pre-computation on a 512bits DH modulus permits to do DLOG in seconds afterwards. They believe the NSA has enough power to do the precomputation for 1024bits DH. Why this shouldn't be the case:

* too much work compared to other solutions.
* need to use the same modulus on every backdoored implementation: easier to detect.

### The exploitability of the backdoor

To make the backdoor exploitable, each prime factor `p` of `n` participating in the base's `g` order have to be small enough so that the discrete logarithm is "doable" in the multiplicative group `(Z_p)*`.

Of course doable varies according to the computing power of the adversary:

* easy: small groups are ~20 bits
* medium: small groups are ~40 bits
* hard: small groups are ~60bits

This part should be re-worked after some benchmarking of Pollard Rho.

To make it a NOBUS `p-1` should be

## Method 1: Modulus p is prime, p-1 have 'small' factors

The first method we could think of is to use a prime modulus `p` which `p-1` factorization has to be known only to you. Then a combination of one or many of the 'small' factors of `p-1` could be your base's order. 

Nobus:

* `p-1` has to be big enough to be resistant to factorizations like QS and NFS.
* `p-1` factors have to be greater than 300 bits to be resistant to ECM.
* `p-1` factors `p_i` have to be checked s.t. `p_i - 1` are not smooth to be resistant to Pollard p-1.

Exploitability:

* Pohlig-Hellman need the 'small' factors to be small enough.

proposition:

* None. Since the factors have to be greater than 300 bits, the DLOG would be done in 2^300 operations. We cannot exploit this.


## Method 1: place g in a discrete-log-doable subgroup

Since there is no way to build a NOBUS backdoor with a prime modulus, we will now look into composite modulus.

> According to state-of-the-art, the difficulty of solving DLOG in prime order fields of size 2n is, up to constants, asymptotically equivalent to that of breaking n-bit RSA. In practice though, DLOG is noticeably more difficult. Moreover, DLOG is in most standardized algorithms performed in a smaller subgroup, and then the size of this subgroup matters too, in which case the symmetric key equivalent is theoretically half of the bit-size of said subgroup, again according to the same generic attacks applicable also in the EC case. This would imply DLOG sub-groups of the same size as a corresponding EC group. Note though that performing exponentiations over a finite field is noticeably more expensive than on an elliptic curve of equivalent security. (The difference can be on the order 10-40 times, depending on security level.)

http://www.ecrypt.eu.org/ecrypt2/documents/D.SPA.20.pdf

knowing the factorization of `n = pq` , we do `y = g^x mod p` and do the dlog there.

* dlog with NFS => prime has to be [512, 1024] ~ [current research, NSA]

* dlog with Pollard Rho => prime can be smaller

-- notes --

We set `n = p_1 * p_2 * p_3` with `p_i` of around the same size, s.t. `(p_i-1)/2` is prime (safe primes)

Nobus:

* `p_i` should be around 400 to 500bits to counter the ECM factorization

Exploitability:

* Pohlig-Hellman will have to do the DLOG modulo each `p_i - 1`

Proposition:

* The factors of `n` are too big to do Pohlig-Hellman. This method doesn't seem to bring anything to the other method?



## Method 2: modulus = pq with p-1 SNFS-friendly (factors are SNFS primes)

We can try to make the subgroup of the previous method bigger by using a SNFS prime.

## Method 3: modulus = pq where (p-1)/2 has small factors for Pohlig-Hellman

NFS and SNFS involves a lot of pre-computation. It seems like there should be "Easier" to exploit backdoors using Pohlig-Hellman. To do that we need the order of the generator to have 'small' factors.

This method creates a modulus `n = p_1 * ... * p_k` where each `(p_i - 1)/2` is a composite of 'small' factors: each `(p_i - 1)/2 = q_1 * ... * q_l` with `q_i` 'small'

Nobus:

* Since the factors of `(p_i-1)/2` are 'small', i's highly possible that *Pollard's p-1* factorization algorithm could factor the modulus.

Exploitability:

* `q_i` have to be 'small' enough for Pohlig-Hellman.

Proposition:

* a 1024bits modulus `n = p_1 * p_2` with both `p_1` and `p_2` 512 bits
* `(p_1-1)/2 = q_1 * ... * q_10` with `q_i` ~ 50bits
* generator `g` of order `q_1 * ... * q_10`
* `(p_2-1)/2` can be safe-prime to avoid Pollard's p-1


## Method 4: modulus = pq with p-1 partially-smooth

This is the same method as method 2 above, except that we can avoid Pollard's p-1 with another trick: we can have an extra 'large enough' factor of `(p_1-1)/2`. We do not need to use it in Pohlig-Hellman, it just have to be here to counter the factorization attack.

Proposition:

* a 1024bits modulus `n = p_1 * p_2` with both `p_1` and `p_2` 512 bits
* `(p_1-1)/2 = q_1 * ... * q_8 * L` with `q_i` ~ 50bits and `L` ~ 100bits
* generator `g` of order `q_1 * ... * q_8`
* `(p_2-1)/2` can be safe-prime to avoid Pollard's p-1
