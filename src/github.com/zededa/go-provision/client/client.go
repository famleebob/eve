package main

import (
	"bytes"
	"crypto/ecdsa"
	"crypto/rand"
	"crypto/sha256"
	"crypto/tls"
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"github.com/RevH/ipinfo"
	"github.com/satori/go.uuid"
	"github.com/zededa/go-provision/types"
	"golang.org/x/crypto/ocsp"
	"io/ioutil"
	"log"
	"net"
	"net/http"
	"os"
	"strings"
	"time"
)

var maxDelay = time.Second * 600 // 10 minutes

// Assumes the config files are in dirName, which is /opt/zededa/etc
// by default. The files are
//  root-certificate.pem	Fixed? Written if redirected. factory-root-cert?
//  server			Fixed? Written if redirected. factory-root-cert?
//  onboard.cert.pem, onboard.key.pem	Per device onboarding certificate/key
//  		   		for selfRegister operation
//  device.cert.pem,
//  device.key.pem		Device certificate/key created before this
//  		     		client is started.
//  infra			If this file exists assume zedcontrol and do not
//  				create ACLs
//  zedserverconfig		Written by lookupParam operation; zed server EIDs
//  zedrouterconfig.json	Written by lookupParam operation
//  uuid			Written by lookupParam operation
//  hwstatus.json		Uploaded by updateHwStatus operation
//  swstatus.json		Uploaded by updateSwStatus operation
//  clientIP			Written containing the public client IP
//
func main() {
	args := os.Args[1:]
	if len(args) > 10 { // XXX
		log.Fatal("Usage: " + os.Args[0] +
			"[<dirName> [<operations>...]]")
	}
	dirName := "/opt/zededa/etc"
	if len(args) > 0 {
		dirName = args[0]
	}
	operations := map[string]bool{
		"selfRegister":   false,
		"lookupParam":    false,
		"updateHwStatus": false,
		"updateSwStatus": false,
	}
	if len(args) > 1 {
		for _, op := range args[1:] {
			operations[op] = true
		}
	} else {
		// XXX for compat
		operations["selfRegister"] = true
		operations["lookupParam"] = true
	}

	onboardCertName := dirName + "/onboard.cert.pem"
	onboardKeyName := dirName + "/onboard.key.pem"
	deviceCertName := dirName + "/device.cert.pem"
	deviceKeyName := dirName + "/device.key.pem"
	rootCertName := dirName + "/root-certificate.pem"
	serverFileName := dirName + "/server"
	infraFileName := dirName + "/infra"
	zedserverConfigFileName := dirName + "/zedserverconfig"
	zedrouterConfigFileName := dirName + "/zedrouterconfig.json"
	uuidFileName := dirName + "/uuid"
	clientIPFileName := dirName + "/clientIP"
	hwStatusFileName := dirName + "/hwstatus.json"
	swStatusFileName := dirName + "/swstatus.json"

	var onboardCert, deviceCert tls.Certificate
	var deviceCertPem []byte
	deviceCertSet := false

	if operations["selfRegister"] {
		var err error
		onboardCert, err = tls.LoadX509KeyPair(onboardCertName, onboardKeyName)
		if err != nil {
			log.Fatal(err)
		}
		// Load device text cert for upload
		deviceCertPem, err = ioutil.ReadFile(deviceCertName)
		if err != nil {
			log.Fatal(err)
		}
	}
	if operations["lookupParam"] || operations["updateHwStatus"] ||
		operations["updateSwStatus"] {
		// Load device cert
		var err error
		deviceCert, err = tls.LoadX509KeyPair(deviceCertName,
			deviceKeyName)
		if err != nil {
			log.Fatal(err)
		}
		deviceCertSet = true
	}

	// Load CA cert
	caCert, err := ioutil.ReadFile(rootCertName)
	if err != nil {
		log.Fatal(err)
	}
	caCertPool := x509.NewCertPool()
	caCertPool.AppendCertsFromPEM(caCert)

	server, err := ioutil.ReadFile(serverFileName)
	if err != nil {
		log.Fatal(err)
	}
	serverNameAndPort := strings.TrimSpace(string(server))
	serverName := strings.Split(serverNameAndPort, ":")[0]
	// XXX for local testing
	// serverNameAndPort = "localhost:9069"

	// If infraFileName exists then don't set ACLs to eidset; allow any
	// EID to connect.
	ACLPromisc := false
	if _, err := os.Stat(infraFileName); err == nil {
		fmt.Printf("Setting ACLPromisc\n")
		ACLPromisc = true
	}

	// Post something without a return type.
	// Returns true when done; false when retry
	myPost := func(client *http.Client, url string, b *bytes.Buffer) bool {
		resp, err := client.Post("https://"+serverNameAndPort+url,
			"application/json", b)
		if err != nil {
			fmt.Println(err)
			return false
		}
		defer resp.Body.Close()
		connState := resp.TLS
		if connState == nil {
			fmt.Println("no TLS connection state")
			return false
		}

		if connState.OCSPResponse == nil ||
			!stapledCheck(connState) {
			if connState.OCSPResponse == nil {
				fmt.Println("no OCSP response")
			} else {
				fmt.Println("OCSP stapled check failed")
			}
			return false
		}

		contents, err := ioutil.ReadAll(resp.Body)
		if err != nil {
			fmt.Println(err)
			return false
		}

		// XXX Should this behavior be url-specific?
		switch resp.StatusCode {
		case http.StatusOK:
			fmt.Printf("%s StatusOK\n", url)
		case http.StatusCreated:
			fmt.Printf("%s StatusCreated\n", url)
		case http.StatusConflict:
			fmt.Printf("%s StatusConflict\n", url)
			// Retry until fixed
			fmt.Printf("%s\n", string(contents))
			return false
		default:
			fmt.Printf("%s statuscode %d %s\n",
				url, resp.StatusCode,
				http.StatusText(resp.StatusCode))
			fmt.Printf("%s\n", string(contents))
			return false
		}

		contentType := resp.Header.Get("Content-Type")
		if contentType != "application/json" {
			fmt.Println("Incorrect Content-Type " + contentType)
			return false
		}
		fmt.Printf("%s\n", string(contents))
		return true
	}

	// Returns true when done; false when retry
	selfRegister := func() bool {
		// Setup HTTPS client
		tlsConfig := &tls.Config{
			Certificates: []tls.Certificate{onboardCert},
			ServerName:   serverName,
			RootCAs:      caCertPool,
			CipherSuites: []uint16{
				tls.TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,
				tls.TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256},
			// TLS 1.2 because we can
			MinVersion: tls.VersionTLS12,
		}
		tlsConfig.BuildNameToCertificate()

		fmt.Printf("Connecting to %s\n", serverNameAndPort)

		transport := &http.Transport{TLSClientConfig: tlsConfig}
		client := &http.Client{Transport: transport}
		rc := types.RegisterCreate{PemCert: deviceCertPem}
		b := new(bytes.Buffer)
		json.NewEncoder(b).Encode(rc)
		return myPost(client, "/rest/self-register", b)
	}

	// Returns true when done; false when retry
	lookupParam := func(client *http.Client, device *types.DeviceDb) bool {
		resp, err := client.Get("https://" + serverNameAndPort +
			"/rest/device-param")
		if err != nil {
			fmt.Println(err)
			return false
		}
		defer resp.Body.Close()
		connState := resp.TLS
		if connState == nil {
			log.Println("no TLS connection state")
			return false
		}

		if connState.OCSPResponse == nil ||
			!stapledCheck(connState) {
			if connState.OCSPResponse == nil {
				fmt.Println("no OCSP response")
			} else {
				fmt.Println("OCSP stapled check failed")
			}
			return false
		}

		contents, err := ioutil.ReadAll(resp.Body)
		if err != nil {
			fmt.Println(err)
			return false
		}
		switch resp.StatusCode {
		case http.StatusOK:
			fmt.Printf("device-param StatusOK\n")
		default:
			fmt.Printf("device-param statuscode %d %s\n",
				resp.StatusCode,
				http.StatusText(resp.StatusCode))
			fmt.Printf("%s\n", string(contents))
			return false
		}
		contentType := resp.Header.Get("Content-Type")
		if contentType != "application/json" {
			fmt.Println("Incorrect Content-Type " + contentType)
			return false
		}
		if err := json.Unmarshal(contents, &device); err != nil {
			fmt.Println(err)
			return false
		}
		return true
	}

	if operations["selfRegister"] {
		done := false
		var delay time.Duration
		for !done {
			time.Sleep(delay)
			done = selfRegister()
			delay = 2 * (delay + time.Second)
			if delay > maxDelay {
				delay = maxDelay
			}
		}
	}

	if !deviceCertSet {
		return
	}
	// Setup HTTPS client for deviceCert
	tlsConfig := &tls.Config{
		Certificates: []tls.Certificate{deviceCert},
		ServerName:   serverName,
		RootCAs:      caCertPool,
		CipherSuites: []uint16{
			tls.TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,
			tls.TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256},
		// TLS 1.2 because we can
		MinVersion: tls.VersionTLS12,
	}
	tlsConfig.BuildNameToCertificate()

	transport := &http.Transport{TLSClientConfig: tlsConfig}
	client := &http.Client{Transport: transport}

	var addInfoDevice *types.AdditionalInfoDevice
	if operations["lookupParam"] || operations["updateHwStatus"] {
		// Determine location information and use as AdditionalInfo
		if myIP, err := ipinfo.MyIP(); err == nil {
			addInfo := types.AdditionalInfoDevice{
				UnderlayIP: myIP.IP,
				Hostname:   myIP.Hostname,
				City:       myIP.City,
				Region:     myIP.Region,
				Country:    myIP.Country,
				Loc:        myIP.Loc,
				Org:        myIP.Org,
			}
			addInfoDevice = &addInfo
		}
	}

	if operations["lookupParam"] {
		done := false
		var delay time.Duration
		device := types.DeviceDb{}
		for !done {
			time.Sleep(delay)
			done = lookupParam(client, &device)
			delay = 2 * (delay + time.Second)
			if delay > maxDelay {
				delay = maxDelay
			}
		}

		// XXX add Redirect support and store + retry
		// XXX try redirected once and then fall back to original; repeat
		// XXX once redirect successful, then save server and rootCert

		// Convert from IID and IPv6 EID to a string with
		// [iid]eid, where the eid uses the textual format defined in
		// RFC 5952. The iid is printed as an integer.
		sigdata := fmt.Sprintf("[%d]%s",
			device.LispInstance, device.EID.String())
		fmt.Printf("sigdata (len %d) %s\n", len(sigdata), sigdata)

		hasher := sha256.New()
		hasher.Write([]byte(sigdata))
		hash := hasher.Sum(nil)
		fmt.Printf("hash (len %d) % x\n", len(hash), hash)
		fmt.Printf("base64 hash %s\n",
			base64.StdEncoding.EncodeToString(hash))

		var signature string
		switch deviceCert.PrivateKey.(type) {
		default:
			log.Fatal("Private Key RSA type not supported")
		case *ecdsa.PrivateKey:
			key := deviceCert.PrivateKey.(*ecdsa.PrivateKey)
			r, s, err := ecdsa.Sign(rand.Reader, key, hash)
			if err != nil {
				log.Fatal("ecdsa.Sign: ", err)
			}
			fmt.Printf("r.bytes %d s.bytes %d\n", len(r.Bytes()),
				len(s.Bytes()))
			sigres := r.Bytes()
			sigres = append(sigres, s.Bytes()...)
			fmt.Printf("sigres (len %d): % x\n", len(sigres), sigres)
			signature = base64.StdEncoding.EncodeToString(sigres)
			fmt.Println("signature:", signature)
		}
		fmt.Printf("UserName %s\n", device.UserName)
		fmt.Printf("MapServers %s\n", device.LispMapServers)
		fmt.Printf("Lisp IID %d\n", device.LispInstance)
		fmt.Printf("EID %s\n", device.EID)
		fmt.Printf("EID hash length %d\n", device.EIDHashLen)

		// write zedserverconfig file with hostname to EID mappings
		f, err := os.Create(zedserverConfigFileName)
		if err != nil {
			log.Fatal(err)
		}
		defer f.Close()
		for _, ne := range device.ZedServers.NameToEidList {
			for _, eid := range ne.EIDs {
				output := fmt.Sprintf("%-46v %s\n",
					eid, ne.HostName)
				_, err := f.WriteString(output)
				if err != nil {
					log.Fatal(err)
				}
			}
		}
		f.Sync()

		// Determine whether NAT is in use
		if publicIP, err := addrStringToIP(device.ClientAddr); err != nil {
			log.Printf("Failed to convert %s, error %s\n",
				device.ClientAddr, err)
			// Remove any existing/old file
			_ = os.Remove(clientIPFileName)
		} else {
			nat := !IsMyAddress(publicIP)
			fmt.Printf("NAT %v, publicIP %v\n", nat, publicIP)
			// Store clientIP in file for device-steps.sh
			b := []byte(fmt.Sprintf("%s\n", publicIP))
			err = ioutil.WriteFile(clientIPFileName, b, 0644)
			if err != nil {
				log.Fatal("WriteFile", err, clientIPFileName)
			}
		}
		var devUUID uuid.UUID
		if _, err := os.Stat(uuidFileName); err != nil {
			// Create and write with initial values
			devUUID = uuid.NewV4()
			b := []byte(fmt.Sprintf("%s\n", devUUID))
			err = ioutil.WriteFile(uuidFileName, b, 0644)
			if err != nil {
				log.Fatal("WriteFile", err, uuidFileName)
			}
			fmt.Printf("Created UUID %s\n", devUUID)
		} else {
			b, err := ioutil.ReadFile(uuidFileName)
			if err != nil {
				log.Fatal("ReadFile", err, uuidFileName)
			}
			uuidStr := strings.TrimSpace(string(b))
			devUUID, err = uuid.FromString(uuidStr)
			if err != nil {
				log.Fatal("uuid.FromString", err, string(b))
			}
			fmt.Printf("Read UUID %s\n", devUUID)
		}
		uv := types.UUIDandVersion{
			UUID:    devUUID,
			Version: "0",
		}
		// Write an AppNetworkConfig for the ZedManager application
		config := types.AppNetworkConfig{
			UUIDandVersion: uv,
			DisplayName:    "zedmanager",
			IsZedmanager:   true,
		}
		olconf := make([]types.OverlayNetworkConfig, 1)
		config.OverlayNetworkList = olconf
		olconf[0].IID = device.LispInstance
		olconf[0].EID = device.EID
		olconf[0].LispSignature = signature
		olconf[0].AdditionalInfoDevice = addInfoDevice
		olconf[0].NameToEidList = device.ZedServers.NameToEidList
		acl := make([]types.ACE, 1)
		olconf[0].ACLs = acl
		matches := make([]types.ACEMatch, 1)
		acl[0].Matches = matches
		actions := make([]types.ACEAction, 1)
		acl[0].Actions = actions
		if ACLPromisc {
			matches[0].Type = "ip"
			matches[0].Value = "::/0"
		} else {
			matches[0].Type = "eidset"
		}
		writeNetworkConfig(&config, zedrouterConfigFileName)
	}
	if operations["updateHwStatus"] {
		// Load file for upload
		buf, err := ioutil.ReadFile(hwStatusFileName)
		if err != nil {
			log.Fatal(err)
		}
		// Input is in json format; parse and add additionalInfo
		b := bytes.NewBuffer(buf)
		// parsing DeviceHwStatus json payload
		hwStatus := &types.DeviceHwStatus{}
		if err := json.NewDecoder(b).Decode(hwStatus); err != nil {
			log.Fatal("Error decoding DeviceHwStatus: ", err)
		}
		hwStatus.AdditionalInfoDevice = *addInfoDevice
		fmt.Printf("hwStatus %v\n", hwStatus) // XXX remove
		b = new(bytes.Buffer)
		json.NewEncoder(b).Encode(hwStatus)

		done := false
		var delay time.Duration
		for !done {
			time.Sleep(delay)
			done = myPost(client, "/rest/update-hw-status", b)
			delay = 2 * (delay + time.Second)
			if delay > maxDelay {
				delay = maxDelay
			}
		}
	}
	if operations["updateSwStatus"] {
		// Load file for upload
		buf, err := ioutil.ReadFile(swStatusFileName)
		if err != nil {
			log.Fatal(err)
		}
		// Input is in json format
		b := bytes.NewBuffer(buf)
		done := false
		var delay time.Duration
		for !done {
			time.Sleep(delay)
			done = myPost(client, "/rest/update-sw-status", b)
			delay = 2 * (delay + time.Second)
			if delay > maxDelay {
				delay = maxDelay
			}
		}
	}
}

