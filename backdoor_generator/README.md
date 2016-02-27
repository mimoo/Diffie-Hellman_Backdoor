# Ways to generate a non-prime DH modulus to create a NOBUS backdoor

Here are the different methods you can use to build the DH backdoor:

1. [modulus p is prime, p-1 have 'small' factors]()
1. [modulus = pq with p-1 and q-1 smooth]()
1. [same as above but partially smooth]()
1. [modulus = p_1*p_2*p_3*p_4 with no smooth p_i-1]()
1. [modulus = pq with p-1 partially smooth, g generates the smooth part]()
1. [modulus = pq with p-1 SNFS-friendly (factors are SNFS primes)]()

And the last section is on [How to build a secure NOBUS backdoor](how-to-build-a-secure-nobus-backdoor) for the theory behind the numbers.

Also this directory includes:

* [backdoor_generator.sage](backdoor_generator.sage): the script to generate the backdoored parameters
* [dhparams_exporter.py](dhparams_exporter.py): a script to export 

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

    Description
    * This method creates a modulus n = p_1 * ... * p_{number_of_factors}
    with each p_i - 1 smooth, that is, each p_i - 1 = q_1 * ... * q_{something} 
    * `something` is calculated according to `smooth_size`:
    each q_i is of size ~ `smooth_size`

    How to use the backdoor
    * To use this backdoor you need to keep track of each q_i
    * Pohlig-Hellman will have to do the DLOG modulo every q_i
    * To verify that the `smooth_size` is low enough: try to compute a DLOG on a q_i

    NOBUS?
    * Since each p_i-1 are smooth, i's highly possible that
    Pollard's p-1 factorization algorithm could factor the modulus


## Method3: modulus = pq with p-1 and q-1 partially-smooth

    Description
    * This is the same method as method 2 above, except:
    one q_i (we'll call it q_B2) of each p_i-1 is big.
    * This makes the p_i-1 "partially" smooth

    How to use the backdoor
    * To use this backdoor you need to keep track of each q_i
    * Pohlig-Hellman will have to do the DLOG modulo every q_i
    * To verify that the `B2_size` is low enough: try to compute a DLOG on a q_B2

    NOBUS?
    * Since both p-1 and q-1 have a large factor, 
    * Pollard's p-1 would need a B2 bound too large to work efficiently.
    * ECM could still work if the large factor is not large enough


## Method4: modulus = p_1*p_2*p_3*p_4 with no smooth p_i-1

    Description
    * n = \prod p_i with each p_i the same large size and
    p_i - 1 = 2q_i with q_i prime (so p_i - 1 are not smooth)
    
    How to use the backdoor
    * To use this backdoor you need to keep track of each p_i
    * Pohlig-Hellman will have to do the DLOG modulo each p_i - 1
    * This is a large modulus, for a 1024 bits dh modulus the dlogs will
    have to be done modulus 256 bits prime

    NOBUS?
    * Since none of the p_i - 1 are smooth, Pollard's p-1 would not yield anything
    * But 256bits factors are "easy" to find
    * You also have "not easy" DLOG to do


## Method5: modulus = pq with p-1 partially smooth, g generates the smooth part

    Description
    * n = pq and p-1 has large factors except for a small one that will
    be our generator's subgroup


## Method6: modulus = pq with p-1 SNFS-friendly (factors are SNFS primes)

to be researched...
