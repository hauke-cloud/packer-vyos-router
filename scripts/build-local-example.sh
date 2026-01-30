#!/bin/bash
#
# Example: Local build using build-vyos-image-wrapper
#
# This script demonstrates how to build a VyOS ISO locally using the wrapper
# with custom APT repositories and packages.
#

set -e

# Configuration
BUILD_BY="${BUILD_BY:-hauke-cloud}"
BUILD_VERSION="${BUILD_VERSION:-1.5-rolling-$(date -u +%Y%m%d%H%M)}"
ARCHITECTURE="${ARCHITECTURE:-amd64}"

# Clone vyos-build repository if it doesn't exist
if [ ! -d "vyos-build" ]; then
    echo "Cloning vyos-build repository..."
    git clone https://github.com/vyos/vyos-build.git
fi

# Fetch latest vyos-customization version from GitHub
echo "Fetching latest vyos-customization version from GitHub..."
CUSTOMIZATION_VERSION=$(./scripts/get_latest_vyos_customization_version.sh)

if [ -z "$CUSTOMIZATION_VERSION" ]; then
    echo "Error: Could not fetch latest version from GitHub"
    exit 1
fi

echo "Using vyos-customization version: $CUSTOMIZATION_VERSION"

# Save version to metadata file for Packer
echo "$CUSTOMIZATION_VERSION" > customization-version.txt
echo "Saved version to customization-version.txt"

# Get release info to find the actual .deb filename
echo "Fetching release info..."
RELEASE_INFO=$(curl -s "https://api.github.com/repos/hauke-cloud/vyos-customization/releases/tags/${CUSTOMIZATION_VERSION}")

DEB_FILE=$(echo "$RELEASE_INFO" | jq -r '.assets[] | select(.name | endswith(".deb")) | .name' | head -n1)
DOWNLOAD_URL=$(echo "$RELEASE_INFO" | jq -r '.assets[] | select(.name | endswith(".deb")) | .browser_download_url' | head -n1)

if [ -z "$DEB_FILE" ] || [ "$DEB_FILE" = "null" ]; then
    echo "Error: Could not find .deb file in release $CUSTOMIZATION_VERSION"
    echo "Make sure the release exists at:"
    echo "https://github.com/hauke-cloud/vyos-customization/releases/tag/$CUSTOMIZATION_VERSION"
    exit 1
fi

# Download vyos-customization package
echo "Downloading $DEB_FILE..."
mkdir -p vyos-build/packages
if ! curl -L -f -o vyos-build/packages/$DEB_FILE "$DOWNLOAD_URL"; then
    echo "Error: Download failed from $DOWNLOAD_URL"
    exit 1
fi

echo "Package downloaded:"
ls -lh vyos-build/packages/

# Change to vyos-build directory
cd vyos-build

# Pull the latest Docker image
echo "Pulling vyos-build Docker image..."
docker pull vyos/vyos-build:current

# Build the ISO
echo "Building VyOS ISO with customizations..."
docker run --rm \
    --privileged \
    -v "$(pwd)":/vyos \
    -w /vyos \
    -e BUILD_BY="${BUILD_BY}" \
    --sysctl net.ipv6.conf.lo.disable_ipv6=0 \
    vyos/vyos-build:current \
    sudo ./build-vyos-image \
        --architecture "${ARCHITECTURE}" \
        --build-by "${BUILD_BY}" \
        --build-type release \
        --custom-package vyos-1x-smoketest \
        --version "${BUILD_VERSION}" \
        generic

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Build Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "ISO files can be found in: vyos-build/build/"
ls -lh build/*.iso 2>/dev/null || echo "No ISO files found"
