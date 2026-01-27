#!/bin/bash
set -e

echo "Starting VyOS installation..."

# Check if auto-install script is available (embedded in custom ISO)
# Try multiple locations for compatibility
if [ -f "/usr/local/bin/vyos-auto-install" ]; then
    echo "Using embedded auto-install script from custom ISO (/usr/local/bin)"
    /usr/local/bin/vyos-auto-install --auto-install
elif [ -f "/usr/bin/vyos-auto-install" ]; then
    echo "Using embedded auto-install script from custom ISO (/usr/bin)"
    /usr/bin/vyos-auto-install --auto-install
else
    echo "Auto-install script not found, using legacy method"
    echo "Checked locations: /usr/local/bin/vyos-auto-install, /usr/bin/vyos-auto-install"
    
    # Fallback to legacy install method
    if [ -f "/opt/vyatta/sbin/install-image" ]; then
        echo "Using legacy install-image with VYATTA_PROCESS_CLIENT"
        export VYATTA_PROCESS_CLIENT='gui2_rest'
        /opt/vyatta/sbin/install-image
    else
        echo "ERROR: No installation method available"
        exit 1
    fi
fi

echo "VyOS installation finished successfully."
