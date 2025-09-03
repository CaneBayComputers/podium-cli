#!/bin/bash

set -e


ORIG_DIR=$(pwd)

# Get the directory of this script, handling both direct execution and sourcing
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Script is being sourced
    SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
else
    # Script is being executed directly
    SCRIPT_DIR="$(dirname "$(realpath "$0")")"
fi

cd "$SCRIPT_DIR/.."

DEV_DIR=$(pwd)

source scripts/functions.sh

# Do not run as root
if [[ "$(whoami)" == "root" ]]; then
  error "Do NOT run with sudo!"
fi


# Check if this environment is configured
if ! [ -f /etc/podium-cli/.env ]; then
  error "Development environment has not been configured! Run: podium configure" 0
fi

cd "$ORIG_DIR"