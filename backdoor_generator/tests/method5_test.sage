import subprocess, sys

# Sage's Pollard rho for discrete log
def discrete_log(public_key, generator, modulus, max=10^30):
    # trials
    g = 1
    secret = 0
    while True:
        if g == public_key:
            return secret
        g = Mod(g * generator, modulus)
        secret += 1
        # time out
        max -= 1
        if max < 0:
            break
    # Pollard rho
    I = IntegerModRing(modulus)
    return discrete_log_rho(I(public_key), I(generator))

# Home-made CRT (Sage has one also)
def CRT(hints, order_group): #hint
    print "attempting CRT"
    private_key = 0
    for hint in hints: # hint{subgroup, discrete log}
        blob = order_group//hint[0]
        temp = Mod(hint[1] * blob * inverse_mod(blob, hint[0]), order_group)
        private_key += temp

    #
    return private_key

def static_data():
    # using method 5. modulus = pq with p-1 partially smooth, g generates the smooth part
    modulus   = 548245664831225767141419273016768085406542237011230361276016565689134676706690352687292164960483315938369078458653578083713414699806019007950938450071366526478128083926885468277081095240967721758450836457978831900338219489281173073922491033103028452659577263035768839045341692238323705207003584738353752287
    bitlength = 1016
    factors   = 70117787024684775148549498461156077636013417080777716401285698096755274967604399160448249683124862517060625481858839332443325117518076089289436555852227  *  7818924242977283072267846038359392392135445300602775206633291186258799653434795866058576671165541249744847334956849807840154296207654821966574051508569781
    subgroups = [2, 1381355933, 2939315173, 3578534881, 7687338353, 3053137099, 3036275573, 2422598467, 4100054393]
    generator = 248671414939905491445356177266582647287080883455811181894034447475861652966403145776758964569878231179505323472699103703148234314379651037597490391955157078531721305383498477341554810068655918380976969935924960267826230785243150252343522698615522498569114360709449470012302180163337217804603940658308617574
    # be sure to test if you can do a DLOG modulo 4100054393
    return modulus, subgroups, generator

def main():
    # initialize test data
    if len(sys.argv) > 1 and sys.argv[1] == "dynamic":
        print "# Testing from a new generation"
        eval(subprocess.call("../backdoor_generator.sage", "5"))
    else:
        print "# Testing from hard-coded test"
        modulus, subgroups, generator = static_data()

    # create a public key
    secret = randint(2, modulus - 1)
    pubkey = power_mod(generator, secret, modulus)
    print "* pubkey:", pubkey

    # order of the group
    order = 1
    for i in subgroups:
        order *= i
    print "* order:", order

    # Pohlig-Hellman
    subgroup_DLOGs = []
    for subgroup in subgroups:
        # reduce to subgroup
        pubkey_reduced = power_mod(pubkey, order//subgroup, modulus)
        print "[ ] trying to find the discrete log of", pubkey_reduced, "in subgroup", subgroup
        if pubkey_reduced == 1:
            print "[~] already 1"
            continue
        if power_mod(pubkey_reduced, subgroup, modulus) != 1:
            print "[~] error"
            continue
        found = discrete_log(pubkey_reduced, generator, modulus)
        subgroup_DLOGs += [subgroup, found]
        print "[.] we found the discrete log: ", found

    # CRT
    secret_found = CRT(subgroup_DLOGs, order)

    # check
    if secret_found == secret:
        "[x] Good!"
    else:
        "[ ] Bad!"

if __name__ == "__main__":
    main()
