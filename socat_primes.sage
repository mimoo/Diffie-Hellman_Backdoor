# the old "fake prime" dh params

dh1024_p = 0xCC17F2DC96DF59A446C53E0EB826550CE388C1CEA7BCB3BF1694D8A945A2CEA95B22255F9259941C22BFCBC8C857CBBFBC0EE840F98703BF609B08C68E99C605FC00D66D90A8F5F8D38D43C88F7ABDBB28AC04694A0B867337F06D4F04F6F5AFBFAB8ECE75534D7F7D17780E12464AAF9599EFBCA6C54177437AB9EC8E073C6D
dh1024_g = 2

# the new dh params

dh2048_p = 0x00dc216456bd9cb2acbec998ef953e26fab557bcd9e675c043a21c7a85df34ab57a8f6bcf6847d056904834cd556d385090a08ffb537a1a38a370446d2933196f4e40d9fbd3e7f9e4daf08e2e8039473c4dc0687bb6dae662d181fd847065ccf8ab50051579bea1ed8db8e3c1fd32fba1f5f3d15c13b2c8242c88c87795b38863aebfd81a9baf7265b93c53e03304b005cb6233eea94c3b471c76e643bf89265ad606cd47ba9672604a80ab206ebe07d90ddddf5cfb4117cabc1a384be2777c7de20576647a735fe0d6a1c52b858bf2633815eb7a9c0ee581174861908891c370d524770758ba88b3011713662f07341ee349d0a2b674e6aa3e299921bf5327363
dh2048_g = 2

# is_prime(dh2048_p) -> True

order = dh2048_p - 1

factors = [2]
print "2 divides the order"

# let's try to factorize the order by trial divisions
def find_factors(number):
    factors = []
    # use different techniques to get primes, dunno which is faster
    index = 0
    for prime in Primes():
        if Mod(number, prime) == 0:
            print prime, "divides the order"
            factors.append(prime)
        if index == 10000:
            print "tested up to prime", prime, "so far"
            index = 0
        else:
            index += 1

    return factors

#factors += find_factors(order / 2)

