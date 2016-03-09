import base64, pdb, sys, re, argparse

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
