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

# Produce a generator for a group modulo a prime
def produce_generator(modulus, order, subgroups, g=2):
    # we want g s.t. g^{order/subgroup_order} != 1 for all subgroups
    is_generator = False
    while not is_generator:
        is_generator = True
        for subgroup in subgroups:
            if int(power_mod(g, order//subgroup, modulus)) == 1:
                g = randint(2, modulus - 1)
                is_generator = False
                break
    return g

# Produce good enough for a group modulo a prime
def produce_good_enough_generator(modulus, order, subgroups, g=2):
    # we want g s.t. g^{order/subgroup_order} != 1 for all subgroups
    is_generator = False
    while not is_generator:
        is_generator = True
        for subgroup in subgroups:
            if int(power_mod(g, subgroup, modulus)) == 1:
                g = randint(2, modulus - 1)
                is_generator = False
                break
    return g

# returns the order of g
def order_of_g(g, order, subgroups, modulus):
    for subgroup in subgroups:
        if power_mod(g, order//subgroup, modulus) == 1:
            reduced_subgroups = list(subgroups)
            reduced_subgroups.remove(subgroup)
            return order_of_g(g, order//subgroup, reduced_subgroups, modulus)
    return order, subgroups

# returns false if order of g is not a multiplication of some subgroups
def not_so_bad(g, order, subgroups, modulus):
    for subgroup in subgroups:
        if power_mod(g, subgroup, modulus) == 1:
            return False
        
    return True

# Produce a generator of a target subgroup for any kind of group
def produce_bad_generator(modulus, order_group, subgroups, target, g=2):
    while int(power_mod(g, target, modulus)) != 1 and not_so_bad(g, target, subgroups, modulus):
        g = randint(2, modulus - 1)
        g = power_mod(g, order_group//target, modulus)
    print "# Found a generator"
    order_g, subgroups_g = order_of_g(g, target, subgroups, modulus)
    print "generator_order:", order_g
    print "inbits:", len(bin(order_g)) - 2
    print "generator_subgr:", subgroups_g
    return g, order_g, subgroups_g
            
################################################################# 
# Methods
################################################################# 

# returns a prime and the small_factor
def smooth_prime(prime_size, small_factor_size):
    """ generate p s.t. p-1 = 2 * small_factor * large_factor
    with small_factor a prime of size small_factor_size
    """
    p = 0
    while not is_prime(p):
        # small factor
        small_factor = random_prime(1<<(small_factor_size+1),
                        lbound=1<<(small_factor_size-3))
        # large factor
        large_factor_size = prime_size - small_factor_size
        large_factor = random_prime(1<<(large_factor_size+1),
                        lbound=1<<(large_factor_size-3))
        # p
        p = 2 * small_factor * large_factor + 1
    #
    return p, small_factor

# returns generator, modulus, prime p and q, order of g mod p, order of g mod q
def method2(modulus_size, smooth_size):
    """ n = p * q, s.t. p-1 and q-1 are of the form
    2 * small_factor * large_factor
    the generator g mod p and mod q lies in the small subgroup
    the large factor is here to prevent against Pollard's p-1 factorization
    """
    # set the group
    start = time.time()
    prime_size = modulus_size//2
    p, p_order = smooth_prime(prime_size, smooth_size)
    q, q_order = smooth_prime(prime_size, smooth_size)
    n = p * q
    print "p and q generation took ", time.time() - start

    # find a generator mod p
    start = time.time()
    gp = 2
    while power_mod(gp, p_order, p) != 1:
        gp = power_mod(randint(3, p-1), (p-1)//p_order, p)
    print "gp generation took ", time.time() - start    

    # find a generator mod q
    start = time.time()
    gq = 2
    while power_mod(gq, q_order, q) != 1:
        gq = power_mod(randint(3, q-1), (q-1)//q_order, q)
    print "gq generation took ", time.time() - start    

    # CRT the generator mod n
    g = CRT(gp, gq, p, q)

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
    "hello"
        ]

def main():
    # display menu if not provided with an option
    # if len(sys.argv) < 2:
    #     sys.stderr.write("\x1b[2J\x1b[H")
    #     print cc.HEADER + "# Choose a method from:" + cc.END
    #     for index, item in enumerate(menu, 1):
    #         print "%d. %s" % (index, menu[index - 1])
    #     print "(you can also pass that choice as an argument)"
    #     # prompt
    #     choice = int(raw_input(cc.OKGREEN + "# Enter a digit:\n" + cc.END))
    #     sys.stderr.write("\x1b[2J\x1b[H")
    # else:
    #     choice = int(sys.argv[1])

    # run method
    choice = 1
    if choice == 1:
        g, n, p, q, p_order, q_order = method2(1024, 30)
        #g, n, p, q, p_order, q_order = method2(512, 40)

        return

if __name__ == "__main__":
    main()
