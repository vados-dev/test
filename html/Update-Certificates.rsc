#!rsc by Vados
# RouterOS script: Update-Certificates
# Script comment: Certificates CloudFlare, Quad9
# Copyright (c) 2005-2026 Vados <vados@vados.ru>
#
#
#
# requires RouterOS, version=7.19
# requires device-mode, fetch
#
# CloudFlare
/tool/fetch mode=https url=https://cacerts.digicert.com/DigiCertGlobalRootCA.crt.pem;
/certificate/import file-name=DigiCertGlobalRootCA.crt.pem passphrase="";
/tool/ fetch mode=https url=https://cacerts.digicert.com/DigiCertGlobalG2TLSRSASHA2562020CA1-1.crt.pem;
/certificate/import file-name=DigiCertGlobalG2TLSRSASHA2562020CA1-1.crt.pem passphrase="";
# Quad9
/tool/fetch mode=https url="https://cacerts.digicert.com/DigiCertGlobalG3TLSECCSHA3842020CA1-1.crt.pem"
/certificate/import file-name=DigiCertGlobalG3TLSECCSHA3842020CA1-1.crt.pem  passphrase="";

#:global AmScriptsUrl;
#google
#:local CertName "GTS-Root-R1.pem";
#/tool/fetch mode=https url=($AmScriptsUrl . "certs/" . $CertName);
#/certificate/import file-name=$CertName passphrase="";
#:set CertName "GTS-Root-R4.pem";
#/tool/fetch mode=https url=($AmScriptsUrl . "certs/" . $CertName);
#/certificate/import file-name=$CertName passphrase="";
#:set CertName "GTS-Root-RX.pem";
#/tool/fetch mode=https url=($AmScriptsUrl . "certs/" . $CertName);
#/certificate/import file-name=$CertName passphrase="";
#internet
#:set CertName "ISRG-Root-X1.pem";
#/tool/fetch mode=https url=($AmScriptsUrl . "certs/" . $CertName);
#/certificate/import file-name=$CertName passphrase="";
#:set CertName "ISRG-Root-X2.pem";
#/tool/fetch mode=https url=($AmScriptsUrl . "certs/" . $CertName);
#/certificate/import file-name=$CertName passphrase="";
#:set CertName "Starfield-Root-Certificate-Authority-G2.pem";
#/tool/fetch mode=https url=($AmScriptsUrl . "certs/" . $CertName);
#/certificate/import file-name=$CertName passphrase="";

#/ip/dns/set allow-remote-requests=yes doh-max-concurrent-queries=100 doh-max-server-connections=20 use-doh-server=https://security.cloudflare-dns.com/dns-query verify-doh-cert=yes;
#/ip/dns/static remove [find where address=1.1.1.1];
#/ip/dns/static add address=1.1.1.1 name=security.cloudflare-dns.com comment="cloudflare-dns IPv4 1";
#/ip/dns/ static remove  [find where address=1.0.0.1];
#/ip/dns/static add address=1.0.0.1 name=security.cloudflare-dns.com comment="cloudflare-dns IPv4 2"
#/ip dns static add address=2606:4700:4700::1111 name=security.cloudflare-dns.com type=AAAA
#/ip dns static add address=2606:4700:4700::1001 name=security.cloudflare-dns.com type=AAAA
#/ip/dns set servers="1.0.0.1, 8.8.4.4";
#/ip/dns set servers="";