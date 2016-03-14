import base64, pdb, sys, re, argparse
from pyasn1.type import univ, namedtype, tag
from pyasn1.codec.der import encoder


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
    
#################################################################################
# To asn1 (useful for openssl s_server -dhparam file_generated_by_this
#################################################################################

def to_asn1(modulus, generator):
  # -> asn1
  asn1 = univ.SequenceOf(univ.Integer())
  asn1.setComponentByPosition(0, modulus)
  asn1.setComponentByPosition(1, generator)
  # -> der
  der = encoder.encode(asn1)
  # -> b64
  asn1b64 = base64.b64encode(der)
  dhparam = "-----BEGIN DH PARAMETERS-----\n"
  for ii in range(len(asn1b64) // 64):
    dhparam += asn1b64[ii*64:ii*64+64] + "\n"
  dhparam += asn1b64[ii*64+64:] + "\n"
  dhparam += "-----END DH PARAMETERS-----"
  # ->
  return dhparam

#################################################################################
# To go (useful for openssl s_server -dhparam file_generated_by_this
#################################################################################

def to_go(modulus, generator):

  # modulus
  dhparam = "dh1024_p := ["
  modulus = int_to_bytearray(modulus)
  dhparam += str(len(modulus)) + "]byte{"
  for ii in modulus:
    dhparam += hex(ii) + ", "
  dhparam += "}\n"
  
  #generator
  dhparam += "dh1024_g := ["
  generator = int_to_bytearray(generator)
  dhparam += str(len(generator)) + "]byte{"
  for ii in generator:
    dhparam += hex(ii) + ", "
  dhparam += "}\n"

  #
  return dhparam

### main ###

def main():
  # usage
  """
  parser = argparse.ArgumentParser(description='Export a modulus and a generator to a go or asn1 format.')
  parser.add_argument('modulus', metavar='m', type=int, nargs='+',
                      help='the modulus')
  parser.add_argument('generator', metavar='g', type=int, nargs='+',
                      help='the generator')
  args = parser.parse_args()
  """

  if len(sys.argv) < 4:
    print "normal usage:"
    print "> python dhparams_exporter.py [asn1|go] [modulus] [generator] (output_file)"
    print "decimal or hexadecimal permited"

    return

  # parse modulus
  modulus = sys.argv[2]

  if re.match(r'[0-9]+', modulus):
    modulus = int(modulus)
  elif re.match(r'[A-Za-z0-9]+', modulus):
    modulus = int(modulus, 16)
  else:
    print "cannot parse modulus"
    return

  # parse generator
  generator = sys.argv[3]
  if re.match(r'[0-9]+', generator):
    generator = int(generator)
  elif re.match(r'[A-Za-z0-9]+', generator):
    generator = int(generator, 16)
  else:
    print "cannot parse generator"
    return

  # to asn1?
  if sys.argv[1] == "asn1":
    dhparam = to_asn1(modulus, generator)
  elif sys.argv[1] == "go":
    dhparam = to_go(modulus, generator)

  if len(sys.argv) > 4:
    newFile = open(sys.argv[4], "w")
    newFile.write(dhparam)
  else:
    print dhparam
  
if __name__ == "__main__":
  main()
