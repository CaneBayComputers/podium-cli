#!/bin/bash

set -e

# Store current working directory (should be projects directory)
PROJECTS_DIR=$(pwd)

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

# Return to projects directory
cd "$PROJECTS_DIR"

echo-return; echo-return


# Initialize variables
PROJECT_NAME=""
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
            echo-white "Usage: $0 [OPTIONS] [project_name]"
            echo-white "Shutdown project containers or all projects"
            echo-white ""
            echo-white "Arguments:"
            echo-white "  project_name      Optional: Specific project to shutdown"
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
            if [ -z "$PROJECT_NAME" ]; then
                PROJECT_NAME="$1"
            else
                error "Too many arguments"
            fi
            shift
            ;;
    esac
done


# Functions
# Docker handles all networking - no iptables rules needed

shutdown_container() {

        CONTAINER_NAME=$1

        REPO_DIR=$CONTAINER_NAME;

  if [ -d "$REPO_DIR" ]; then

  	if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then

	  	echo-return; echo-cyan "Shutting down $CONTAINER_NAME ..."; echo-white; echo

	  	cd "$REPO_DIR"

	  	dockerdown

	  	echo-green "Successfully shut down $CONTAINER_NAME!"; echo-white; echo

	  	cd ../..

	  else

	  	echo-return; echo-yellow "Container $CONTAINER_NAME is not running!"; echo-white; echo

	  fi

  	divider

  fi
}


#######################################################
# Main
#######################################################


# Define the comment to search for
CUSTOM_COMMENT="cbc-rule"

if [ -n "$PROJECT_NAME" ]; then

	CUSTOM_COMMENT="${CUSTOM_COMMENT}-${PROJECT_NAME}"

fi


# Docker handles all networking automatically - no iptables cleanup needed

# Shut down Docker containers
if [ -z "$PROJECT_NAME" ]; then

	for CONTAINER_ID in $(docker ps -q); do

	    CONTAINER_NAME=$(docker inspect --format='{{.Name}}' $CONTAINER_ID | sed 's/^\/\+//')

	    shutdown_container $CONTAINER_NAME;

	done

	        if check-mariadb; then

                echo-return; echo-cyan "Shutting down services ..."; echo-white; echo

                cd "$DEV_DIR/docker-stack"

          dockerdown

          echo-green "Successfully shut down services!"; echo-white; echo

          cd "$PROJECTS_DIR"

        fi

else

        shutdown_container $PROJECT_NAME

fi

# Final output
if [[ "$JSON_OUTPUT" == "1" && "$SUPPRESS_INTERMEDIATE_JSON" != "1" ]]; then
    # JSON output for shutdown
    if [ -n "$PROJECT_NAME" ]; then
        echo "{\"action\": \"shutdown\", \"target\": \"project\", \"project_name\": \"$PROJECT_NAME\", \"status\": \"success\"}"
    else
        echo "{\"action\": \"shutdown\", \"target\": \"all_projects\", \"status\": \"success\"}"
    fi
elif [[ "$JSON_OUTPUT" != "1" ]]; then
    echo-return; echo-green "Docker containers shut down successfully!"; echo-white; echo
fi

