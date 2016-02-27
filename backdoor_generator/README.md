# Ways to generate a non-prime DH modulus to create a NOBUS backdoor

Here is a list of ways to build a NOBUS backdoor into Diffie-Hellman by constructing a proper modulus `n`.

From Handbook of Applied Cryptography fact 3.79:

> the DLP in (Z_n)* reduces to: 1) FACTORIZATION of n and 2) DLP in (Z_p)* for each prime p factor of n

So:

* to make a NOBUS backdoor, `n`'s factorization has to be known only to the malicious person. This also means it cannot be easily factorable.

* to make the backdoor exploitable, each prime factor `p` of `n` has to be small enough so that DLP is "doable" in (Z_p)*. Doable varies according to the computing power of the adversary.


## n = p_1 * ... * p_n

`n = p_1 * ... * p_n` where `p_i - 1` are smooth

There is a proof of concept of that method in [`PoC.sage`](PoC.sage)

## n = p^i

`n = p^i`, a power prime. 

If `i = 2` and `n` is a 1024 bits number, then `p` is a 512bits number

It's basically the same method as the previous one but it seems easier to generate (although the previous method is pretty easy to generate, see the [proof of concept](PoC.sage))

## MOAR

see this crypto stackexchange [answers](http://crypto.stackexchange.com/questions/32415/how-does-a-non-prime-modulus-for-diffie-hellman-allow-for-a-backdoor/32431)

