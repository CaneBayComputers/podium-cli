#!/bin/bash

# In the Startup Applications manager enter this command to run this script to start up repos:
# gnome-terminal -- bash -c "/home/dev/repos/cbc-development-setup/startup.sh; exec bash"

set -e


# Store the current directory (should be projects directory)
PROJECTS_DIR=$(pwd)

cd "$(dirname "$(realpath "$0")")"

cd ..

DEV_DIR=$(pwd)

source scripts/functions.sh

# Env vars
source /etc/podium-cli/.env

# Return to projects directory for project operations
cd "$PROJECTS_DIR"


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

  echo; echo-cyan "Starting up $PROJECT_FOLDER_NAME ..."; echo-white

  if ! [ -d "$PROJECT_FOLDER_NAME" ]; then

    error "Project folder not found!"

  fi

  cd "$PROJECT_FOLDER_NAME"

  # Check for Podium project docker-compose.yaml
  local compose_type=$(check_docker_compose_type "docker-compose.yaml")
  
  case "$compose_type" in
      "none")
          echo-red "No docker-compose.yaml file found in $PROJECT_FOLDER_NAME!"
          echo-white "Run 'podium setup $PROJECT_FOLDER_NAME' to configure this project for Podium."
          cd ..
          return 1
          ;;
      "non-podium")
          echo-red "Found non-Podium docker-compose.yaml in $PROJECT_FOLDER_NAME!"
          echo-white "Run 'podium setup $PROJECT_FOLDER_NAME --overwrite-docker-compose' to configure for Podium."
          cd ..
          return 1
          ;;
      "podium-project")
          # Good to go - continue with startup
          ;;
  esac

  dockerup

  sleep 5

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
cd "$(get_projects_dir)"

# Start projects either just one by name or all in the projects directory
# Note: We're in the projects directory

if ! [ -z "$PROJECT_NAME" ]; then

  if start_project $PROJECT_NAME; then true; fi

else

  # Ensure we're in the projects directory before iterating
  cd "$(get_projects_dir)"
  
  for PROJECT_FOLDER_NAME in *; do

    if start_project $PROJECT_FOLDER_NAME; then true; fi

  done

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