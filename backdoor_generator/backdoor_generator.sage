#################################################################
# DH Backdoor generator
#################################################################
# This tool generates Diffie-Hellman parameters
# that would allow for a backdoor.
#
# several method are availables
################################################################# 

import sys, pdb, time

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
            
################################################################# 
# Methods
################################################################# 

# method 1 helper
# prime p - 1 = 2 * p_1 * p_2 -> returns p, p_1
def subgroup_prime(prime_size, small_factor_size):
    """ generate a prime `p` s.t. `p - 1 = 2 * small_factor * large_factor`
    with `small_factor` a prime of size `small_factor_size`
    and `p` of size `prime_size`
    """
    p = 0

    # fixed large factor
    large_factor_size = prime_size - small_factor_size
    large_factor = random_prime(1<<(large_factor_size+1),
                                lbound=1<<(large_factor_size-3))

    while not is_prime(p):
        # find a small factor
        small_factor = random_prime(1<<(small_factor_size+1),
                                    lbound=1<<(small_factor_size-3))

        # p
        p = 2 * small_factor * large_factor + 1
    #
    return p, small_factor

# n = pq s.t. p,q "partially-smooth"-primes and g generates the smooth part modulo p and q
def method1(modulus_size, subgroup_size):
    """ n = p * q, s.t. p-1 and q-1 are of the form
    2 * small_factor * large_factor
    the generator g mod p and mod q lies in the small subgroup
    the large factor is here to prevent against Pollard's p-1 factorization
    """
    # set the group
    prime_size = modulus_size//2
    p, p_order = subgroup_prime(prime_size, subgroup_size)
    q, q_order = subgroup_prime(prime_size, subgroup_size)
    n = p * q

    # find a generator
    g = 2
    while power_mod(g, p_order*q_order, n) != 1 or power_mod(g, p_order, n) == 1 or power_mod(g, q_order, n) == 1:
        g = power_mod(randint(2, n-1), (p-1)*(q-1)//(p_order*q_order), n)

    # print
    print "modulus          =", n
    print "bitlength        =", len(bin(n)) - 2
    print "p, q             =", p, ", ", q
    print "generator        =", g
    print "order_p, order_q =", p_order, ", ", q_order

    #
    return g, n, p, q, p_order, q_order

# method 2 helper

def B_smooth(total_size, small_factors_size, big_factor_size):
    """ Just picking at random should be enough, there is a very small probability
    we will pick the same factors twice
    """
    smooth_prime = 2
    factors = [2]
    # large B-sized prime
    large_prime = random_prime(1<<(big_factor_size + 1), lbound=1<<(big_factor_size-3))
    factors.append(large_prime)
    smooth_prime *= large_prime
    # all the other small primes
    number_small_factors = (total_size - big_factor_size) // small_factors_size
    i = 0
    for i in range(number_small_factors - 1):
        small_prime = random_prime(1<<(small_factors_size + 1), lbound=1<<(small_factors_size-3))
        factors.append(small_prime)
        smooth_prime *= small_prime
    # we try to find the last factor so that the total number is a prime
    # (it should be faster than starting from scratch every time)
    prime_test = 0
    while not is_prime(prime_test):    
        last_prime = random_prime(1<<(small_factors_size + 1), lbound=1<<(small_factors_size-3))
        prime_test = smooth_prime * last_prime + 1

    factors.append(last_prime)
    smooth_prime *= last_prime

    return smooth_prime, factors

# n = pq s.t. p-1,q-1 B-smooth with B large enough
def method2(modulus_size, small_factors_size, big_factor_size):
    """ n = p * q, s.t. p-1 and q-1 are B-smooth (for Pohlig-Hellman)
    with B large enough to counter Pollard's p-1 factorization algorithm
    latest records of Pollard's p-1 used B = 10^15 (~50bits)
    p-1, q-1 will have one factor of size `upper_smooth_size` and all others of size `smooth_size`
    """
    # p - 1 = B_prime * small_prime_1 * small_prime2 * ...
    p, p_factors = B_smooth(modulus_size//2, small_factors_size, big_factor_size)
    q, q_factors = B_smooth(modulus_size//2, small_factors_size, big_factor_size)
    factors = p_factors + q_factors

    # modulus
    modulus = p * q

    # the order of the generator we ideally want
    order = 1
    for factor in factors[1:]: # we get rid of the first 2 (lcm)
        order *= factor

    # find a generator
    g = 2
    is_generator = False
    while not is_generator:
        is_generator = True
        for factor in factors[1:]:
            # we want all of the factors to be a part of the order
            if power_mod(g, order//factor, modulus) == 1: 
                g = randint(2, modulus - 1)
                is_generator = False
                break

    # print
    print "modulus          =", modulus
    print "bitlength        =", len(bin(modulus)) - 2
    print "p, q             =", p, ", ", q
    print "factors          =", factors
    print "generator        =", g

    # ->
    return g, modulus, p, q, factors


################################################################# 
# Main menu
################################################################# 

menu = [
    "composite modulus with partially smooth order",
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
        g, n, p, q, p_order, q_order = method1(1024, 30)
    elif choice == 2:
        g, n, p, q, factors = method2(1024, 20, 60)

if __name__ == "__main__":
    main()
else:
    method2(1024, 20, 60)

