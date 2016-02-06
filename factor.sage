import sys

# sage verbose
set_verbose(2)

# will take sqrt(n) divisions in the worst case
def trial_division(number):
    factors = []
    # use different techniques to get primes, dunno which is faster
    index = 0
    for prime in Primes():
        if prime > number:
            break
        while Mod(number, prime) == 0:
            print prime, "divides the order"
            factors.append(prime)
            number = number // prime
        if index == 10000:
            print "tested up to prime", prime, "so far"
            index = 0
        else:
            index += 1

    return factors

# read stdin
number = int(sys.stdin.read())

# different factorization methods
if sys.argv[1] == "dumb":
    trial_division(number)
elif sys.argv[1] == "sage":
    print factor(number, verbose=8)
elif sys.argv[1] == "ecm":
    from sage.libs.libecm import ecmfactor
    print ecmfactor(number, 0.00, verbose=True)
