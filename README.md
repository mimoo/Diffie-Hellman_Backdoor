# How to backdoor Diffie-Hellman

This repo contains some research I'm **currently** doing on how to bakdoor Diffie-Hellman:

* ![backdoor_generator/](backdoor_generator/) everything to generate and export parameters for a Diffie-Hellman backdoor
* ![attack/](attack/) the setup to perform the Man-In-The-Middle attack on both Socat and Apache2 (works on Socat/OpenSSL only for now)
* ![socat_reverse/](socat_reverse/) contains work on reversing the backdoor in the old 1024bits socat modulus and checking the security of the new 2048bits one.

Other repositories were created during this research:

* [github/test_DHparams](https://github.com/mimoo/test_DHparams) contains a tool to check your Diffie-Hellman parameters (is the modulus long enough? Is it a safe prime? ...)

* [github/GoNTL](https://github.com/mimoo/GoNTL) contains an extension of the go bignumber library along with an implementation of Pollard Rho for discrete logarithm


