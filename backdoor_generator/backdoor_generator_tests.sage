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
    small = False
    if small:
        n = 409633707987005582696602277955282147643085268801177479120969473217998754460013
        p, q = 251153300769938074253856282383556425027 ,  1631010648600788382336119717304312773519 
        g = 5247633181626135476282744635251118657559312444785916253644290946309843578259
        p_small, q_small    = 244159 ,  1478123 
    else:
        n = 109423519767528224387299888812160571977863549562018651093678167563100502546191068886945691026909693084778891719899174693785122277780438033371574158372385675619909656159680772481231551510253625962961496062192935037274983759709222473441081885293077937396959779852246525852479331345971568935426705321065419729661
        p, q = 7323720966914812591055941708221331966484585723722438709794411811359163268313938691329827951251267050560591642529907351637378159060836729528663195017591659, 14940973346998489926743945066580524906625114387157803259698606478035694327084592182142273688331448815700547769593757798760429978677185604346516769767175479
        g = 32483850559328188434549894182960886820302303321915126177094908458926091304352160054754046284869862170109997699701542437843827087743586196385161467001830143489899358697855828016839242722985661372269246110402295328611009948505049189522851363742586097464031737426541218090692193647163279329266030382311566123304
        p_small, q_small = 897696227, 2121852613 

    # setup public/private key
    x = randint(2, n-1)
    y = power_mod(g, x, n)

    print "setting up done"
    
    # discrete log modulo p and q
    yp = GF(p)(y)
    yq = GF(q)(y)
    gp = GF(p)(g)
    gq = GF(q)(g)
    xp = discrete_log_rho(yp, gp, ord=p_small)
    xq = discrete_log_rho(yq, gq, ord=q_small)
    xp = int(xp)
    xq = int(xq)

    print "xp, xq found"

    # reconstructing x mod p_1 p_2
    solt = xp * q_small * inverse_mod(q_small, p_small) + xq * p_small * inverse_mod(p_small, q_small)
    
    # reconstruct x mod (p-1/2)(q-1)
    pp = (p-1)//2
    qq = q-1
    sol1 = xp * qq * inverse_mod(qq, pp) + xq * pp * inverse_mod(pp, qq)
    sol1 = sol1 % (pp*qq)
    sol2 = sol1 + (pp*qq)

    # print solutions
    print "sol1    :", sol1
    print "sol2    :", sol2
    print "solt    :", solt
    print "realx   :", x
    print "y       :", y
    print "g^sol1  :", power_mod(g, sol1, n)
    print "g^sol2  :", power_mod(g, sol2, n)
    print "g^solt  :", power_mod(g, solt, n)

    """ Usually at this point we found different solutions,
    it doesn't matter because the shared key for both party will be the same
    and our solution should work
    """

    # simulate party 2
    x2 = randint(2, n-1)
    y2 = power_mod(g, x2, n)

    # get keys
    key1 = power_mod(y2, x, n) # real shared key from Alice
    key2 = power_mod(y, x2, n) # real shared key from Bob

    key3 = power_mod(y2, sol2, n) # shared key found with solution 2
    key4 = power_mod(y2, sol1, n) # shared key found with solution 1

    # check shared keys
    print "real key1", key1
    print "real key2", key2
    print "our key1", key3
    print "our key2", key4

    if key1 == key2 == key3 == key4:
        print "WE ARE ALL GOOOD :))))"

if __name__ == "__main__":
    test_method1()
