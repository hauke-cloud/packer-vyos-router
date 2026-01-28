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

# Clone and build vyos-customization package
echo "Building vyos-customization package..."
if [ ! -d "/tmp/vyos-customization" ]; then
    git clone --depth 1 https://github.com/hauke-cloud/vyos-customization.git /tmp/vyos-customization
fi

cd /tmp/vyos-customization
dpkg-buildpackage -us -uc -b || {
    echo "Package build requires: debhelper devscripts"
    echo "Install with: sudo apt-get install -y debhelper devscripts"
    exit 1
}

# Copy the built .deb to vyos-build/packages/
echo "Copying package to vyos-build/packages/..."
mkdir -p $OLDPWD/vyos-build/packages
cp ../*.deb $OLDPWD/vyos-build/packages/
ls -lh $OLDPWD/vyos-build/packages/

cd $OLDPWD

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
