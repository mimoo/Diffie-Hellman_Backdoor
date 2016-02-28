# Reversing Socat's non-prime prime

The composite prime is 1024bits long, which is too much to try factorization algorithms like QS and GNFS that depend on the number's size.

Instead I tried factoring it with both ECM and Pollard's p-1. The latter is used because it is likely that one of the factor `p` of the order has a 'small' factorization of  `p-1`.

If the backdoor was done properly, or if the number was uniformly generated. It's possible that we won't find anything using this methods.

But first, trial divisions gave us 2 numbers: 271 and 13,597. The remaining factor is still a composite of 1002 bits (302  digits) that we'll call C302 (C for Composite).

## ECM

a run with B1 = 1000000000 and automatic B2 didn't find anything after ~52 hours

```bash
$ ecm 1000000000 < socat_1024dh_p
GMP-ECM 6.4.4 [configured with GMP 6.0.0, --enable-asm-redc] [ECM]
Input number is 38894884397634366007356454548332370646972724268802781973440208895542936165564656473524541403310393405820598366261673173802130771236325314878371830363723788045821711985461441675679316058246609104355161134470046705337593170498462616195650378975298117141144096886684800236261920005248055422089305813639519 (302 digits)
Using B1=1000000000, B2=19071176724616, polynomial Dickson(30), sigma=943042405
Step 1 took 10019112ms
Step 2 took 1429277ms
```

## P-1

I didn't save the previous run, although it found nothing. currently running with B1 = 10^12 which might be way too big. Will post the seed once done.

```bash
$ ecm -save socat_ecm_progress -pm1 1e12 1e15 < socat_1024dh_q
GMP-ECM 6.4.4 [configured with GMP 6.0.0, --enable-asm-redc] [P-1]
Input number is 38894884397634366007356454548332370646972724268802781973440208895542936165564656473524541403310393405820598366261673173802130771236325314878371830363723788045821711985461441675679316058246609104355161134470046705337593170498462616195650378975298117141144096886684800236261920005248055422089305813639519 (302 digits)
Using B1=1000000000000, B2=1324293386181580, polynomial x^1, x0=785660251
```

