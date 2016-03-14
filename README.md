# How to backdoor Diffie-Hellman

This repo contains some research I'm **currently** doing on how to bakdoor Diffie-Hellman:

* ![backdoor_generator/](backdoor_generator/) everything to generate and export parameters for a Diffie-Hellman backdoor
* ![attack/](attack/) the setup to perform the Man-In-The-Middle attack on both Socat and Apache2 (works on Socat/OpenSSL only for now)
* ![socat_reverse/](socat_reverse/) contains work on reversing the backdoor in the old 1024bits socat modulus and checking the security of the new 2048bits one.

Other repositories were created during this research:

* [github/test_DHparams](https://github.com/mimoo/test_DHparams) contains a tool to check your Diffie-Hellman parameters (is the modulus long enough? Is it a safe prime? ...)

* [github/GoNTL](https://github.com/mimoo/GoNTL) contains an extension of the go bignumber library along with an implementation of Pollard Rho for discrete logarithm

## How to implement a NOBUS backdoor in DH

There seem to be different ways, with different consequences, to do that. [backdoor_generator/backdoor_generator.sage](backdoor_generator/backdoor_generator.sage) allows you to generate backdoored DH parameters according to these different techniques, the explanations are in the source as well as the [README there](backdoor/README.md).

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
