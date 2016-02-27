# Attack

My setup is currently 3 VMs:
* client
* server
* proxy

1. On the proxy I run the `proxy.go` in sudo (you might have to build it to do that)

`go build proxy.go && sudo ./proxy -l ip_proxy:port_proxy -r ip_server:port_server

2. On the client I connect to the proxy, which will proxy the client to the server.

This is the easy way of simulating a Man-In-The-Middle. There might be more interesting ways to do that for real with bettercap/arpspoof and gopackets. There is also this MITM VM that kelby made: https://github.com/praetorian-inc/mitm-vm

3. To connect to the proxy, I used either socat or openssl:

* `socat - openssl:ip_proxy:port_proxy,verify=0` (I don't verify the server's cert)
* `openssl s_client -connect ip_proxy:port_proxy`

4. The server has to run either service:

* `socat openssl-listen:ip_server:port_server,cert=server.pem,key=server.key,verify=0,reuseaddr -`
* `openssl s_server -cert server.pem -key server.key -www -accept 4433 -msg -cipher "DH" -dhparam backdoored_dh`

of course I will create a key first: `openssl req -new -nodes -keyout server.key -out server.pem -x509` (and press enter until certs and key is made)

5. for the backdoor:

* I create it with what is in `backdoor_generator/backdoor_generator.sage`
* I transform the modulus and generator with `backdoor_generator/params_to_asn1.py` with option `asn1` for openssl and then `go` for the go proxy. A C option should be made to patch socat. The go proxy should accept params in a file as well.

6. The proxy should detect the backdoor and then decrypt socat or openssl (to be done)
