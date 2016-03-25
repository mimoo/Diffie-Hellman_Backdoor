# Estimations on the discrete logarithm problem

There isn't much source on what is accomplishable with Pollard Rho and its different versions.

Most records have been using the NFS algorithm because of large modulus, but in our backdoor we are interested in small orders so Pollard Rho is more relevant.

These are the current tests, done on a last generation MacBook Pro.

![OSX](http://i.imgur.com/3bAQLN4.png)

* `trials` is the naive trial multiplication approach
* `old_rho` is the implementation of the First generation Pollard Rho, taken directly from the Handbook of Applied Cryptography Chapter 3
* `rho_lambda` is the first generation Pollard Kangaroo
* `rho_sage` is the Sage 6.10.beta1 `discrete_log_rho` function.

| Modulus size (bits) | DLOG algorithm | Time (s) |
|---------------------|----------------|----------|
| 10                  | trials         | 0        |
| 10                  | old_rho        | 0        |
| 10                  | rho_lambda     | 0        |
| 10                  | rho_sage       | 0        |
| 20                  | trials         | 2        |
| 20                  | old_rho        | 0        |
| 20                  | rho_lambda     | 11       |
| 20                  | rho_sage       | 0        |
| 30                  | old_rho        | 0        |
| 30                  | old_sage       | 0        |
| 40                  | old_rho        | 38       |
| 40                  | rho_sage       | 4        |
| 45                  | rho_sage       | 20       |
| 50                  | rho_sage       | 146      |

Simply trying everything is fast enough up to around 23bits. Then it takes minutes. The first generation Pollard Rho works extremly well under 40bits.

* I'm hoping Pollard Rho lambda and newer optimizations could improve this.

* Also writing that in Go would be **COOL** + maybe faster?

