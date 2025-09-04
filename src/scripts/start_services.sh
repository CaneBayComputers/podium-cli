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

# Initialize variables
JSON_OUTPUT="${JSON_OUTPUT:-}"
NO_COLOR="${NO_COLOR:-}"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --json-output)
            JSON_OUTPUT=1
            shift
            ;;
        --no-colors)
            NO_COLOR=1
            shift
            ;;
        --help)
            echo-white "Usage: $0 [OPTIONS]"
            echo-white "Start Podium shared services"
            echo-white ""
            echo-white "Options:"
            echo-white "  --json-output     Output results in JSON format"
            echo-white "  --no-colors       Disable colored output"
            echo-white "  --help            Show this help message"
            exit 0
            ;;
        -*)
            error "Unknown option: $1. Use --help for usage information"
            ;;
        *)
            error "Unexpected argument: $1. Use --help for usage information"
            ;;
    esac
done

if [[ "$JSON_OUTPUT" != "1" ]]; then
    echo-return; echo-return
fi

# Main
source "$DEV_DIR/scripts/pre_check.sh"


# Start CBC stack
if ! check-mariadb; then

  if [[ "$JSON_OUTPUT" != "1" ]]; then
    echo-cyan "Starting services ..."; echo-white
  fi

  cd /etc/podium-cli

  dockerup

  cd "$DEV_DIR"

  sleep 5

fi

# JSON output for service start
if [[ "$JSON_OUTPUT" == "1" && "$SUPPRESS_INTERMEDIATE_JSON" != "1" ]]; then
    echo "{\"action\": \"start_services\", \"status\": \"success\"}"
elif [[ "$JSON_OUTPUT" != "1" ]]; then
    echo-green "Services are running!"; echo-white
fi

cd "$ORIG_DIR"