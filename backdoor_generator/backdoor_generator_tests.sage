#################################################################
# DH Backdoor exploit tester
#################################################################
# This tool test the backdoored Diffie-Hellman parameters
#
# several tests are availables
################################################################# 

import pdb

################################################################# 
# Helpers
################################################################# 

# colors
class cc:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    END = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

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
        if int(x) % 3 == 1: # x in S_1 (chosen from example)
            x = beta * x
            b = b + 1

        elif int(x) % 3 == 0: # x in S_2
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


################################################################# 
# Tests
################################################################# 

def test_CM_HSS(small=True):
    # setting
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
    
    # discrete log modulo p and q
    yp = GF(p)(y)
    yq = GF(q)(y)
    gp = GF(p)(g)
    gq = GF(q)(g)
    xp = discrete_log_rho(yp, gp, ord=p_small)
    xq = discrete_log_rho(yq, gq, ord=q_small)
    xp = int(xp)
    xq = int(xq)

    # reconstructing x mod p_1 p_2
    sol= xp * q_small * inverse_mod(q_small, p_small) + xq * p_small * inverse_mod(p_small, q_small)

    # print solutions
    print "* Extracted key        :", sol
    print "* Alice secret key     :", x
    print "* Alice public key     :", y
    print "* Our public key       :", power_mod(g, sol, n)

    # simulate party 2
    x2 = randint(2, n-1)
    y2 = power_mod(g, x2, n)

    # get keys
    key1 = power_mod(y2, x, n) # real shared key from Alice
    key2 = power_mod(y, x2, n) # real shared key from Bob
    key3 = power_mod(y2, sol, n) # shared key found with solution

    # check shared keys
    print "* Shared key from Alice:", key1
    print "* Shared key from Bob  :", key2
    print "* Shared key extracted :", key3

    if key1 == key2 == key3:
        print cc.OKGREEN + "WE ARE ALL GOOOD :))))" + cc.END
    else:
        print cc.WARNING + "WE ARE NOT GOOOD :((((" + cc.END

def test_CM_HSO(small=True):
    if small:
        n          = 19268137865846626851958850322272856396047197682155895684435307978408373065747222697014496202362311549109907458859894354242607160525182604546874472815394580816196765747126365472731269275061518226655168962439072077412577579238431279581950423379707114550984862594479256455246871653608374555649077669
        p, q             = 570853668478777192365118373180099512009639900914548425401110397888084486494265711768517539762811776026858240145585299695637461850362031048765029103 , 33753199689848300442407066691746986229688883915840287800669896943595783069881176522499940807880422002333485157079701615278175199300918469110179966123
        p_order          = 570853668478777192365118373180099512009639900914548425401110397888084486494265711768517539762811776026858240145585299695637461850362031048765029102
        q_order          = 33753199689848300442407066691746986229688883915840287800669896943595783069881176522499940807880422002333485157079701615278175199300918469110179966122
        p_factors        = [2, 232439, 811231, 1843111, 243707, 1150141, 143593, 867371, 1625719, 208393, 1255757, 835553, 860927, 479513, 1581949, 446713, 455783, 740161, 1148527, 1246711, 1179991, 859801, 389447, 970164681287, 1225109]
        q_factors        = [2, 2016752958443, 844117, 422111, 935581, 1573237, 323903, 1265657, 1462759, 242807, 279863, 1794257, 808363, 1301459, 285631, 792037, 1168523, 1136449, 292183, 1050817, 1626137, 376373, 1664561, 1885703, 1170649]
        g = 2

    # setup public/private key
    #x = randint(2, n-1)
    x = 10158765805698842059975984071234248844298026000114333444935461394391907940690012515457612454216052557973931234368572956888753052673325921139445731419491194361879419848813179222618931
    y = power_mod(g, x, n)

    # Pohlig-Hellman in (p-1)/2
    yp = y % p
    xp = 0
    xp_mod = 1

    for order in p_factors[1:]: # to remove the 2
        print "attempting pollard rho in subgroup of order", order
        # reduce the problem
        new_problem = power_mod(yp, (p-1)//order, p)
        # find a generator of that group
        new_generator = power_mod(g, (p-1)//order, p)
        # Pollard Rho
        new_problem = GF(p)(new_problem)
        new_generator = GF(p)(new_generator)
        new_xp = discrete_log_rho(new_problem, new_generator, order)
        #
        print "found it!", new_xp
        xp = CRT(xp, new_xp, xp_mod, order)
        xp_mod *= order

    # Pohlig-Hellman in (q-1)/2
    yq = y % q
    xq = 0
    xq_mod = 1

    for order in q_factors[1:]: # removes 2
        print "attempting pollard rho in subgroup of order", order
        # reduce the problem
        new_problem = power_mod(yq, (q-1)//order, q)
        # find a generator of that grouq
        new_generator = power_mod(g, (q-1)//order, q)
        # Qollard Rho
        new_problem = GF(q)(new_problem)
        new_generator = GF(q)(new_generator)
        new_xq = discrete_log_rho(new_problem, new_generator, order)
        #
        print "found it!", new_xq
        xq = CRT(xq, new_xq, xq_mod, order)
        xq_mod *= order

    # CRT
    #xx = CRT(xp, xq, xp_mod, xq_mod)
    xx = CRT(xp, xq, xp_mod, xq_mod)

    print "x", x
    print "xx", xx
    print "yy", power_mod(g, xx, n)
    print "y", y
    x2 = CRT(xx, 1, xp_mod*xq_mod, 2)
    print "x2", 
    print "y2", power_mod(g, x2, n)

    # the important stuff
    print (xx - x) % ((p-1)*(q-1)//4) # this one is 0 for sure
    print (xx - x) % ((p-1)*(q-1)//2) # why is this one 0...?? should be 0 one out of 2 times

    pdb.set_trace()
        
################################################################# 
# Main menu
################################################################# 

menu = [
    "composite modulus with hidden subgroup",
    "composite modulus with B-smooth order"
        ]

def main():
    # display menu if not provided with an option
    if len(sys.argv) < 2:
        sys.stderr.write("\x1b[2J\x1b[H")
        print cc.HEADER + "# Choose a method from:" + cc.END
        for index, item in enumerate(menu, 1):
            print "%d. %s" % (index, menu[index - 1])
        print "(you can also pass that choice as an argument)"
        # prompt
        choice = int(raw_input(cc.OKGREEN + "# Enter a digit:\n" + cc.END))
        sys.stderr.write("\x1b[2J\x1b[H")
    else:
        choice = int(sys.argv[1])

    # run method
    if choice == 1:
        test_CM_HSS()
    elif choice == 2:
        test_CM_HSO()

if __name__ == "__main__":
    main()
else:
    test_CM_HSO()

