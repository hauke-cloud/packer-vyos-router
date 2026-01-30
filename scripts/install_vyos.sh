#!/bin/bash
set -e

echo "Starting VyOS installation..."

# The vyos-auto-install script is provided by the vyos-customization Debian package
# It should be installed at /usr/local/bin/vyos-auto-install during ISO build
if [ -f "/usr/local/bin/auto-install" ]; then
  echo "Using auto-install script from vyos-customization package"
  /usr/local/bin/auto-install --auto-install
else
  echo "ERROR: auto-install not found at /usr/local/bin/auto-install"
  echo "The VyOS ISO must be built with the vyos-customization package installed."
  exit 1
fi

echo "VyOS installation finished successfully."
