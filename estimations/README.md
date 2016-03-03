# Estimations on the discrete logarithm problem

There isn't much source on what is accomplishable with Pollard Rho and its different versions.

Most records have been using the NFS algorithm because of large modulus, but in our backdoor we are interested in small orders so Pollard Rho is more relevant.

This are the current tests, done on a last generation macbook pro.

![OSX](http://i.imgur.com/3bAQLN4.png)

The implementation is of the First generation Pollard Rho, taken directly from the Handbook of Applied Cryptography Chapter 3.

![table](http://i.imgur.com/Fca89Bv.png)

Simply trying everything is fast enough up to around 23bits. Then it takes minutes. The first generation Pollard Rho works extremly well under 40bits.

* I'm hopping Pollard Rho lambda and newer optimizations could improve this.

* Also writing that in Go would be **COOL** + maybe faster?

