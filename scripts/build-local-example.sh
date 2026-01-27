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
CUSTOMIZATION_MIRROR="${CUSTOMIZATION_MIRROR:-https://hauke-cloud.github.io/vyos-customization/}"
CUSTOMIZATION_PACKAGE="${CUSTOMIZATION_PACKAGE:-vyos-customization}"

# Clone vyos-build repository if it doesn't exist
if [ ! -d "vyos-build" ]; then
    echo "Cloning vyos-build repository..."
    git clone https://github.com/vyos/vyos-build.git
fi

# Copy the wrapper script
echo "Copying wrapper script..."
cp scripts/build-vyos-image-wrapper vyos-build/
chmod +x vyos-build/build-vyos-image-wrapper

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
    sudo ./build-vyos-image-wrapper \
        --architecture "${ARCHITECTURE}" \
        --build-by "${BUILD_BY}" \
        --build-type release \
        --custom-package vyos-1x-smoketest \
        --customization-mirror "${CUSTOMIZATION_MIRROR}" \
        --customization-package "${CUSTOMIZATION_PACKAGE}" \
        --version "${BUILD_VERSION}" \
        generic

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Build Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "ISO files can be found in: vyos-build/build/"
ls -lh build/*.iso 2>/dev/null || echo "No ISO files found"
