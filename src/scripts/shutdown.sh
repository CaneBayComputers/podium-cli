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

source scripts/pre_check.sh

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
        --debug)
            DEBUG=1
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
            echo-white "  --debug           Enable debug logging to /tmp/podium-cli-debug.log"
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

# Initialize debug logging
debug "Script started: shutdown.sh with args: $*"


# Functions
# Docker handles all networking - no iptables rules needed

shutdown_project() {
    local PROJECT_NAME="$1"
    local PROJECT_FOLDER="$2"
    
    # Check if project folder exists
    if [ ! -d "$PROJECT_FOLDER" ]; then
        error "Project folder does not exist: $PROJECT_FOLDER"
    fi
    
    # Check for docker-compose.yaml file
    COMPOSE_FILE="$PROJECT_FOLDER/docker-compose.yaml"
    
    if [ ! -f "$COMPOSE_FILE" ]; then
        echo-return; echo-yellow "No docker-compose.yaml found in project: $PROJECT_NAME"
        return 1
    fi
    
    # Check if it's a Podium project
    COMPOSE_TYPE=$(check_docker_compose_type "$COMPOSE_FILE")
    
    if [ "$COMPOSE_TYPE" != "podium-project" ]; then
        echo-return; echo-yellow "Project $PROJECT_NAME is not a Podium project"
        return 1
    fi
    
    # Check if container is running and shut it down
    if [ "$(docker ps -q -f name=$PROJECT_NAME)" ]; then
        echo-return; echo-cyan "Shutting down $PROJECT_NAME ..."; echo-white; echo-return
        
        # Save current directory to return to it after dockerdown
        CURRENT_DIR=$(pwd)
        cd "$PROJECT_FOLDER"
        dockerdown
        cd "$CURRENT_DIR"
        
        echo-green "Successfully shut down $PROJECT_NAME!"; echo-white; echo-return
        
        divider
        return 0
    else
        echo-return; echo-yellow "Container $PROJECT_NAME is not running!"; echo-white; echo-return
        return 1
    fi
}



#######################################################
# Main
#######################################################

# Shut down Docker containers
if [ -z "$PROJECT_NAME" ]; then

    # Iterate through each folder in the projects directory (PROJECTS_DIR_PATH set by pre_check)
    for PROJECT_FOLDER in "$PROJECTS_DIR_PATH"/*; do
        
        # Skip if not a directory
        if [ ! -d "$PROJECT_FOLDER" ]; then
            continue
        fi
        
        # Get the project name (folder name)
        PROJECT_FOLDER_NAME=$(basename "$PROJECT_FOLDER")
        
        # Use the reusable shutdown function (but don't exit on errors in loop)
        shutdown_project "$PROJECT_FOLDER_NAME" "$PROJECT_FOLDER" || true
    done

    # Stop services using the dedicated script and capture output if needed
    if [[ "$JSON_OUTPUT" == "1" ]]; then
        STOP_SERVICES_OUTPUT=$(source "$DEV_DIR/scripts/stop_services.sh" 2>&1)
    else
        source "$DEV_DIR/scripts/stop_services.sh"
    fi

else
    # Shutdown specific project (PROJECTS_DIR_PATH set by pre_check)
    PROJECT_FOLDER="$PROJECTS_DIR_PATH/$PROJECT_NAME"
    
    # Use the reusable shutdown function
    shutdown_project "$PROJECT_NAME" "$PROJECT_FOLDER"

fi

# Final output
if [[ "$JSON_OUTPUT" == "1" ]]; then

    # JSON output for shutdown
    if [ -n "$PROJECT_NAME" ]; then

        echo "{\"action\": \"shutdown\", \"target\": \"project\", \"project_name\": \"$PROJECT_NAME\", \"status\": \"success\"}"

    else
        # Include services output if captured
        if [ -n "$STOP_SERVICES_OUTPUT" ]; then
            echo "{\"action\": \"shutdown\", \"target\": \"all_projects\", \"status\": \"success\", \"services_result\": $STOP_SERVICES_OUTPUT}"
        else
            echo "{\"action\": \"shutdown\", \"target\": \"all_projects\", \"status\": \"success\"}"
        fi

    fi

else
    echo-return; echo-green "Docker containers shut down successfully!"; echo-white; echo-return
fi

