########################################################################
# Discrete Logarithm in prime fields
########################################################################
# This file is a test for computing times in prime field
#

import time, sys, pdb

########################################################################
# Discrete log functions
########################################################################

# Simples trials
def dumb_discrete_log(public_key, generator, modulus):
    g = 1
    x = 0
    while True:
        if g == public_key:
            return x
        g = Mod(g * generator, modulus)
        x += 1


# https://eprint.iacr.org/2010/617.pdf
def Pollard_rho_four_kangaroo(public_key, order, generator, modulus, a=0, b=1):
    """ This is the latest improvement on Pollard Rho Lambda's algorithm
    """
    return 0

# http://math.boisestate.edu/~liljanab/Crypto2Spring10/PollardKangaroo.pdf
def Pollard_rho_lambda_improved(public_key, order, generator, modulus):

    return 0

# Pollard Rho Lambda or Pollard Kangaroo for serial computers
# http://math.boisestate.edu/~liljanab/Crypto2Spring10/PollardKangaroo.pdf
def Pollard_kangaroo_serial(public_key, order, generator, modulus, b=0):
    """ This is the Pollard rho lambda or Pollard Kangaroo algorithm,
    this version is for serial computers (no parallelization)
    """
    # initialization
    alpha = generator # to keep the same variables as in the book
    beta = public_key

    # random walk
    def f(x):
        return power_mod(alpha, int(x), modulus)

    # tame kangaroo
    a = 0
    if b==0:
        b = order//2

    x = power_mod(alpha, b, modulus)
    x = Mod(x, modulus)

    dx = 0
    i = 0

    # tame kangaroo jumping
    while i < b:
        fx = f(x)
        x = x * power_mod(alpha, fx, modulus)
        dx += fx
        i += 1

    # wild kangaroo
    y = Mod(beta, modulus)

    dy = 0
    i = 0

    # wild kangaroo jumping
    while i < b:
        fy = f(y)
        y = y * power_mod(alpha, fy, modulus)
        dy += fy

        # trap
        if x == y:
            return (b + dx - dy) % order
        if dy > b - a + dx:
            break
        i += 1

    # failure
    b = randint(2, order//2)
    return Pollard_kangaroo_serial(public_key, order, generator, modulus, b)
        
# Handbook of applied crypto Pollard Rho
def Pollard_rho(public_key, order, generator, modulus, a=0, b=1):
    """ This is the implementation of the algorithm introduced in
    the Handbook of Applied Cryptography chapter 3.6.3
    """
    # initialization
    alpha = generator # to keep the same variables as in the book
    beta = public_key

    if a != 0 or b != 0:
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
        if Mod(x, 3) == 0: # x in S_1 (chosen from example)
            x = beta * x
            b = b + 1

        elif Mod(x, 3) == 1: # x in S_2
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

        
# Pollard rho
def Pollard_rho_tag_tracing(public_key, order, generator, modulus):
    # defining our r-adding walk iterating function
    def r_adding_walk(index, element):
        # determines the index
        print index
        # get M_s
        M_s = Mod(power_mod(generator, m_s, modulus) * power_mod(public_key, n_s, modulus), modulus)
        # produces        
        return element * M_s
    
########################################################################
# Helper functions
########################################################################

# print a nice table
def print_table(data, headers=False):

    if headers:
        sys.stdout.write("\n+" + "-" * (len(data) * 20 + len(data)) + "\n")

    sys.stdout.write("|")
    for item in data:
        item = item.center(20)
        sys.stdout.write(item + "|")

    sys.stdout.write("\n+")
    for item in data:
        sys.stdout.write("-" * 20 + "+")
    sys.stdout.write("\n")

# safe prime for worst-cases tests
def safe_prime(bitlevel):
    p = 0
    while not is_prime(p):
        q = random_prime(1<<bitlevel, lbound=1<<bitlevel - 1)
        p = 2*q + 1
    return p, q

# setup the test
def setup(bitlevel, generator=2):
    modulus, q = safe_prime(bitlevel)
    secret = randint(2, q-1)
    public_key = power_mod(generator, secret, modulus)
    return secret, public_key, modulus, q

# run the test
def test(bitsize, algo):
    # init
    secret, public_key, modulus, order = setup(bitsize)
    generator = 2

    # start timer
    start_time = time.time()
    secret_found = 0

    # algo?
    if algo == "trials":
        secret_found = dumb_discrete_log(public_key, generator, modulus)
    elif algo == "rho":
        secret_found = Pollard_rho_tag_tracing(public_key, generator, modulus, order)
    elif algo == "old_rho":
        secret_found = Pollard_rho(public_key, order, generator, modulus)
    elif algo == "rho_lambda":
        secret_found = Pollard_kangaroo_serial(public_key, order, generator, modulus)

    # end timer
    delta = int(time.time() - start_time)

    # display
    if secret == secret_found:
        print_table([str(bitsize) + "bits", algo, str(delta) + "s"])

    else:
        print "SECRET NOT FOUND, DEBUG INFO:"
        print "* secret", secret
        print "* secret_found", secret_found
        print "* pubkey", public_key
        print "* modulus", modulus
        print "* g^secret", power_mod(generator, secret, modulus)
        print "* g^found", power_mod(generator, secret_found, modulus)

########################################################################
# Tests
########################################################################

def main():
    print "# Time to compute discrete logs"

    print_table(["modulus bitsize", "DLOG algorithm", "time"], headers=True)


    test(10, "trials") # <1s
    test(10, "old_rho") # <1s
    test(10, "rho_lambda") # <0s

    test(20, "trials") # 1s
    test(20, "old_rho") # <1s
    test(20, "rho_lambda") # 6s

    test(23, "trials") # 4s, 14s
    test(23, "old_rho") # <1s
    test(23, "rho_lambda") # 64s

    #test(30, "trials") # 24m
    test(30, "old_rho") # 1s, 2s, 1s, 0s
    test(30, "rho_lambda") # 

    #test(40, "trials") # unknown (>1hour)
    test(40, "old_rho") # 12s, 59s, 9s, 19s
    test(40, "rho_lambda") #

    # test(50, "old_rho") # unknown >10min


if __name__ == "__main__":
    main()
