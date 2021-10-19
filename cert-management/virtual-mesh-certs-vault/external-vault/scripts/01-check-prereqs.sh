#!/bin/sh
# Prereqs Check
echo "Checking for openssl..."
which openssl
if [ $? != 0 ]; then
  echo "openssl not found. Consult your OS distribution to install."
  exit 1
fi
echo "Checking for vault..."
which vault
if [ $? != 0 ]; then
  echo "vault was not found. "
  exit 1
fi
echo "Checking for jq..."
which jq
if [ $? != 0 ]; then
  echo "jq was not found."
  exit 1
fi
echo "Prereqs check passed!"