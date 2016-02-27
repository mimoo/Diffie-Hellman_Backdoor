#################################################################
# DH Backdoor generator
#################################################################
# This tool generates Diffie-Hellman parameters
# that would allow for a backdoor.
#
# several method are availables
################################################################# 

import sys

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

# Produce a generator of a target subgroup for any kind of group
def produce_bad_generator(modulus, order_group, target, g=2):
    while int(power_mod(g, target, modulus)) != 1:
        g = randint(2, modulus - 1)
        g = power_mod(g, order_group//target, modulus)
    return g
            
################################################################# 
# Methods
################################################################# 

def method1(modulus_size, factors_size):
    """
    # Description
    * This method creates a prime modulus p
    * p-1 factors are small enough for DLOG
    * p-1 factors are big enough to avoid factorization

    # How to use the backdoor
    * You should be able to do a DLOG modulo a factors_size prime

    # NOBUS?
    * Nobody should be able to find a factor of size factors_size
    """
    print "this is not a good idea"
    return True

def method2(modulus_size, number_of_factors, smooth_size):
    """
    # Description
    * This method creates a modulus n = p_1 * ... * p_{number_of_factors}
    with each p_i - 1 smooth, that is, each p_i - 1 = q_1 * ... * q_{something} 
    * `something` is calculated according to `smooth_size`:
    each q_i is of size ~ `smooth_size`

    # How to use the backdoor
    * To use this backdoor you need to keep track of each q_i
    * Pohlig-Hellman will have to do the DLOG modulo every q_i
    * To verify that the `smooth_size` is low enough: try to compute a DLOG on a q_i

    # NOBUS?
    * Since each p_i-1 are smooth, i's highly possible that
    Pollard's p-1 factorization algorithm could factor the modulus
    """

    # checks
    assert(number_of_factors > 1)
    assert(smooth_size > 0)
    
    # generation of the X primes p_i s.t. p_i - 1 smooth
    p_i = []
    subgroups_list = []
    for i in range(number_of_factors):
        prime_size = modulus_size // number_of_factors
        number_small_primes = prime_size // smooth_size
        # let's compute a p_i
        prime_test = 0
        while not is_prime(prime_test):
            primes_list = [2] # number is even
            prime_test = 2
            for j in range(number_small_primes):
                prime = random_prime(1<<(smooth_size + 1), lbound=1<<(smooth_size-3))
                primes_list.append(prime)
                prime_test *= prime
            # prime_test - 1 = p_i - 1 = \prod primes_list = \prod q_i
            prime_test += 1
        # we found a p_i
        p_i.append(prime_test)
        subgroups_list += primes_list

    # compute the modulus
    modulus = 1
    for p in p_i:
        modulus *= p

    # verify the order of the group
    order_group = 1
    for p in p_i:
        order_group *= p - 1
    if power_mod(2, order_group, modulus) != 1:
        print "Method 1 crashed"
        sys.exit(1)

    # find a generator
    g = produce_good_enough_generator(modulus, order_group, subgroups_list)

    # print
    print "modulus   =", modulus
    print "bitlength =", len(bin(modulus)) - 2
    print "factors   =", p_i
    print "generator =", g
    print "subgroups =", subgroups_list
    print "# be sure to test if you can do a DLOG modulo", subgroups_list[1]

    #
    return modulus, subgroups_list, p_i, g

def method3(modulus_size, number_of_factors, smooth_size, B2_size):
    """
    # Description
    * This is the same method as method 2 above, except:
    one q_i (we'll call it q_B2) of each p_i-1 is big.
    * This makes the p_i-1 "partially" smooth

    # How to use the backdoor
    * To use this backdoor you need to keep track of each q_i
    * Pohlig-Hellman will have to do the DLOG modulo every q_i
    * To verify that the `B2_size` is low enough: try to compute a DLOG on a q_B2

    # NOBUS?
    * Since both p-1 and q-1 have a large factor, 
    * Pollard's p-1 would need a B2 bound too large to work efficiently.
    * ECM could still work if the large factor is not large enough
    """

    # B2 should be > smooth_size
    assert(B2_size > smooth_size)
    
    # generation of the X primes p_i s.t. p_i - 1 smooth
    p_i = []
    subgroups_list = []
    for i in range(number_of_factors):
        prime_size = modulus_size // number_of_factors
        number_small_primes = (prime_size // smooth_size) - (B2_size // smooth_size)
        # let's compute a p_i
        prime_test = 0
        while not is_prime(prime_test):
            primes_list = [2] # number is even
            prime_test = 2
            for j in range(number_small_primes):
                prime = random_prime(1<<(smooth_size+1), lbound=1<<(smooth_size-3))
                primes_list.append(prime)
                prime_test *= prime
            # now the time for q_B2
            prime = random_prime(1<<(B2_size+1), lbound=1<<(B2_size-3))
            primes_list.append(prime)
            prime_test *= prime
            # prime_test - 1 = p_i - 1 = \prod primes_list = \prod q_i
            prime_test += 1
        # we found a p_i
        p_i.append(prime_test)
        subgroups_list += primes_list

    # compute the modulus
    modulus = 1
    for p in p_i:
        modulus *= p

    # verify the order of the group
    order_group = 1
    for p in p_i:
        order_group *= p - 1
    if power_mod(2, order_group, modulus) != 1:
        print "Method 1 crashed"
        sys.exit(1)

    # find a generator
    g = produce_good_enough_generator(modulus, order_group, subgroups_list)

    # print
    print "modulus   =", modulus
    print "bitlength =", len(bin(modulus)) - 2
    print "factors   =", p_i
    print "subgroups =", subgroups_list
    print "generator =", g
    print "# be sure to test if you can do a DLOG modulo", subgroups_list[-1]

    #
    return modulus, subgroups_list, p_i, g

def method4(modulus_size=1024, factors_size=256):
    """
    # Description
    * n = \prod p_i with each p_i the same large size and
    p_i - 1 = 2q_i with q_i prime (so p_i - 1 are not smooth)
    
    # How to use the backdoor
    * To use this backdoor you need to keep track of each p_i
    * Pohlig-Hellman will have to do the DLOG modulo each p_i - 1
    * This is a large modulus, for a 1024 bits dh modulus the dlogs will
    have to be done modulus 256 bits prime

    # NOBUS?
    * Since none of the p_i - 1 are smooth, Pollard's p-1 would not yield anything
    * But 256bits factors are "easy" to find
    * You also have "not easy" DLOG to do
    """

    number_of_factors = modulus_size // factors_size
    return method2(modulus_size, number_of_factors, factors_size)

def method5(modulus_size, subgroups_order, large_factor_size):
    """
    # Description
    * n = pq and p-1 has large factors except for a small one that will
    be our generator's subgroup
    """
    # generation of the 2 primes p and q s.t. p-1 has one small factor
    prime_size = modulus_size // 2

    # q should be have few factors (not smooth) if we pick it randomly
    q = random_prime(1<<(prime_size+1), lbound=1<<(prime_size-3))

    # p
    number_small_subgroups = (prime_size - large_factor_size) // subgroups_order
    p = 0
    while not is_prime(p):
        subgroups_list = [2]
        generator_subgroup = 2
        # generate the `number_small_subgroups` small subgroups
        for j in range(number_small_subgroups):
            prime = random_prime(1<<(subgroups_order+1), lbound=1<<(subgroups_order-3))
            subgroups_list.append(prime)
            generator_subgroup *= prime
        # the large rest
        large_subgroup = random_prime(1<<(large_factor_size+1), lbound=1<<(large_factor_size-3))
        # p
        p = generator_subgroup * large_subgroup + 1

    # compute the modulus
    modulus = p * q

    # verify the order of the group
    order_group = (p-1) * (q-1)
    if power_mod(2, order_group, modulus) != 1:
        print "Method 1 crashed"
        sys.exit(1)

    # find a generator of the small subgroup
    g = produce_bad_generator(modulus, order_group, generator_subgroup)

    # print
    print "modulus   =", modulus
    print "bitlength =", len(bin(modulus)) - 2
    print "factors   =", p, " * ", q
    print "subgroups =", subgroups_list
    print "generator =", g
    print "# be sure to test if you can do a DLOG modulo", subgroups_list[-1]

    #
    return modulus, subgroups_list, generator_subgroup, g

def method6():
    return True
    
################################################################# 
# Main menu
################################################################# 

menu = ["modulus p is prime, p-1 have 'small' factors",
        "modulus = pq with p-1 and q-1 smooth",
        "same as above but partially smooth",
        "modulus = p_1*p_2*p_3*p_4 with no smooth p_i-1",
        "modulus = pq with p-1 partially smooth, g generates the smooth part"
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
        print "# using method 1.", menu[0]
        """
        compute a prime modulus p where p-1 has small factors
        small enough to do the dlog, but large enough to avoid factorization
        (this is not really possible)
        """
        method1(1024, 256)

    if choice == 2:
        print "# using method 2.", menu[1]
        """
        We use it to compute n = pq with p-1 and q-1 32bits-smooth
        dlog in 32 bits is relatively easy (?)
        factoring n is easy with Pollard's p - 1
        """
        method2(1024, 2, 32)
    if choice == 3:
        print "# using method 3.", menu[2]
        """
        As above, we generate n = pq with p-1 and q-1 32bits-smooth
        except! for one factor that is ~64bits
        dlog should be possible in 64 bits
        factoring n with Pollard's p-1 will have to catch that 64bits with B2
        """
        method3(1024, 2, 32, 64)
    if choice == 4:
        print "# using method 4.", menu[3]
        """
        We compute n = p1*p2*p3*p4 with each p_i 256bits and
        p_i - 1 = 2q_i with q_i prime (so p_i - 1 are not smooth)
        This is not a very good way, because easily factorable
        """
        method4(1024, 256)
    if choice == 5:
        print "# using method 5.", menu[4]
        """
        We compute n = pq with p and q prime s.t.
        p-1 has a few 32bits factors and a large 250bits factor
        We use a generator of the entire small subgroups
        """
        method5(1024, 32, 250)


if __name__ == "__main__":
    main()
