#!/bin/bash
set -e

echo "Starting VyOS installation..."

# The vyos-auto-install script is provided by the vyos-customization Debian package
# It should be installed at /usr/local/bin/vyos-auto-install during ISO build
if [ -f "/usr/local/bin/vyos-auto-install" ]; then
    echo "Using vyos-auto-install script from vyos-customization package"
    /usr/local/bin/vyos-auto-install --auto-install
else
    echo "ERROR: vyos-auto-install not found at /usr/local/bin/vyos-auto-install"
    echo "The VyOS ISO must be built with the vyos-customization package installed."
    echo ""
    echo "Build the ISO with:"
    echo "  ./build-vyos-image-wrapper \\"
    echo "    --customization-mirror 'https://hauke-cloud.github.io/vyos-customization/' \\"
    echo "    --customization-package 'vyos-customization' \\"
    echo "    --architecture amd64 \\"
    echo "    --build-by 'hauke-cloud' \\"
    echo "    generic"
    exit 1
fi

echo "VyOS installation finished successfully."
