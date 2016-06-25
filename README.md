# How to backdoor Diffie-Hellman

[The whitepaper is on ePrint](http://eprint.iacr.org/2016/644).

This repo contains research on how to backdoor Diffie-Hellman:

* [backdoor_generator/](backdoor_generator/) contains everything to generate and export parameters for a Diffie-Hellman backdoor.
* [attack/](attack/) contains the setup to perform the Man-In-The-Middle attack on TLS (tested on Socat/OpenSSL so far).
* [socat_reverse/](socat_reverse/) contains work on reversing the "backdoor" discovered in Socat in February 2016.

Other repositories were created during this research:

* [github/test_DHparams](https://github.com/mimoo/test_DHparams) contains a tool to check your Diffie-Hellman parameters (is the modulus long enough? Is it a safe prime? ...)

* [github/GoNTL](https://github.com/mimoo/GoNTL) contains an extension of the go bignumber library along with an implementation of Pollard Rho for discrete logarithm


