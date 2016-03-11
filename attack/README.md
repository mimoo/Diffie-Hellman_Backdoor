# Attack setup

## Generating the backdoor

First you need to generate the backdoor parameters, head over to the [/backdoor_generator](/backdoor_generator) folder and do that first. There is a script there to generate the parameters, there are also scripts to export the parameters to go or asn1 (for direct use in OpenSSL, Socat, ...)

Generate the go code for the parameters and replace them in the `attack.go` file.

## Setup

My setup is currently 3 VMs:

* a *client* machine
* a *server* machine
* a *proxy* machine

The client connects to the server by connecting to the proxy, this is an easy way to reproduce a Man-In-The-Middle setup.

* On the proxy machine I run the proxy: `go build proxy.go attack.go && sudo ./proxy -l ip_proxy:6666 -r ip_server:443`

* On the server machine I run the server: `sudo socat openssl-listen:443,verify=0,cert=server.pem,key=server.key,cipher="DHE-RSA-AES128-SHA256",reuseaddr,dhparam=dhfile -`. the server RSA key and certs can be generated with `openssl req -new -key key.key -x509 -days 3653 -out cert.crt`, the `dhfile` contains the backdoored parameters in asn1 DER encoded, you can use the script in [/backdoor_generator](/backdoor_generator) to create it.

* On the client machine I run the client: `socat - openssl:ip_proxy:6666,verify=0,reuseaddr`

You should see what the server and the client are writing to each other in the proxy. 

