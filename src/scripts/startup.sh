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
NO_STATUS=false
PROJECT_NAME=""
JSON_OUTPUT="${JSON_OUTPUT:-}"
NO_COLOR="${NO_COLOR:-}"

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --no-status) 
            NO_STATUS=true 
            shift
            ;;
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
            echo-white "  --no-status       Skip status display after startup"
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

  if [[ "$JSON_OUTPUT" != "1" ]]; then
      echo; echo-cyan "Starting up $PROJECT_FOLDER_NAME ..."; echo-white
  fi

  if ! [ -d "$PROJECT_FOLDER_NAME" ]; then

    error "Project folder not found!"

  fi

  cd "$PROJECT_FOLDER_NAME"

  # Check docker-compose.yaml and handle intelligently - run setup if needed
  if ! handle_docker_compose_conflict "docker-compose.yaml" "startup"; then
      # If conflict handling failed (user said no), skip this project
      if [[ "$JSON_OUTPUT" == "1" ]]; then
          echo "{\"action\": \"startup\", \"project_name\": \"$PROJECT_FOLDER_NAME\", \"status\": \"error\", \"error\": \"docker_compose_conflict\"}"
      else
          echo-white "Skipping $PROJECT_FOLDER_NAME due to Docker configuration conflict"
      fi
      cd ..
      return 1
  fi
  
  # If no docker-compose.yaml exists or user agreed to overwrite, run setup
  local compose_type=$(check_docker_compose_type "docker-compose.yaml")
  if [[ "$compose_type" == "none" ]] || [[ "$OVERWRITE_DOCKER_COMPOSE" == "1" && "$compose_type" == "non-podium" ]]; then
      if [[ "$JSON_OUTPUT" == "1" ]]; then
          echo "{\"action\": \"startup\", \"project_name\": \"$PROJECT_FOLDER_NAME\", \"status\": \"info\", \"message\": \"running_setup\"}"
      else
          echo-cyan "Setting up $PROJECT_FOLDER_NAME for Podium..."
      fi
      
      # Build setup options
      SETUP_OPTIONS="$PROJECT_FOLDER_NAME"
      if [[ "$JSON_OUTPUT" == "1" ]]; then
          SETUP_OPTIONS="$SETUP_OPTIONS --json-output"
      fi
      if [[ "$NO_COLOR" == "1" ]]; then
          SETUP_OPTIONS="$SETUP_OPTIONS --no-colors"
      fi
      if [[ "$OVERWRITE_DOCKER_COMPOSE" == "1" ]]; then
          SETUP_OPTIONS="$SETUP_OPTIONS --overwrite-docker-compose"
      fi
      
      # Run setup from the project directory
      cd ..
      if ! source "$DEV_DIR/scripts/setup_project.sh" $SETUP_OPTIONS; then
          if [[ "$JSON_OUTPUT" == "1" ]]; then
              echo "{\"action\": \"startup\", \"project_name\": \"$PROJECT_FOLDER_NAME\", \"status\": \"error\", \"error\": \"setup_failed\"}"
          else
              echo-red "Setup failed for $PROJECT_FOLDER_NAME"
          fi
          return 1
      fi
      cd "$PROJECT_FOLDER_NAME"
      
      if [[ "$JSON_OUTPUT" != "1" ]]; then
          echo-green "Setup completed for $PROJECT_FOLDER_NAME, now starting..."
      fi
  fi

  dockerup

  sleep 5

  cd ..

  if [[ "$JSON_OUTPUT" != "1" ]]; then
      echo-green "Project $PROJECT_FOLDER_NAME started successfully!"
  fi
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

source "$DEV_DIR/scripts/start_services.sh" $START_SERVICES_OPTIONS

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

if ! $NO_STATUS; then
  if [ -n "$PROJECT_NAME" ]; then
      source "$DEV_DIR/scripts/status.sh" $PROJECT_NAME $STATUS_OPTIONS
  else
      source "$DEV_DIR/scripts/status.sh" $STATUS_OPTIONS
  fi
elif [[ "$JSON_OUTPUT" == "1" ]]; then
  # For JSON output, we still need to call status.sh to get the data
  if [ -n "$PROJECT_NAME" ]; then
      source "$DEV_DIR/scripts/status.sh" $PROJECT_NAME $STATUS_OPTIONS
  else
      source "$DEV_DIR/scripts/status.sh" $STATUS_OPTIONS
  fi
fi