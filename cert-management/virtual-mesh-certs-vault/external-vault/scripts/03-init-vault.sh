#!/bin/sh
#
# Initialize vault for pki

vault secrets enable pki

vault secrets enable -path=pki_int pki
