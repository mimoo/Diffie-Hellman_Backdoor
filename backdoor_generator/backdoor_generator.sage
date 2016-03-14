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

# prime p - 1 = 2 * p_1 * p_2 -> returns p, p_1
def partial_smooth_prime(prime_size, small_factor_size):
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
def method2(modulus_size, smooth_size):
    """ n = p * q, s.t. p-1 and q-1 are of the form
    2 * small_factor * large_factor
    the generator g mod p and mod q lies in the small subgroup
    the large factor is here to prevent against Pollard's p-1 factorization
    """
    # set the group
    #start = time.time()
    prime_size = modulus_size//2
    p, p_order = partial_smooth_prime(prime_size, smooth_size)
    q, q_order = partial_smooth_prime(prime_size, smooth_size)
    n = p * q
    #print "p and q generation took ", time.time() - start

    # find a generator
    #start = time.time()
    g = 2
    while power_mod(g, p_order*q_order, n) != 1 or power_mod(g, p_order, n) == 1 or power_mod(g, q_order, n) == 1:
        g = power_mod(randint(2, n-1), (p-1)*(q-1)//(p_order*q_order), n)
    #print "generator's generation took ", time.time() - start    

    # print
    print "modulus   =", n
    print "bitlength =", len(bin(n)) - 2
    print "factors   = [", p, ", ", q, "]"

    print "generator =", g
    print "orders    = [", p_order, ", ", q_order, "]"

    #
    return g, n, p, q, p_order, q_order

################################################################# 
# Main menu
################################################################# 

menu = [
    "composite modulus with partially smooth factors"
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
        g, n, p, q, p_order, q_order = method2(1024, 30)

if __name__ == "__main__":
    main()

