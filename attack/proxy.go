package main

import (
	"log"
	"bytes"
	"encoding/binary"
	"flag"
	"net"
	"fmt"
	"io"
	"os"
)

// get client and server ip:port
var localAddr *string = flag.String("l", "localhost:6666", "this proxy address")
var serverAddr *string = flag.String("r", "localhost:5443", "socat server address")

// global vars
var handshake_step int
var clientRandom [32]byte
var serverRandom [32]byte
var modulus []byte 
var generator []byte
var serverPubkey []byte
var clientPubkey []byte

// attack
func attack() {
	// everything is a global var
}

// backdoored modulus?

func equality(a []byte, b []byte) (bool) {
	// bytes
	for index,_ := range a {
		if a[index] != b[index] {
			return false
		}
	}
	//
	return true
}

func backdoored(modulus []byte, generator []byte) (bool) {
	dh1024_p := []byte{81, 103, 245, 255, 142, 93, 151, 165, 53, 36, 245, 103, 208, 126, 168, 12, 207, 110, 10, 205, 71, 23, 232, 73, 183, 70, 245, 216, 195, 149, 101, 181, 149, 112, 62, 61, 238, 8, 3, 151, 14, 95, 68, 144, 75, 16, 18, 33, 167, 82, 44, 92, 170, 122, 145, 42, 6, 92, 216, 174, 69, 172, 10, 75, 84, 129, 99, 65, 72, 38, 34, 37, 24, 106, 78, 179, 123, 11, 100, 106, 134, 224, 39, 157, 44, 167, 82, 162, 14, 48, 139, 27, 13, 96, 80, 7, 156, 239, 161, 170, 26, 119, 89, 87, 235, 47, 51, 152, 224, 40, 30, 59, 93, 180, 135, 70, 210, 7, 117, 1, 126, 214, 195, 36, 105, 119, 65, }

	dh1024_g := []byte{48, 178, 71, 15, 134, 34, 126, 212, 37, 161, 132, 205, 184, 172, 127, 212, 63, 228, 176, 39, 2, 67, 182, 119, 24, 191, 60, 120, 130, 194, 178, 132, 45, 236, 173, 205, 91, 145, 22, 185, 152, 116, 31, 178, 217, 166, 71, 26, 113, 12, 134, 212, 178, 130, 61, 91, 116, 181, 110, 33, 182, 55, 150, 242, 71, 157, 71, 183, 137, 74, 192, 208, 157, 195, 131, 194, 42, 195, 82, 43, 35, 150, 237, 230, 202, 134, 82, 77, 16, 199, 9, 3, 253, 85, 66, 143, 6, 172, 162, 104, 22, 195, 214, 112, 158, 54, 251, 68, 196, 170, 133, 44, 178, 151, 255, 22, 202, 210, 88, 67, 222, 233, 74, 214, 121, 238, 196, }

	if len(dh1024_p) == len(modulus) && len(dh1024_g) == len(generator) &&
		equality(dh1024_p, modulus) && equality(dh1024_g, generator) {
		log.Println("backdoor detected!")
		return true
	} else {
		return false
	}
}

// Parse the first TLS record, returns the en
func parseTLSRecord(payload []byte) (int) {
	// settings
	record_length := int(binary.BigEndian.Uint32(append([]byte{0x0}, payload[1:4]...)))

	// what type of record?
	if payload[0] == 1 { // clientHello
		log.Println("parsing clientHello")
		handshake_step = 1
		// clientRandom (need to strip the first 4 bytes though I think)
		copy(clientRandom[:], payload[6:32+6]) 
		log.Println("clientRandom:", clientRandom)

	} else if payload[0] == 2 && handshake_step == 1 { // serverHello
		log.Println("parsing serverHello")
		handshake_step = 2
		// serverRandom
		copy(serverRandom[:], payload[6:32+6])
		log.Println("serverRandom:", serverRandom)

	} else if payload[0] == 12 && handshake_step == 2 { // serverKeyExchange
		log.Println("parsing serverKeyExchange")
		handshake_step = 12
		// modulus
		modulus_size := int(binary.BigEndian.Uint16(payload[4:6]))
		offset := 6
		modulus = make([]byte, modulus_size)
		copy(modulus, payload[offset:offset+modulus_size])
		log.Println("modulus:", modulus)
		// generator
		offset += modulus_size
		generator_size := int(binary.BigEndian.Uint16(payload[offset:offset+2]))
		offset += 2
		generator = make([]byte, generator_size)
		copy(generator, payload[offset:offset+generator_size])
		log.Println("generator:", generator)

		// check if modulus is backdoored
		if !backdoored(modulus, generator){
			handshake_step = 1
		} else {
			// server public key
			offset += generator_size

			pubkeyLength := int(binary.BigEndian.Uint16(payload[offset:offset+2]))
			offset += 2

			serverPubkey = make([]byte, pubkeyLength)
			copy(serverPubkey, payload[offset:offset+pubkeyLength])
			log.Println("serverPubkey:", serverPubkey)
		}
		
	} else if payload[0] == 16 && handshake_step == 12 { // clientKeyExchange
		log.Println("parsing clientKeyExchange")
		handshake_step = 16
		// client public key
		pubkeyLength := int(binary.BigEndian.Uint16(payload[4:6]))
		clientPubkey = make([]byte, pubkeyLength)
		copy(clientPubkey, payload[6:6+pubkeyLength])
		log.Println("clientPubkey:", clientPubkey)
		// perform the attack
		//successful <- attack() (this should be an event)
	} else {
		log.Println("parsing something else")
	}

	// return the index of the next record
	return record_length + 1 + 3
}

