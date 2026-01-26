#!/bin/bash

CONFIG_FILE="/etc/checkdns/checkdns.conf"

if [ ! -f $CONFIG_FILE ]; then
    echo "Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Source the configuration file
source $CONFIG_FILE

if [ -z "$DNS_SERVER" ]; then
    echo "DNS_SERVER variable is not set."
    exit 1
fi

if [ -z "$IP_FILE" ]; then
    echo "IP_FILE variable is not set."
    exit 1
fi

if [ -z "$DOMAIN" ]; then
    echo "DOMAIN variable is not set."
    exit 1
fi

CURRENT_IP=$(dig +short @$DNS_SERVER $DOMAIN)

# Try to resolve the domain
if [ -z "$CURRENT_IP" ]; then
    echo "Failed to resolve $DOMAIN"
    exit 1
fi

# Check if the IP file exists
if [ ! -f $IP_FILE ]; then
    echo "No IP file found, creating one..."
    echo "$CURRENT_IP" > $IP_FILE
    exit 0
fi

# Get the last known IP
LAST_IP=$(cat $IP_FILE)

# Compare the current IP with the last known IP
if [ "$CURRENT_IP" != "$LAST_IP" ]; then
    echo "Detected IP change, updating the WireGuard configuration..."
    echo "$CURRENT_IP" > $IP_FILE

    # Restart the wireshark service
    echo "Restarting WireGuard connection..."
    systemctl restart wg-quick@wg0.service
fi
