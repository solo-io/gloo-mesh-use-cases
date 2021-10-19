#!/bin/bash
#
# Install root a in Vault

if [[ "${PWD}" == *scripts ]]; then
  cd ..
fi

AROOT=${PWD}/aroot

vault write -format=json pki/config/ca pem_bundle="$(cat ${AROOT}/gloo-mesh-roota.key ${AROOT}/gloo-mesh-roota.crt)"
