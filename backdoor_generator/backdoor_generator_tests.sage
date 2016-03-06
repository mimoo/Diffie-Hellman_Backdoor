# Handbook of applied crypto Pollard Rho
def Pollard_rho(public_key, order, generator, modulus, a=0, b=0):
    """ This is the implementation of the algorithm introduced in
    the Handbook of Applied Cryptography chapter 3.6.3
    It is definitely not the latest improvement, 
    nor the parallelizable version.
    You need to know the order of the generator to use it
    """
    # initialization
    alpha = generator # to keep the same variables as in the book
    beta = public_key

    if a != 0 or b != 0: # <- wrong
        x = Mod(power_mod(alpha, a, modulus) * power_mod(beta, b, modulus), modulus)
    else:
        x = Mod(1, modulus)

    x = [x, x]
    a = Mod(a, order)
    a = [a, a]
    b = Mod(b, order)
    b = [b, b]
    
    # iteration function
    def iteration(x, a, b):
        if Mod(x, 3) == 1: # x in S_1 (chosen from example)
            x = beta * x
            b = b + 1

        elif Mod(x, 3) == 0: # x in S_2
            x = x * x
            a = 2 * a
            b = 2 * b

        else: # x in S_3
            x = alpha * x
            a = a + 1

        return x, a, b

    # loop
    while True:
        # iteration function
        x[0], a[0], b[0] = iteration(x[0], a[0], b[0])

        x[1], a[1], b[1] = iteration(x[1], a[1], b[1])
        x[1], a[1], b[1] = iteration(x[1], a[1], b[1])

        # detect collision
        if x[0] == x[1]:
            r = b[0] - b[1]
            if r != 0:
                return r^-1 * (a[1] - a[0])
            else:
                break
                
    # failure
    a = randint(3, order)
    b = randint(3, order)
    return Pollard_rho(public_key, order, generator, modulus, a, b)


def test_method1():
    # setting
    n = 409633707987005582696602277955282147643085268801177479120969473217998754460013
    p, q = 251153300769938074253856282383556425027 ,  1631010648600788382336119717304312773519 
    g = 5247633181626135476282744635251118657559312444785916253644290946309843578259
    p_small, q_small    = 244159 ,  1478123 

    x = randint(2, n-1)
    y = power_mod(g, x, n)

    # discrete log modulo p and q
    yp = y % p
    yq = y % q
    xp = Pollard_rho(yp, p_small, g, p)
    xp = int(xp)
    xq = Pollard_rho(yq, q_small, g, q)
    xq = int(xq)

    # reconstruct x mod (p-1/2)(q-1)
    pp = (p-1)//2
    qq = q-1
    sol1 = xp * qq * inverse_mod(qq, pp) + xq * pp * inverse_mod(pp, qq)
    sol1 = sol1 % (pp*qq)
    sol2 = sol1 + (pp*qq)

    # print solutions
    print "sol1    :", sol1
    print "sol2    :", sol2
    print "realx   :", x
    print "y       :", y
    print "g^sol1  :", power_mod(g, sol1, n)
    print "g^sol2  :", power_mod(g, sol2, n)

    """ Usually at this point we found different solutions,
    it doesn't matter because the shared key for both party will be the same
    and our solution should work
    """

    # simulate party 2
    x2 = randint(2, n-1)
    y2 = power_mod(g, x2, n)

    # check shared keys
    print "key1", power_mod(y2, x, n) # party 1 shared print "key 
    print "key 2", power_mod(y, x2, n) # party 2 shared print "key 
    print "key 3_1", power_mod(y2, sol2, n)
    print "key 3_2", power_mod(y2, sol1, n)
    

if __name__ == "__main__":
    test_method1()
