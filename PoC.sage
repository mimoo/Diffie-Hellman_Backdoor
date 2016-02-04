#
# HELPERS
#

# multiply every element of a list together
def multiply_factors(factors):
    p = 1
    for factor in factors:
        p *= factor
    return p

# string separator for nicer output
separator = "="*32

# merges two list of factors with their orders
def factor_list(factors):
    factors_real = {}
    for factor in factors:
        for factor2 in (factor - 1).factor():
            if factor2[0] in factors_real:
                factors_real[factor2[0]] += factor2[1]
            else:
                factors_real[factor2[0]] = factor2[1]
    return factors_real

#
# METHODS TO GENERATE THE MODULUS
# 

# Method 1: generate a new prime p of size 1024 bits s.t. p=p_1*...*p_n with each p_i - 1 smooth
# **code not finished**
def gen1(number, size_total):
    number_of_prime = 2
    p = 1 << (1024//number_of_prime)
    factors = []
    for ii in range(2):
        while not is_prime(p):
            p +=1
        factors.append(p)
        p += 1
    return factors

# Method 2: try generating a bunch of small primes, which multiplied together + 1 is a prime
def gen2(number, size_total):
    result = []
    for ii in range(number):
        prime_size = size_total // number
        number_small_primes = prime_size // 16
        prime = 0
        while not is_prime(prime):
            primes_list = [2]
            for jj in range(number_small_primes):
                primes_list.append(random_prime(1<<20, lbound=1<<15))
            prime = multiply_factors(primes_list) + 1
        result.append(prime)
    return result

# Method 3:
# p prime s.t. p = 2p_1p_2 + 1 with p_1 small, p_2 big
# so the order will be p - 1 and we have p_1|p - 1
# choose a generator g of that subgroup of order p_1
# >> this is taking way too much time :/ <<
def gen3(size_total):
    # pick 2 primes, one small one big
    size_small = 32
    size_big = size_total - size_small - 2
    prime = 0
    while not is_prime(prime):
        p_1=random_prime(1<<(size_small+2), lbound=1<<(size_small-1))
        p_2=random_prime(1<<(size_big+2), lbound=1<<(size_big-1))
        prime = p_1*p_2*2 + 1

    return prime

#
# GENERATING THE NON-PRIME MODULUS
#

# so here we use it as such
# p = p_1 * p_2 s.t. p_1 - 1 and p_2 -1 are smooth

print separator
print "We are generating the non-prime modulus as such:"
print "p = p_1 * p_2"
print "such that p_1 - 1 and p_2 -1 are both smooth"
factors = gen2(2, 1024)
print separator
p_1 = factors[0]
p_2 = factors[1]
print "p_1 =", p_1
print "p_1 - 1 =", (p_1-1).factor()
print "and"
print "p_2 =", p_2
print "p_2 - 1 =", (p_2-1).factor()
print separator
p = multiply_factors(factors)
print "We now have our non-prime modulus p of size", len(bin(p)) - 2
print p
print separator
print "The order of the group created should be (p_1-1)*(p_2-1)"
print "which is smooth..."
order_group = (p_1-1)*(p_2-1)
print order_group
print separator
print "Let's verify that 2^order = 1 mod p"
verif = power_mod(2, order_group, p)
if verif != 1:
    print "Unfortunately not...", verif
    sys.exit(1)
print "All good:", verif
print separator
raw_input("Press a key to continue...")

#
# ATTACK
#

# this server takes a public key and add his on it
real_private_key = 0xFFFFFFFFFFF2140214
def server(public_key, modulus):
    return power_mod(public_key, real_private_key, modulus)

# a Pohlig Hellman attack is possible, but an active small subgroup attack is easier to mount

def client(server, modulus, factors):
    # merge all the factors in one list
    factors = factor_list(factors)

    # iterate all the subgroups
    group = Zmod(modulus)
    hints = [] # the list of [generator, subgroup order]

    for factor in factors:
        # find the subgroup order
        if factors[factor] == 1:
            order_subgroup = factor
        else:
            order_subgroup = factor^(factors[factor])

        # create generator
        g = 0
        while power_mod(g, order_subgroup, modulus) != 1:
            g = group.random_element()
            exp = order_group/order_subgroup
            g = power_mod(ZZ(g), ZZ(exp), modulus)

        # send generator to server
        print separator
        print "testing subgroup of order", order_subgroup
        print "with generator", g

        resp = server(g, modulus)

        # get discrete log
        g = group(g)
        resp = group(resp)
        disc = dumb_discrete_log(resp, g, modulus)
        print "Discrete log found!"
        print disc
        hints.append([disc, order_subgroup])

        # verify the discrete log
        if power_mod(g, disc, modulus) != resp:
            print "The discrete log found is incorrect."
            sys.exit(1)

    # do CRT
    print separator
    print "We know have enough to apply CRT"
    private_key = CRT(hints, modulus, factors, order_group)
    return private_key

# Chinese Remainder Theorem
def CRT(hints, modulus, factors, order_group):
    print "attempting CRT"
    private_key = 0
    for hint in hints:
        blob = order_group/hint[1]
        temp = Mod(hint[0] * blob * inverse_mod(ZZ(blob), hint[1]), order_group)
        private_key += temp

    #
    return private_key

# We are not using Pollard Rho at the moment
def dumb_discrete_log(public_key, generator, modulus):
    g = 1
    x = 0
    while True:
        if g == public_key:
            return x
        g *= generator
        x += 1
        
print separator
print "We are doing a small subgroup attack to test our backdoor"
print "We will send to our fake server a generator of each subgroup as public key"
print "The server will reply with the generator raised to his private key"
print "We then need to compute the discrete log with Pollard's rho algorithm on each subgroup"
print separator
raw_input("Press a key to continue...")
print separator

private_key = client(server, p, factors)
print separator
print "We found something!"
print "private key found:", private_key
print separator
if private_key == real_private_key:
    print "It is indeed the server's private key!"
else:
    print "Nope, not the right key, the attack failed."
