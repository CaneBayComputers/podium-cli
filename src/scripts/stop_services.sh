#!/bin/bash

set -e

ORIG_DIR=$(pwd)

cd "$(dirname "$(realpath "$0")")"

cd ..

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
            echo-white "Stop Podium shared services"
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
# Stop CBC stack services
if check-mariadb; then

  if [[ "$JSON_OUTPUT" != "1" ]]; then
    echo-cyan "Stopping services ..."; echo-white
  fi

  cd /etc/podium-cli

  dockerdown

  cd ..

  sleep 2

else

  if [[ "$JSON_OUTPUT" != "1" ]]; then
    echo-yellow "Services are already stopped."; echo-white
  fi

fi

# JSON output for service stop
if [[ "$JSON_OUTPUT" == "1" ]]; then
    echo "{\"action\": \"stop_services\", \"status\": \"success\"}"
else
    echo-green "Services stopped!"; echo-white
fi

cd "$ORIG_DIR"
