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

# multiply every element of a list together
def multiply_factors(factors):
    p = 1
    for factor in factors:
        p *= factor
    return p

################################################################# 
# Methods
################################################################# 

def method1(modulus_size, number_of_factors, smooth_size):
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

    # print
    print "modulus   =", modulus
    print "bitlength =", len(bin(modulus)) - 2
    print "factors   =", p_i
    print "subgroups =", subgroups_list
    print "# be sure to test if you can do a DLOG modulo", subgroups_list[1]

    #
    return modulus, subgroups_list, p_i

def method2(modulus_size, number_of_factors, smooth_size, B2_size):
    """
    # Description
    * This is the same method as method 1 above, except:
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

    # print
    print "modulus   =", modulus
    print "bitlength =", len(bin(modulus)) - 2
    print "factors   =", p_i
    print "subgroups =", subgroups_list
    print "# be sure to test if you can do a DLOG modulo", subgroups_list[-1]

    #
    return modulus, subgroups_list, p_i

def method3(modulus_size=1024, factors_size=256):
    """
    # Description
    * This is the best NOBUS I could achieve,
    * n = \prod p_i with each p_i the same large size and
    p_i - 1 = 2q_i with q_i prime (so p_i - 1 are not smooth)
    
    # How to use the backdoor
    * To use this backdoor you need to keep track of each p_i
    * Pohlig-Hellman will have to do the DLOG modulo each p_i - 1
    * This is a large modulus, for a 1024 bits dh modulus the dlogs will
    have to be done modulus 256 bits prime

    # NOBUS?
    * Since none of the p_i - 1 are smooth, Pollard's p-1 would not yield anything
    * Even ECM would be un-doable
    * On the other hand, you need to be able to do large dlogs
    """

    number_of_factors = modulus_size // factors_size
    return method1(modulus_size, number_of_factors, factors_size)

    
    
################################################################# 
# Main menu
################################################################# 

menu = ["modulus = pq with p-1 and q-1 smooth",
        "same as above but partially smooth",
        "method3",
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
        method1(1024, 2, 32)
    if choice == 2:
        print "# using method 2.", menu[1]
        method2(1024, 2, 32, 64)
    if choice == 3:
        print "# using method 3.", menu[2]
        method3()

if __name__ == "__main__":
    main()
