########################################################################
# Discrete Logarithm in prime fields
########################################################################
# This file is a test for computing times in prime field
#

import time

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

# Pollard rho
def Pollard_rho(public_key, generator, modulus, order):
    I = GF(modulus)
    return discrete_log_rho(I(public_key), I(generator), order)

########################################################################
# Helper functions
########################################################################

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
    secret = randint(2, q)
    public_key = power_mod(generator, secret, modulus)
    return secret, public_key, modulus, q

# run the test
def test(algo, secret, public_key, modulus, order, generator=2):
    # start timer
    start_time = time.time()
    # algo?
    if algo == "trials":
        secret_found = dumb_discrete_log(public_key, generator, modulus)
    elif algo == "rho":
        secret_found = Pollard_rho(public_key, generator, modulus, order)

    # end timer
    delta = int(time.time() - start_time)

    # display
    if secret == secret_found:
        print "|", algo, "|", delta, "|"
    else:
        print "secret", secret
        print "found", secret_found
        print "-pubkey", public_key
        print "-modulus", modulus
        print "^secret", power_mod(generator, secret, modulus)
        print "^found", power_mod(generator, secret_found, modulus)

########################################################################
# Tests
########################################################################

def main():
    print "# Time to compute discrete logs"


    print "10 bits"
    secret, public_key, modulus, order = setup(10)
    test("trials", secret, public_key, modulus) # <1s
    #test("rho", secret, public_key, modulus, order) 

    print "20 bits"
    secret, public_key, modulus, order = setup(20)
    test("trials", secret, public_key, modulus) # 1s

    print "30 bits"
    secret, public_key, modulus, order = setup(30)
    test("trials", secret, public_key, modulus) # 24m

    print "40 bits"
    secret, public_key, modulus, order = setup(40)
    #test("trials", secret, public_key, modulus) # >1hour

if __name__ == "__main__":
    main()
