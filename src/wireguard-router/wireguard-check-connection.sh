#!/bin/bash

CONFIG_FILE="/etc/check-connection/config.conf"

if [ ! -f $CONFIG_FILE ]; then
  echo "Configuration file not found: $CONFIG_FILE"
  exit 1
fi

# Source the configuration file
source $CONFIG_FILE

if [ -z "$TARGET_IP" ]; then
  echo "TARGET_IP variable is not set."
  exit 1
fi

# Ping ip address
if ping -c 1 -W 1 "$TARGET_IP" >/dev/null 2>&1; then
  echo "IP address $TARGET_IP is reachable."
  exit 0
else
  echo "IP address $TARGET_IP is not reachable."
  exit 1
fi
