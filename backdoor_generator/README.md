# Ways to generate a non-prime DH modulus to create a NOBUS backdoor

Check the next section [How to build a secure NOBUS backdoor](how-to-build-a-secure-nobus-backdoor) for the theory behind the numbers.

Here are the different methods you can use to build the DH backdoor:

1. [modulus p is prime, p-1 have 'small' factors]()
1. [modulus = pq with p-1 and q-1 smooth]()
1. [same as above but partially smooth]()
1. [modulus = p_1*p_2*p_3*p_4 with no smooth p_i-1]()
1. [modulus = pq with p-1 partially smooth, g generates the smooth part]()
1. [modulus = pq with p-1 SNFS-friendly (factors are SNFS primes)]()

## How to build a secure NOBUS backdoor

The obvious way is to ease the discrete logarithm problem of one of the public key. This can be achieved by making one of the following discrete logarithm easier:

* Pollard Rho
* NFS
* SNFS
* Pohlig-Hellman

### The NOBUS part

* Making Pollard Rho easy would mean making it easy for anyone.

* NFS/SNFS? (to be researched...)

* Pohlig-Hellman only requires that the factorization of the order is known only to you.

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

> According to state-of-the-art, the difficulty of solving DLOG in prime order fields of size 2n is, up to constants, asymptotically equivalent to that of breaking n-bit RSA. In practice though, DLOG is noticeably more difficult.

To make the backdoor exploitable, each prime factor `p` of `n` participating in the base's `g` order have to be small enough so that the discrete logarithm is "doable" in the multiplicative group `(Z_p)*`.

Of course doable varies according to the computing power of the adversary:

* easy: small groups are ~20 bits
* medium: small groups are ~40 bits
* hard: small groups are ~60bits

This part should be re-worked after some benchmarking of Pollard Rho.

To make it a NOBUS `p-1` should be

## Method 1: Modulus p is prime, p-1 have 'small' factors

The first method we could think of is to use a prime modulus `p` which `p-1` factorization has to be known only to you. Then a combination of one or many of the 'small' factors of `p-1` could be your base's order. 

exploitability:

* Pohlig-Hellman need the 'small' factors to be small enough

Nobus:

* `p-1` has to be big enough to be resistant to factorizations like QS and NFS
* `p-1` factors have to be greater than 300 bits
* `p-1` factors `p_i` have to be checked s.t. `p_i - 1` are not smooth

proposition:

* None. Since the factors have to be greater than 300 bits, we cannot exploit this.


## Method2: modulus = pq with p-1 and q-1 smooth

`n = p_1 * ... * p_n` where `p_i - 1` are smooth

There is a proof of concept of that method in [`PoC.sage`](PoC.sage)

## n = p^i

`n = p^i`, a power prime. 

If `i = 2` and `n` is a 1024 bits number, then `p` is a 512bits number

It's basically the same method as the previous one but it seems easier to generate (although the previous method is pretty easy to generate, see the [proof of concept](PoC.sage))

## MOAR

see this crypto stackexchange [answers](http://crypto.stackexchange.com/questions/32415/how-does-a-non-prime-modulus-for-diffie-hellman-allow-for-a-backdoor/32431)

