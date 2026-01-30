#!/bin/bash
# Fetches the latest release version of vyos-customization from GitHub
set -e

REPO="hauke-cloud/vyos-customization"
API_URL="https://api.github.com/repos/${REPO}/releases/latest"

# Fetch the latest release tag
LATEST_VERSION=$(curl -s "${API_URL}" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$LATEST_VERSION" ]; then
    echo "Error: Could not fetch latest version from ${REPO}" >&2
    exit 1
fi

echo "$LATEST_VERSION"
