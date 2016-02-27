import base64, pdb, sys

#################################################################################
# Helper functions
#################################################################################

# 256 (int) => [1, 0] (byte array)
def int_to_bytearray(number):
  hexstring = "%X" % number
  if len(hexstring) % 2 != 0:
    hexstring = "0" + hexstring
  byte_array = []
  for ii in range(len(hexstring)//2):
    byte_array.append(int(hexstring[ii*2:ii*2+2], 16))
  return byte_array

# [10, 11, 2] -> ["0A", "0B", "02"]
def intarray_hexarray(intarray):
  hexarray = []
  for ii in intarray:
    hexarray.append("%02X" % ii)
  return hexarray
    
#################################################################################
# To asn1 (useful for openssl s_server -dhparam file_generated_by_this
#################################################################################

def to_asn1(modulus, generator):
  # modulus -> asn1
  modulus = int_to_bytearray(modulus)
  modulus_length = len(modulus)
  modulus_length = int_to_bytearray(modulus_length)
  if len(modulus_length) > 1:
    modulus_length = [0x82] + modulus_length
  asn1 = [0x02] + modulus_length + modulus
  
  # generator -> asn1
  generator = int_to_bytearray(generator)
  generator_length = len(generator)
  generator_length = int_to_bytearray(generator_length)
  if len(generator_length) > 1:
    generator_length = [0x82] + generator_length

  asn1 = asn1 + [0x02] + generator_length + generator
  # asn1 header
  asn1_length = int_to_bytearray(len(asn1))
  if len(asn1_length) > 1:
    asn1_length = [0x82] + asn1_length  
  asn1 = [0x30] + asn1_length + asn1
  # write to file
  asn1 = bytearray(asn1)

  asn1b64 = base64.b64encode(asn1)
  dhparam = "-----BEGIN DH PARAMETERS-----\n"
  for ii in range(len(asn1b64) // 64):
    dhparam += asn1b64[ii*64:ii*64+64] + "\n"
  dhparam += asn1b64[ii*64+64:] + "\n"
  dhparam += "-----END DH PARAMETERS-----"

  return dhparam

#################################################################################
# To asn1 (useful for openssl s_server -dhparam file_generated_by_this
#################################################################################

def to_go(modulus, generator):

  # modulus
  dhparam = "dh1024_p := ["
  modulus = int_to_bytearray(modulus)
  dhparam += str(len(modulus)) + "]byte{"
  for ii in modulus:
    dhparam += str(ii) + ", "
  dhparam += "}\n"
  
  #generator
  dhparam += "dh1024_g := ["
  generator = int_to_bytearray(generator)
  dhparam += str(len(generator)) + "]byte{"
  for ii in generator:
    dhparam += str(ii) + ", "
  dhparam += "}\n"

  #
  return dhparam

###

def main():
  # got modulus and generator from `sage backdoor_generator.sage 5`
  # missing params for this backdoor are in `../attack/method5_dhparams.data`
  modulus   = 223301975106993667325614167621709126547894648210186226643666068328617807516202545681655438155822192582033902502819313668103425198156427523424595010171112083255849911301850199554336445834580968127632569431148343473164461003102425641472990270060709999646440923327965355858492025074208423160672403731262306113
  generator = 133577237272149091420470710599617727967503551130038227711083989919128111659010169338433592360601283105084573447723432702474485969595386752970787786319095099886758944622697198813658852048492827918528163024844484146263552371160527611868901190798297550101799050105104076967399921052206210187792453635470388932

  # to asn1?
  if len(sys.argv) > 1 and sys.argv[1] == "asn1":
    dhparam = to_asn1(modulus, generator)
  elif len(sys.argv) > 1 and sys.argv[1] == "go":
    dhparam = to_go(modulus, generator)
  # -help
  else:
    print "python params_to_asn1.py [asn1|go] (output_file)?"
    return

  if len(sys.argv) > 2:
    newFile = open(sys.argv[2], "w")
    newFile.write(dhparam)
  else:
    print dhparam
  
if __name__ == "__main__":
  main()
