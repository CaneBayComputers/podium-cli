#!/bin/bash

# In the Startup Applications manager enter this command to run this script to start up repos:
# gnome-terminal -- bash -c "/home/dev/repos/cbc-development-setup/startup.sh; exec bash"

set -e


# Store the current directory (should be projects directory)
PROJECTS_DIR=$(pwd)

cd "$(dirname "$(realpath "$0")")"

cd ..

DEV_DIR=$(pwd)

# Capture original arguments for debug logging
ORIGINAL_ARGS="$*"

source scripts/pre_check.sh

# Initialize debug logging
debug "Script started: startup.sh with args: $ORIGINAL_ARGS"
debug "PROJECTS_DIR: $PROJECTS_DIR"

# Return to projects directory for project operations
cd "$PROJECTS_DIR"
debug "Changed to projects directory: $(pwd)"


# Initialize variables
PROJECT_NAME=""
JSON_OUTPUT="${JSON_OUTPUT:-}"
NO_COLOR="${NO_COLOR:-}"

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
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
            echo-white "Usage: $0 [OPTIONS] [project_name]"
            echo-white "Start project containers or all projects"
            echo-white ""
            echo-white "Arguments:"
            echo-white "  project_name      Optional: Specific project to start"
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
start_project() {

  PROJECT_FOLDER_NAME=$1
  debug "start_project called for: $PROJECT_FOLDER_NAME"

  echo-return; echo-cyan "Starting up $PROJECT_FOLDER_NAME ...";

  if ! [ -d "$PROJECT_FOLDER_NAME" ]; then
    debug "Project folder not found: $PROJECT_FOLDER_NAME"
    error "Project folder not found!"

  fi

  debug "Changing to project directory: $PROJECT_FOLDER_NAME"
  cd "$PROJECT_FOLDER_NAME"
  debug "Current directory: $(pwd)"

  # Check for Podium project docker-compose.yaml
  debug "Checking docker-compose.yaml type"
  local compose_type=$(check_docker_compose_type "docker-compose.yaml")
  debug "Docker compose type: $compose_type"
  
  case "$compose_type" in
      "none")
          echo-white "Run 'podium setup $PROJECT_FOLDER_NAME' to configure this project for Podium."
          echo-yellow "$PROJECT_FOLDER_NAME is not configured for Podium. Run: podium setup $PROJECT_FOLDER_NAME"
          cd ..
          return 1
          ;;
      "non-podium")
          echo-white "Run 'podium setup $PROJECT_FOLDER_NAME --overwrite-docker-compose' to configure for Podium."
          echo-yellow "$PROJECT_FOLDER_NAME has non-Podium docker-compose.yaml. Run: podium setup $PROJECT_FOLDER_NAME --overwrite-docker-compose"
          cd ..
          return 1
          ;;
      "podium-project")
          # Good to go - continue with startup
          ;;
  esac

  dockerup

  cd ..

  echo-green "Project $PROJECT_FOLDER_NAME started successfully!"; echo-return
}


# Main
# Build start_services options
START_SERVICES_OPTIONS=""
if [[ "$JSON_OUTPUT" == "1" ]]; then
    START_SERVICES_OPTIONS="$START_SERVICES_OPTIONS --json-output"
fi
if [[ "$NO_COLOR" == "1" ]]; then
    START_SERVICES_OPTIONS="$START_SERVICES_OPTIONS --no-colors"
fi
if [[ "$DEBUG" == "1" ]]; then
    START_SERVICES_OPTIONS="$START_SERVICES_OPTIONS --debug"
fi

# Capture JSON output from start_services.sh if in JSON mode
if [[ "$JSON_OUTPUT" == "1" ]]; then
    START_SERVICES_OUTPUT=$(source "$DEV_DIR/scripts/start_services.sh" $START_SERVICES_OPTIONS 2>&1)
    START_SERVICES_EXIT_CODE=$?
    if [ $START_SERVICES_EXIT_CODE -ne 0 ]; then
        echo "$START_SERVICES_OUTPUT"
        exit $START_SERVICES_EXIT_CODE
    fi
else
    source "$DEV_DIR/scripts/start_services.sh" $START_SERVICES_OPTIONS
fi

# Ensure we're back in the projects directory after sourcing other scripts
cd "$PROJECTS_DIR_PATH"

# Start projects either just one by name or all in the projects directory
# Note: We're in the projects directory

if ! [ -z "$PROJECT_NAME" ]; then
    debug "Starting specific project: $PROJECT_NAME"
    if start_project $PROJECT_NAME; then true; fi

else
    debug "Starting all projects"
  
    # Only iterate directories; avoid literal '*' / '*/' with nullglob
    shopt -s nullglob

    for PROJECT_FOLDER_NAME in */ ; do
        PROJECT_FOLDER_NAME=${PROJECT_FOLDER_NAME%/}

        debug "Attempting to start project: $PROJECT_FOLDER_NAME"
        start_project "$PROJECT_FOLDER_NAME" || true

    done

    shopt -u nullglob

fi


# Docker handles all networking automatically

# Build status options
STATUS_OPTIONS=""
if [[ "$JSON_OUTPUT" == "1" ]]; then
    STATUS_OPTIONS="$STATUS_OPTIONS --json-output"
fi
if [[ "$NO_COLOR" == "1" ]]; then
    STATUS_OPTIONS="$STATUS_OPTIONS --no-colors"
fi

# Show status to confirm successful startup
if [ -n "$PROJECT_NAME" ]; then
    source "$DEV_DIR/scripts/status.sh" $PROJECT_NAME $STATUS_OPTIONS
else
    source "$DEV_DIR/scripts/status.sh" $STATUS_OPTIONS
fi