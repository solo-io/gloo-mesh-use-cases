#!/bin/bash
#
# Creates the root cert A
#
if [[ "${PWD}" == *scripts ]]; then
  cd ..
fi
 
AROOT=${PWD}/aroot
mkdir -p ${AROOT}

openssl req -new -newkey rsa:4096 -x509 -sha256 \
  -days 3650 -nodes -out ${AROOT}/gloo-mesh-roota.crt -keyout ${AROOT}/gloo-mesh-roota.key \
  -subj "/CN=gloo-mesh-roota" \
  -addext "extendedKeyUsage = clientAuth, serverAuth"
