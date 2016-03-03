# How to backdoor Diffie-Hellman, lessons learned from the Socat non-prime prime

This repo contains some research I'm **currently** doing on the Socat backdoor:

* ![backdoor_generator/](backdoor_generator/) everything to generate parameters for a DH backdoor
* ![attack/](attack/) contains everything to generate the attack on both Socat and Openssl (still not fully working)
* ![PoC.sage](PoC.sage) is a (now *old*) proof of concept (generation + small subgroup attack)
* ![socat_reverse/](socat_reverse/) contains work on reversing the backdoor in the old 1024bits socat modulus and checking the security of the new 2048bits one.
* ![estimations/](estimations/) hopefuly soon it will be full with estimations on Pohlig-Hellman and Pollard Rho
* ![whitepaper.tex](whitepaper.tex) wannabe whitepaper

* [github/test_DHparams](https://github.com/mimoo/test_DHparams) contains a tool to check your Diffie-Hellman parameters (is the modulus long enough? Is it a safe prime? ...)

Also, this page is getting long so here's a table of content:

1. [Socat? What?](#socat-what-timeline-of-events)
2. [Human Error](#human-error)
3. [How to implement a NOBUS backdoor](#how-to-implement-a-nobus-backdoor-in-dh)
4. [How to reverse socat's non prime modulus](#how-to-reverse-socats-non-prime-modulus)
5. [How is the attacker using the backdoor](#how-is-the-attacker-using-the-backdoor)
6. [What about socat's new prime modulus?](#what-about-socats-new-prime-modulus)
7. [Resources](#resources)


## How to implement a NOBUS backdoor in DH

There seem to be different ways, with different consequences, to do that. [backdoor_generator/backdoor_generator.sage](backdoor_generator/backdoor_generator.sage) allows you to generate backdoored DH parameters according to these different techniques, the explanations are in the source as well as the [README there](backdoor/README.md).

![backdoor generator menu](http://i.imgur.com/ReNnJ7U.png)

![backdoor generator result](http://i.imgur.com/klxlZpB.png)

There is also a working proof of concept in [PoC.sage](PoC.sage) that implements one way of doing it: 

It creates a non-prime modulus `p = p_1 * p_2` with `p_i` primes, such that
`p_i - 1` are smooth. Since the order of the group will be `(p_1 - 1)(p_2 - 1)` (smooth) and known only to the malicious person who generated `p`, *Pohlig-Hellman* (passive) or a *Small Subgroup Confinment attack* (active) can be used to recover the private key.

In the proof of concept the small subgroup attack is implemented instead of Pohlig-Hellman just because it seemed easier to code. They are relatively equivalent except that in practice an ephemeral key is used which makes small subgroup attacks not practical.

Note that these issues should not arrise if the DH parameters were generated properly, that is the order and subgroups orders should be known. If the prime is a safe prime, you don't need to do anything. If it is not, it might be that the order of the group (`p-1`) is smooth, this is a bad idea but nonetheless you can verify that the public key received lies in the correct subgroup by raising it to the power of the subgroup. See [rfc2785](https://tools.ietf.org/html/rfc2785) for more information.

![proof of concept](http://i.imgur.com/L7cNJP0.png)

The proof of concept is a step by step explanation of what's happening. Above you can see the generation of the backdoored modulus, bellow you can see the attack tacking place and recovering discrete logs of each of the subgroups

![discrete logs](http://i.imgur.com/kKgNjmh.png)

To run it yourself you will need Sage. You can also use an online version of it a [cloud.sagemath.com](http://cloud.sagemath.com).

## How to reverse socat's non-prime modulus

from what we learned in implementing such a backdoor, we will see how we can reverse it to use it ourselves.

**Trial division** (testing every small primes up to a certain limit) has already found two small factors: 271 and 13,597. The last factor is still a composite of 1002 bits (302  digits) that we'll call C302 (C for Composite).

I tested if the generator (2) has order 271-1 or 13,597-1 or (271-1)*(13,597-1). But no.

**Pollard's p-1** factorization algorithm should work fine for finding factors `p` if `p-1` is smooth.

[The records people have reached with this algorithm](http://www.loria.fr/~zimmerma/records/Pminus1.html) is to factor a ~200bits composite which largest factor was a 50bits and other factors under 30bits (with B1=10^10 and B2 =10^15).

But an attacker could have easily chosen factors of `p-1` and `q-1` to be of size > 50bits which would have canceled any possibility of Pollard's p-1 to factor `p` or `q`. He could have also added two 60 bits factors to void the B2 bound as well.

Another very good algorithm at factoring is the **Elliptic Curve Method** or  [ECM](https://en.wikipedia.org/wiki/Lenstra_elliptic_curve_factorization), that only depends on the size of the smallest factor.

[The records](http://www.loria.fr/~zimmerma/records/top50.html) found factors of size 276bits. This is again a problem if the backdoored modulus is composed of two 512bits primes.

**The Quadratic Sieve**, or [QS](https://en.wikipedia.org/wiki/Quadratic_sieve) algorithm running-time depends on the modulus's size, best for numbers under 400-500bits, and so is out of reach for our big 1024bits modulus.

> Then, at some predetermined point where ECM is less likely to find a factor over time than the time taken to run a sieve method, you switch from ECM to the sieve method, which is SIQS below ~100 digits and NFS above 100 digits. These sieve methods are different in that they take a fixed amount of time for a given input number, and are guaranteed* to produce a factorization at the end. ([Dubslow](http://www.mersenneforum.org/showpost.php?p=427248&postcount=22))

Finally the **General Number Field Sieve**, or the [GNFS](https://en.wikipedia.org/wiki/General_number_field_sieve) algorithm, which works according to the size of the entire modulus and not its factors, has a [record of factoring 768bits](https://en.wikipedia.org/wiki/RSA_Factoring_Challenge#The_prizes_and_records) in 2009. That might be our best bet, although the modulus is still too big for us to try. In the [Logjam](https://weakdh.org/) paper last year could be read that the NSA might have the capacity to do it.

Q: What are the chances that if this was non-prime was a mistake, it generated factors large enough so that no one can reverse it?

A: From Handbook of Applied Cryptography fact 3.7:

> Let n be chosen **uniformly at random** form the interval [1, x]
> 1. if 1/2 <= a <= 1, then the probability that the largest prime factor of n is <= x^a is approximately 1+ ln(a). Thus, for example, the probability than n has a prime factor > sqrt(x) is ln(2) ~= 0.69
> 2. The probability that the second-largest prime factor of n is <= x^{0.2117} is about 1/2
> 3. The expected total number of prime factors of n is ln ln x + O(1). (If n = mult(p_i^{e_i}), the total number of prime factors of n is sum(e_i).)

This means three things:

1. item socat's 1024 bit composite modulus `n` probability to have a prime factor greater than 512 bits is ~0.69.
2. the probability that the second-largest prime factor of `n` is smaller than 217 bits is 1/2.
3. The total number of prime factor of `n` is expected to be 7 (we already have 2).

217 bits is feasible to find with ECM (maybe with p-1 factorization algorithm)

## How is the attacker using the backdoor?

Note: More info can be found in [backdoor_generator/README.md](backdoor_generator/README.md).

1. The attacker knows the *factorization of the modulus*
2. That means he knows the *factorization of the order*
3. He can compute the discrete logarithm in each subgroup and re-combine them to the real discrete logarithm ([Pohlig-Hellman](https://en.wikipedia.org/wiki/Pohlig%E2%80%93Hellman_algorithm)). This can be done passively with PH, or actively ([small subgroup confinment attack](https://en.wikipedia.org/wiki/Small_subgroup_confinement_attack)) by sending points of different subgroup instead of computing them with PH.

How does he compute the Discrete Logarithm?

[Most records](https://en.wikipedia.org/wiki/Discrete_logarithm_records) use the **NFS** algorithm to compute the DLOG. The best so far is modulo 596 bits. Logjam did tackle a 512 bits as well.

But there exists faster and easier to use algorithms that work in `O(sqrt(modulus))` like **Pollard Rho** or **Baby-Step-Giant-Step**. That means in a subgroup of prime order 64bits, these algorithms would compute a discrete logarithm in ~2^32 operations.

Note: In our proof of concept [PoC.sage](PoC.sage), the subgroups are so small (<20bits) that the naive approach of testing all powers of the generator is fast enough to compute the discrete logarithm of all the subgroups.


## Resources

### Socat's non-prime modulus

* [Thai Duong's blogpost](http://vnhacker.blogspot.com/2016/02/exploiting-diffie-hellman-bug-in-socat.html)
* [crypto stackexchange's post](http://crypto.stackexchange.com/questions/32415/how-does-a-non-prime-modulus-for-diffie-hellman-allow-for-a-backdoor/32431?noredirect=1)
* [reddit's thread](https://www.reddit.com/r/crypto/comments/43wh7h/the_socat_backdoor/)
* [metzdowd's discussion](http://www.metzdowd.com/pipermail/cryptography/2016-February/028033.html)

### Pohlig-Hellman

* [Pohllig, Hellman - An Improved Algorithm for Computing Logarithms over GF(p) and Its Cryptographic Significance (1978)](http://www-ee.stanford.edu/~hellman/publications/28.pdf)

* [Maurer, Yacobi - Non-interactive Public Key Cryptography (1991)](http://link.springer.com/chapter/10.1007%2F3-540-46416-6_43#page-1) section4

* [Joux, Odlyzko, Pierrot - The Past, evolving Present and Future of Discrete Logarithm (2014)](https://www-almasty.lip6.fr/~pierrot/papers/DlogSurvey.pdf)

### Backdoors in general

* [Paper keys under doomarts](https://www.schneier.com/cryptography/paperfiles/paper-keys-under-doormats.pdf)
* [Surreptitiously Weakening Cryptographic Systems](https://eprint.iacr.org/2015/097.pdf)
