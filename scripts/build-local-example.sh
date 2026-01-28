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

# Read vyos-customization version from config file
echo "Reading vyos-customization version..."
CUSTOMIZATION_VERSION=$(grep -v '^#' .vyos-customization-version | grep -v '^[[:space:]]*$' | head -n1)

if [ -z "$CUSTOMIZATION_VERSION" ]; then
    echo "Error: Could not read version from .vyos-customization-version"
    exit 1
fi

echo "Using vyos-customization version: $CUSTOMIZATION_VERSION"

# Download vyos-customization package from releases
echo "Downloading vyos-customization package..."
mkdir -p vyos-build/packages
DEB_FILE="vyos-customization_1.0.0-1_all.deb"
curl -L -f -o vyos-build/packages/$DEB_FILE \
    "https://github.com/hauke-cloud/vyos-customization/releases/download/${CUSTOMIZATION_VERSION}/${DEB_FILE}" || {
    echo "Error: Download failed. Make sure version $CUSTOMIZATION_VERSION exists."
    exit 1
}

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
