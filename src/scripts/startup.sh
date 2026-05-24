#!/bin/bash

# In the Startup Applications manager enter this command to run this script to start up repos:
# gnome-terminal -- bash -c "/home/dev/repos/cbc-development-setup/startup.sh; exec bash"

set -e


# Store the current directory (should be projects directory)
PROJECTS_DIR=$(pwd)

cd "$(cd "$(dirname "$0")" 2>/dev/null && pwd -P)"

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
START_ALL=0
JSON_OUTPUT="${JSON_OUTPUT:-}"
NO_COLOR="${NO_COLOR:-}"

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --all)
            START_ALL=1
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
        --debug)
            DEBUG=1
            shift
            ;;
        --help)
            echo-white "Usage: $0 [OPTIONS] [project_name]"
            echo-white "Start project containers (and shared services if not running)"
            echo-white ""
            echo-white "Arguments:"
            echo-white "  project_name      Optional: specific project to start"
            echo-white ""
            echo-white "Options:"
            echo-white "  --all             Start every project in the projects directory"
            echo-white "  --json-output     Output results in JSON format"
            echo-white "  --no-colors       Disable colored output"
            echo-white "  --debug           Enable debug logging to /tmp/podium-cli-debug.log"
            echo-white "  --help            Show this help message"
            echo-white ""
            echo-white "With no arguments, shows an interactive picker. Shared services always"
            echo-white "start regardless of which mode is selected."
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

if [[ "$START_ALL" == "1" && -n "$PROJECT_NAME" ]]; then
    error "Cannot combine --all with a project name."
fi


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

# If no project name and no --all flag and not JSON mode, prompt the user
# to pick a project from a numbered list (services have already been started).
# JSON mode without explicit --all/project falls through to "all projects" for
# backward compatibility with automation that relied on the old default.
if [[ -z "$PROJECT_NAME" && "$START_ALL" == "0" && "$JSON_OUTPUT" != "1" ]]; then
    if [[ ! -t 0 ]]; then
        echo-red "No project specified and not running in an interactive terminal."
        echo-white "Pass a project name (e.g. 'podium up <project>') or '--all' to start every project."
        exit 1
    fi

    mapfile -t PROJECTS < <(find "$PROJECTS_DIR_PATH" -maxdepth 1 -mindepth 1 -type d ! -name '.*' -printf '%f\n' | sort)

    if [[ ${#PROJECTS[@]} -eq 0 ]]; then
        echo-yellow "No projects found in $PROJECTS_DIR_PATH."
        echo-white "Shared services have been started. Create a project with 'podium new', 'podium clone', or 'podium install <app>'."
    else
        echo-return
        echo-cyan "Select a project to start:"
        echo-return

        COLS=$(tput cols 2>/dev/null || echo 80)
        if command -v column >/dev/null 2>&1; then
            for i in "${!PROJECTS[@]}"; do
                printf "%3d) %s\n" "$((i + 1))" "${PROJECTS[$i]}"
            done | column -c "$COLS"
        else
            for i in "${!PROJECTS[@]}"; do
                printf "  %3d) %s\n" "$((i + 1))" "${PROJECTS[$i]}"
            done
        fi

        echo-return
        echo-yellow -n "Enter number or project name (Ctrl+C to cancel, or --all on the command line to start every project): "
        echo-white -ne
        read -r SELECTION
        echo-return

        if [[ -z "$SELECTION" ]]; then
            echo-yellow "No selection made. Aborting."
            exit 1
        fi

        if [[ "$SELECTION" =~ ^[0-9]+$ ]]; then
            if (( SELECTION < 1 || SELECTION > ${#PROJECTS[@]} )); then
                echo-red "Invalid selection: $SELECTION (valid range: 1-${#PROJECTS[@]})"
                exit 1
            fi
            PROJECT_NAME="${PROJECTS[$((SELECTION - 1))]}"
        else
            PROJECT_NAME="$SELECTION"
        fi
    fi
fi

# Decide which projects to start.
# Note: shared services have already been started above regardless of branch.
if [[ -n "$PROJECT_NAME" ]]; then
    debug "Starting specific project: $PROJECT_NAME"
    if start_project "$PROJECT_NAME"; then true; fi

elif [[ "$START_ALL" == "1" || "$JSON_OUTPUT" == "1" ]]; then
    debug "Starting all projects (START_ALL=$START_ALL JSON_OUTPUT=$JSON_OUTPUT)"

    # Only iterate directories; avoid literal '*' / '*/' with nullglob.
    # Skip files and any directory whose name starts with a dot.
    shopt -s nullglob

    for PROJECT_FOLDER_NAME in */ ; do
        PROJECT_FOLDER_NAME=${PROJECT_FOLDER_NAME%/}

        # Skip non-directories and hidden directories
        [[ -d "$PROJECT_FOLDER_NAME" ]] || continue
        [[ "$PROJECT_FOLDER_NAME" == .* ]] && continue

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

# Allow containers time to finish booting before running status checks
sleep 12

# Show status to confirm successful startup
if [ -n "$PROJECT_NAME" ]; then
    source "$DEV_DIR/scripts/status.sh" $PROJECT_NAME $STATUS_OPTIONS
else
    source "$DEV_DIR/scripts/status.sh" $STATUS_OPTIONS
fi
