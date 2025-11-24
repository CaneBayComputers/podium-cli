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

source scripts/pre_check.sh

# Initialize variables
JSON_OUTPUT="${JSON_OUTPUT:-}"
NO_COLOR="${NO_COLOR:-}"

# Capture original arguments for debug logging
ORIGINAL_ARGS="$*"

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
        --debug)
            DEBUG=1
            shift
            ;;
        --help)
            echo-white "Usage: $0 [OPTIONS]"
            echo-white "Start Podium shared services"
            echo-white ""
            echo-white "Options:"
            echo-white "  --json-output     Output results in JSON format"
            echo-white "  --no-colors       Disable colored output"
            echo-white "  --debug           Enable debug logging to /tmp/podium-cli-debug.log"
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

echo-return; echo-return

# Initialize debug logging
debug "Script started: start_services.sh with args: $ORIGINAL_ARGS"

# Main
source "$DEV_DIR/scripts/pre_check.sh"

# Migrate legacy service volumes to new podium_* names (one-time, best-effort)
migrate_volume_if_needed() {
    local old_name="$1"
    local new_name="$2"
    
    if ! command -v docker >/dev/null 2>&1; then
        return
    fi
    
    # If new volume already exists, nothing to do
    if docker volume inspect "$new_name" >/dev/null 2>&1; then
        return
    fi
    
    # If old volume does not exist, nothing to migrate
    if ! docker volume inspect "$old_name" >/dev/null 2>&1; then
        return
    fi
    
    echo-cyan "Migrating Docker volume '$old_name' to '$new_name' ..."; echo-white
    
    # Create new volume
    docker volume create "$new_name" >/dev/null
    
    # Copy data using a temporary container
    docker run --rm -v "$old_name":/from -v "$new_name":/to alpine sh -c "cp -a /from/. /to/" >/dev/null 2>&1 || true
}

# Attempt migrations for known service volumes (compose project is 'podium-cli')
SERVICE_STACK="podium-cli"
migrate_volume_if_needed "${SERVICE_STACK}_mysql_data" "${SERVICE_STACK}_podium_mysql_data"
migrate_volume_if_needed "${SERVICE_STACK}_redis_data" "${SERVICE_STACK}_podium_redis_data"
migrate_volume_if_needed "${SERVICE_STACK}_mongo_data" "${SERVICE_STACK}_podium_mongo_data"
migrate_volume_if_needed "${SERVICE_STACK}_postgres_data" "${SERVICE_STACK}_podium_postgres_data"


# Start CBC stack
if ! check-mariadb; then

    echo-cyan "Starting services ..."; echo-white

    cd /etc/podium-cli

    dockerup

    cd "$DEV_DIR"

fi

# JSON output for service start
if [[ "$JSON_OUTPUT" == "1" ]]; then
    echo "{\"action\": \"start_services\", \"status\": \"success\"}"
else
    echo-green "Services are running!"; echo-white
fi

cd "$ORIG_DIR"