// the forwarder/parser
func forwardTLS(r io.Reader, w io.Writer) {
	header := make([]byte, 5)

	for {
		// read header
		log.Println("---new_packet---")
		read, err := io.ReadFull(r, header)
		if err != nil {
			// end of connection? connection closed?
			if err == io.EOF || err == io.ErrClosedPipe {
				log.Printf("received err: %v", err)
			} else {
				log.Printf("received err: %v", err)
			}
			break
		}
		if read != 5 {
			log.Println("tcp: can't read header, read only ", read)
		}

		if header[0] == 0x16 {
			log.Println("tls:handshake")
		} else if header[0] == 0x14 {
			log.Println("tls:changeCipherSpec")
		} else if header[0] == 0x17 {
			log.Println("tls:application data")
		} else if header[0] == 0x15 {
			log.Println("tls:alert")
		} else if header[0] == 0x18 {
			log.Println("tls:heartbeat")
		} else {
			// packet is not a TLS record (must be http?)
			log.Println("tcp:PACKET IS NOT A TLS RECORD! ", header)

			// read until \r or \n
			buf := &bytes.Buffer{}
			for {
				data := make([]byte, 256)
				n, err := r.Read(data)
				if err != nil {
					panic(err)
				}
				buf.Write(data[:n])
				if data[0] == '\r' && data[1] == '\n' {
					break
				}
			}

			// write everything
			if _, err := w.Write(append(header, buf.Bytes()...)); err != nil {
				panic(err)
			}

			// skip the TLS part
			continue

		}
		
		// read the rest (only works for TLS records!)
		payload_length := int(binary.BigEndian.Uint16(header[3:5]))
		payload := make([]byte, payload_length)

		log.Println("payload_length", payload_length)

		_, err = io.ReadFull(r, payload)
		if err != nil {
			panic(err)
		}

		// parse the record it's a handshake
		if header[0] == 0x16 {
			offset := 0
			for offset < len(payload) {
				offset += parseTLSRecord(payload[offset:])
			}
		}

		// try and decrypt right away?
		if header[0] == 0x17 { //&& successful == True {
			// create a routine? because if we are still calculating the key...
		}

		// write everything
		_, err = w.Write(append(header, payload...))
		if err != nil {
			panic(err)
		}
	} // endfor
}

// forwaridng traffic
func handleConnection(client net.Conn) {
	log.Println("connection accepted")
	// dial the ip
	log.Println("forwarding to", *serverAddr)

	saddr, err := net.ResolveTCPAddr("tcp", *serverAddr)
	if err != nil {
		panic(err)
	}

	server, err := net.DialTCP("tcp", nil, saddr)
	if err != nil {
		panic(err)
	}

	defer client.Close()
	defer server.Close()

	go forwardTLS(client, server)
	forwardTLS(server, client)
}

//
func main() {
	// get client and server's ip:port
	flag.Parse()

	// accept (as many connections atm)
	laddr, err := net.ResolveTCPAddr("tcp", *localAddr)
	if err != nil {
		panic(err)
	}

	// setting up the proxy
	local, err := net.ListenTCP("tcp", laddr)
	if local == nil {
		fatal("cannot listen: %v", err)
	}

	log.Println("running proxy on", laddr)
	for {
		conn, err := local.AcceptTCP()
		if conn == nil {
			fatal("accept failed: %v", err)
		}
		go handleConnection(conn)
	}
}

func fatal(s string, a ... interface{}) {
	fmt.Fprintf(os.Stderr, "netfwd: %s\n", fmt.Sprintf(s, a))
	os.Exit(2)
}