func writeNetworkConfig(config *types.AppNetworkConfig,
	configFilename string) {
	fmt.Printf("Writing AppNetworkConfig to %s\n", configFilename)
	b, err := json.Marshal(config)
	if err != nil {
		log.Fatal(err, "json Marshal AppNetworkConfig")
	}
	err = ioutil.WriteFile(configFilename, b, 0644)
	if err != nil {
		log.Fatal(err, configFilename)
	}
}

func addrStringToIP(addrString string) (net.IP, error) {
	clientTCP, err := net.ResolveTCPAddr("tcp", addrString)
	if err != nil {
		return net.IP{}, err
	}
	return clientTCP.IP, nil
}

// IsMyAddress checks the IP address against the local IPs. Returns True if
// there is a match.
func IsMyAddress(clientIP net.IP) bool {
	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return false
	}
	for _, address := range addrs {
		if ipnet, ok := address.(*net.IPNet); ok &&
			!ipnet.IP.IsLoopback() {
			if bytes.Compare(ipnet.IP, clientIP) == 0 {
				return true
			}
		}
	}
	return false
}

func stapledCheck(connState *tls.ConnectionState) bool {
	// server := connState.VerifiedChains[0][0]
	issuer := connState.VerifiedChains[0][1]
	resp, err := ocsp.ParseResponse(connState.OCSPResponse, issuer)
	if err != nil {
		log.Println("error parsing response: ", err)
		return false
	}
	now := time.Now()
	age := now.Unix() - resp.ProducedAt.Unix()
	remain := resp.NextUpdate.Unix() - now.Unix()
	log.Printf("OCSP age %d, remain %d\n", age, remain)
	if remain < 0 {
		log.Println("OCSP expired.")
		return false
	}
	if resp.Status == ocsp.Good {
		log.Println("Certificate Status Good.")
	} else if resp.Status == ocsp.Unknown {
		log.Println("Certificate Status Unknown")
	} else {
		log.Println("Certificate Status Revoked")
	}
	return resp.Status == ocsp.Good
}
