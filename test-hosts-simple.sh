#!/bin/bash

# Simple test for container name extraction and hosts file loop
set -e

echo "🧪 Testing Container Name Extraction and Hosts Loop"
echo "=================================================="

# Prefill compose file path
COMPOSE_FILE="/etc/podium-cli/docker-compose.yaml"
HOSTS_FILE="/etc/hosts"
REMOVED_HOSTS=0

echo "Compose file: $COMPOSE_FILE"
echo "Hosts file: $HOSTS_FILE"
echo

# Extract container names (same logic as uninstall.sh)
echo "🔍 Extracting container names from compose file:"
echo "Container name lines found:"
grep -E "^\s*container_name:" "$COMPOSE_FILE" || echo "  None found"

CONTAINER_NAMES=$(grep -E "^\s*container_name:" "$COMPOSE_FILE" | sed 's/.*container_name:\s*\([^[:space:]]*\).*/\1/' | tr '\n' ' ')

echo
echo "Extracted container names: '$CONTAINER_NAMES'"
echo

# Test the loop logic
if [ -n "$CONTAINER_NAMES" ]; then
    for container_name in $CONTAINER_NAMES; do
        echo "Testing container: '$container_name'"
        
        # Check if container name exists in hosts file
        if grep -q "${container_name}" "$HOSTS_FILE"; then
            echo "  ✅ Found '$container_name' in hosts file"
            echo "  Matching lines:"
            grep -n "${container_name}" "$HOSTS_FILE" | sed 's/^/    /'
            
            echo "  Would run command:"
            if [[ "$OSTYPE" == "darwin"* ]]; then
                echo "    macOS temp file approach:"
                echo "    sudo grep -v \"${container_name}\" \"$HOSTS_FILE\" > /tmp/podium_hosts_tmp"
                echo "    sudo mv /tmp/podium_hosts_tmp \"$HOSTS_FILE\""
                echo "    sudo chmod 644 \"$HOSTS_FILE\""
                echo "    sudo chown root:wheel \"$HOSTS_FILE\""
            else
                echo "    sudo sed -i \"/${container_name}/d\" \"$HOSTS_FILE\""
            fi
            ((REMOVED_HOSTS++))
        else
            echo "  ❌ '$container_name' NOT found in hosts file"
        fi
        echo
    done
else
    echo "❌ No container names found"
fi

echo "Summary: Would remove $REMOVED_HOSTS hosts file entries"
