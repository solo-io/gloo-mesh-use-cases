#!/bin/bash

set -e

# Check if required environment variables are defined
required_vars=("ISTIO_IMAGE")
for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    echo "Error: $var is not defined."
    echo "Please set the following environment variables before running this script:"
    echo "  - ISTIO_IMAGE (e.g., 1.28.1-solo)"
    echo "  - REPO_KEY (for Istio 1.28 and earlier)"
    exit 1
  fi
done

echo "========================================="
echo "Installing istioctl"
echo "========================================="
echo ""
echo "Istio Version: $ISTIO_IMAGE"

# Check if istioctl is already installed with the correct version
if command -v istioctl &> /dev/null; then
  CURRENT_VERSION=$(istioctl version --remote=false 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+-solo' | head -1)
  if [ "$CURRENT_VERSION" = "$ISTIO_IMAGE" ]; then
    echo "✓ istioctl $ISTIO_IMAGE is already installed"
    echo ""
    echo "Installation complete!"
    exit 0
  else
    echo "Found istioctl $CURRENT_VERSION, but need $ISTIO_IMAGE. Updating..."
    echo ""
  fi
fi

# Auto-detect OS and architecture
echo "Detecting OS and architecture..."
OS=$(uname | tr '[:upper:]' '[:lower:]' | sed -E 's/darwin/osx/')
ARCH=$(uname -m | sed -E 's/aarch/arm/; s/x86_64/amd64/; s/armv7l/armv7/')
echo "OS: $OS"
echo "ARCH: $ARCH"
echo ""

# Extract Istio version number (e.g., "1.28.1" from "1.28.1-solo")
ISTIO_VERSION_NUM=$(echo $ISTIO_IMAGE | sed 's/-solo//')
ISTIO_MAJOR_MINOR=$(echo $ISTIO_VERSION_NUM | cut -d. -f1,2)

# Determine download method based on Istio version
# Istio 1.29+ uses the new download location
if [ "$(printf '%s\n' "1.29" "$ISTIO_MAJOR_MINOR" | sort -V | head -n1)" = "1.29" ]; then
  # Istio 1.29 and later
  echo "Detected Istio 1.29 or later, using updated download location..."
  DOWNLOAD_URL="https://storage.googleapis.com/soloio-istio-binaries/release/$ISTIO_IMAGE/istio-$ISTIO_IMAGE-$OS-$ARCH.tar.gz"
  
  echo "Downloading istioctl from: $DOWNLOAD_URL"
  mkdir -p ~/.istioctl/bin
  curl -sSL $DOWNLOAD_URL | tar xzf - -C ~/.istioctl/bin
  
  # Move from extracted directory structure
  if [ -d ~/.istioctl/bin/istio-$ISTIO_IMAGE/bin ]; then
    mv ~/.istioctl/bin/istio-$ISTIO_IMAGE/bin/istioctl ~/.istioctl/bin/istioctl
    rm -rf ~/.istioctl/bin/istio-$ISTIO_IMAGE
  fi
else
  # Istio 1.28 and earlier
  echo "Detected Istio 1.28 or earlier, using 1.28 repo download location..."
  
  # Check for REPO_KEY
  if [ -z "$REPO_KEY" ]; then
    echo "Error: REPO_KEY is required for Istio 1.28 and earlier."
    echo "Set REPO_KEY to the 12-character hash from the repo URL."
    exit 1
  fi
  
  DOWNLOAD_URL="https://storage.googleapis.com/istio-binaries-$REPO_KEY/$ISTIO_IMAGE/istioctl-$ISTIO_IMAGE-$OS-$ARCH.tar.gz"
  
  echo "Downloading istioctl from: $DOWNLOAD_URL"
  mkdir -p ~/.istioctl/bin
  curl -sSL $DOWNLOAD_URL | tar xzf - -C ~/.istioctl/bin
fi

# Make executable
chmod +x ~/.istioctl/bin/istioctl

# Add to PATH if not already there
if [[ ":$PATH:" != *":$HOME/.istioctl/bin:"* ]]; then
  export PATH=${HOME}/.istioctl/bin:${PATH}
  echo ""
  echo "Added ~/.istioctl/bin to PATH for this session."
  echo "To persist this change, add the following to your shell profile:"
  echo '  export PATH=$HOME/.istioctl/bin:$PATH'
fi

echo ""
echo "========================================="
echo "Verifying istioctl Installation"
echo "========================================="
echo ""

# Verify installation
if istioctl version --remote=false > /dev/null 2>&1; then
  INSTALLED_VERSION=$(istioctl version --remote=false 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+-solo' | head -1)
  echo "✓ istioctl installed successfully"
  echo "Client version: $INSTALLED_VERSION"
  echo ""
  
  if [ "$INSTALLED_VERSION" != "$ISTIO_IMAGE" ]; then
    echo "⚠ Warning: Installed version ($INSTALLED_VERSION) does not match requested version ($ISTIO_IMAGE)"
  fi
else
  echo "✗ Failed to verify istioctl installation"
  exit 1
fi

echo "Installation complete!"

