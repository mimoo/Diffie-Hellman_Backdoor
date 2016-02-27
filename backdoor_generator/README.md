# Ways to generate a non-prime DH modulus to create a NOBUS backdoor

Here are the different methods you can use to build the DH backdoor:

1. [Method 1: Modulus p is prime, p-1 have 'small' factors](method-1-modulus-p-is-prime-p-1-have-small-factors)
1. [Method 2: modulus = pq with p-1 smooth](method-2-modulus-pq-with-p-1-smooth)
1. [Method 3: modulus = pq with p-1 partially-smooth](method-3-modulus-pq-with-p-1-partially-smooth)
1. [modulus = p_1*p_2*p_3*p_4 with no smooth p_i-1]()
1. [modulus = pq with p-1 partially smooth, g generates the smooth part]()
1. [modulus = pq with p-1 SNFS-friendly (factors are SNFS primes)]()

And the last section is on [How to build an exploitable NOBUS backdoor](how-to-build-an-exploitable-nobus-backdoor) for the theory behind the numbers.

Also this directory includes:

* [backdoor_generator.sage](backdoor_generator.sage): the script to generate the backdoored parameters.
* [dhparams_exporter.py](dhparams_exporter.py): a script to export your backdoored parameters to *go* code or an *ASN.1 DER* encoded file (for OpenSSL).
* [tests/](tests/): tests for the backdoored parameters created with the `backdoor_generator.sage` script.

## How to build an exploitable NOBUS backdoor

The obvious way is to ease the discrete logarithm problem of one of the public key. This can be achieved by making one of the following discrete logarithm easier:

* Pollard Rho (`O(sqrt(p))` with `p` the order of the base)
* NFS (depends on the modulus)
* SNFS
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


## Method 2: modulus = pq with p-1 smooth

Since there is no way to build a NOBUS backdoor with a prime modulus, we will now look into composite modulus. This method creates a modulus `n = p_1 * ... * p_k` where each `(p_i - 1)/2` is a composite of 'small' factors: each `(p_i - 1)/2 = q_1 * ... * q_l` with `q_i` 'small'

Nobus:

* Since the factors of `(p_i-1)/2` are 'small', i's highly possible that *Pollard's p-1* factorization algorithm could factor the modulus.

Exploitability:

* `q_i` have to be 'small' enough for Pohlig-Hellman.

Proposition:

* a 1024bits modulus `n = p_1 * p_2` with both `p_1` and `p_2` 512 bits
* `(p_1-1)/2 = q_1 * ... * q_10` with `q_i` ~ 50bits
* generator `g` of order `q_1 * ... * q_10`
* `(p_2-1)/2` can be safe-prime to avoid Pollard's p-1


## Method 3: modulus = pq with p-1 partially-smooth

This is the same method as method 2 above, except that we can avoid Pollard's p-1 with another trick: we can have an extra 'large enough' factor of `(p_1-1)/2`. We do not need to use it in Pohlig-Hellman, it just have to be here to counter the factorization attack.

Proposition:

* a 1024bits modulus `n = p_1 * p_2` with both `p_1` and `p_2` 512 bits
* `(p_1-1)/2 = q_1 * ... * q_8 * L` with `q_i` ~ 50bits and `L` ~ 100bits
* generator `g` of order `q_1 * ... * q_8`
* `(p_2-1)/2` can be safe-prime to avoid Pollard's p-1


## Method 4: modulus = p_1*p_2*p_3*p_4 with no smooth p_i-1

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
