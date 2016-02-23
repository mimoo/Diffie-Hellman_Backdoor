#################################################################
# DH Backdoor generator
#################################################################
# This tool generates Diffie-Hellman parameters
# that would allow for a backdoor.
#
# several method are availables
################################################################# 

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
    This method creates a modulus n = p_1 * ... * p_{number_of_factors}
    with each p_i - 1 smooth, that is, each p_i - 1 = q_1 * ... * q_{something} 
    `something` is calculated according to `smooth_size`:
    each q_i is of size ~ `smooth_size`

    # How to use the backdoor
    To use this backdoor you need to keep track of each q_i

    Pohlig-Hellman will have to do the DLOG modulo every q_i
    To verify that the `smooth_size` is low enough: try to compute a DLOG on a q_i

    # NOBUS?
    Since both p-1 and q-1 are smooth, 
    it's highly possible that Pollard's p-1 factorization algorithm could
    relatively easily retrieve p and q
    """

    # generation of the X primes p_i s.t. p_i - 1 smooth
    p_i = []
    subgroups_list = []
    for i in range(number_of_factors):
        prime_size = modulus_size // number_of_factors
        number_small_primes = prime_size // smooth_size
        upper_bound = smooth_size + 5 # q_i will be upperbounded by that value
        # let's compute a p_i
        prime_test = 0
        while not is_prime(prime_test):
            primes_list = [2] # number is even
            for j in range(number_small_primes):
                primes_list.append(random_prime(1<<upper_bound, lbound=1<<smooth_size))
            # prime_test - 1 = p_i - 1 = \prod primes_list = \prod q_i
            prime_test = 1
            for prime in primes_list:
                prime_test *= prime
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
        print cc.FAIL + "Method 1 crashed" + cc.END
        sys.exit(1)

    # print
    print cc.OKBLUE + "modulus   =" + cc.END, modulus
    print cc.OKBLUE + "bitlength =" + cc.END, len(bin(modulus)) - 2
    print cc.OKBLUE + "modulus   =" + cc.END, p_i
    print cc.OKBLUE + "subgroups =" + cc.END, subgroups_list
    print cc.WARNING + "be sure to test if you can do a DLOG modulo", subgroups_list[1], cc.END

    #
    return modulus, subgroups_list, p_i


################################################################# 
# Main menu
################################################################# 

def main():
    # display menu
    sys.stderr.write("\x1b[2J\x1b[H")
    print cc.HEADER + "# Choose a method from:" + cc.END
    print "1. modulus = pq with p-1 and q-1 smooth"
    print "2. same as above but partially smooth"

    # prompt
    choice = int(raw_input(cc.OKGREEN + "# Enter a digit:\n" + cc.END))
    sys.stderr.write("\x1b[2J\x1b[H")

    # run method
    if choice == 1:
        method1(1024, 2, 32)
    if choice == 2:
        method1(1024, 2, 32)

if __name__ == "__main__":
    main()
