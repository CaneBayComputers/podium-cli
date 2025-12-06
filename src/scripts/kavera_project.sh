#!/bin/bash

set -e

CALLER_DIR=$(pwd)

cd "$(dirname "$(realpath "$0")")"
cd ..

DEV_DIR=$(pwd)

# Run standard pre-checks (loads /etc/podium-cli/.env, validates projects dir, etc.)
source scripts/pre_check.sh

PROJECTS_DIR="$PROJECTS_DIR_PATH"

# Usage: podium kavera <site-name> [options]
if [ -z "$1" ]; then
    echo-red "Usage: podium kavera <site-name> [options]"
    echo-white "Creates a new Kavera project and prepares the agent brief."
    exit 1
fi

SITE_NAME="$1"
shift

FORWARD_ARGS=("$@")

echo-return
echo-cyan "Creating new Kavera project: $SITE_NAME"
echo-white

# Derive the final project directory name using the same normalization logic as new_project.sh
if [[ "$OSTYPE" == "darwin"* ]]; then
    PROJECT_DIR_NAME=$(echo "$SITE_NAME" | LC_ALL=C tr '[:upper:]' '[:lower:]' | LC_ALL=C tr ' ' '-' | LC_ALL=C tr -cd 'a-z0-9-_')
else
    PROJECT_DIR_NAME=$(echo "$SITE_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-_')
fi

PROJECT_PATH="$PROJECTS_DIR/$PROJECT_DIR_NAME"

if [[ "$JSON_OUTPUT" == "1" ]]; then
    # JSON mode: capture new_project JSON output and avoid running interactive commands
    NEW_PROJECT_OUTPUT="$(NEW_PROJECT_FORCE_FORK=1 "$DEV_DIR/scripts/new_project.sh" "$SITE_NAME" --framework kavera --json-output "${FORWARD_ARGS[@]}" 2>&1)"
    NEW_PROJECT_EXIT=$?

    if [ $NEW_PROJECT_EXIT -ne 0 ]; then
        echo "{\"action\": \"kavera\", \"status\": \"error\", \"message\": \"new_project failed\", \"new_project\": $NEW_PROJECT_OUTPUT}"
        exit $NEW_PROJECT_EXIT
    fi

    BRIEF_PATH="$PROJECT_PATH/storage/app/private/agent-brief.txt"
    MANIFEST_PATH="$PROJECT_PATH/storage/app/private/images/manifest.json"

    if [[ -f "$BRIEF_PATH" && -f "$MANIFEST_PATH" ]]; then
        echo "{\"action\": \"kavera\", \"status\": \"success\", \"new_project\": $NEW_PROJECT_OUTPUT}"
    else
        echo "{\"action\": \"kavera\", \"status\": \"warning\", \"message\": \"Kavera project created but agent-brief and/or images manifest are missing\", \"new_project\": $NEW_PROJECT_OUTPUT}"
    fi

    exit 0
fi

# Non-JSON (interactive) mode
NEW_PROJECT_FORCE_FORK=1 "$DEV_DIR/scripts/new_project.sh" "$SITE_NAME" --framework kavera "${FORWARD_ARGS[@]}"

if [ ! -d "$PROJECT_PATH" ]; then
    echo-yellow "Unable to locate project directory at: $PROJECT_PATH"
    echo-yellow "If you changed the project name during creation, please cd into the project manually."
    exit 0
fi

cd "$PROJECT_PATH"

echo-return
echo-cyan "Running Kavera initialization commands inside project: $PROJECT_DIR_NAME"
echo-white

# Ensure containers/services are up via setup_project; assume standard flow has already handled this

# Generate the agent brief and images manifest
art-docker app:agent-brief || echo-yellow "Warning: app:agent-brief command failed or is unavailable."
art-docker app:images-manifest || echo-yellow "Warning: app:images-manifest command failed or is unavailable."

# Launch the configured AI agent CLI, if available
if [[ "$JSON_OUTPUT" == "1" ]]; then
    echo-cyan "Skipping interactive AI agent CLI launch in JSON mode."
    echo-white "You can run your AI agent manually from the project directory."
    exit 0
fi

podium ai "$KAVERA_AGENT_INITIAL_PROMPT"
