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

print "INPUT NUMBER:", number

# different factorization methods
if sys.argv[1] == "dumb":
    print "ALGORITHM: in-house Trial Division"
    trial_division(number)
elif sys.argv[1] == "sage":
    print "ALGORITHM: Sage factoring algorithm"
    print factor(number, verbose=8)
elif sys.argv[1] == "ecm":
    print "ALGORITHM: INRIA's ECM"
    from sage.libs.libecm import ecmfactor
    print ecmfactor(number, 1000000000, verbose=True)
