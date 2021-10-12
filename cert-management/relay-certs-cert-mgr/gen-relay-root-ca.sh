#! /bin/bash

set -euo pipefail

openssl genrsa -out relay-root-key.pem 4096
openssl req -new -key relay-root-key.pem -config extfile.cnf -out relay-root-cert.csr
openssl x509 -req -days 3650 -extfile extfile.cnf -extensions v3_ca -in relay-root-cert.csr -signkey relay-root-key.pem -out relay-root-cert.pem


