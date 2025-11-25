#!/bin/bash

set -e

ORIG_DIR=$(pwd)

cd "$(dirname "$(realpath "$0")")"
cd ..

DEV_DIR=$(pwd)

source scripts/functions.sh

PROJECTS_DIR="$(get_projects_dir)"

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

# Run the standard new_project flow with the Kavera framework
"$DEV_DIR/scripts/new_project.sh" "$SITE_NAME" --framework kavera "${FORWARD_ARGS[@]}"

# Derive the final project directory name using the same normalization logic
if [[ "$OSTYPE" == "darwin"* ]]; then
    PROJECT_DIR_NAME=$(echo "$SITE_NAME" | LC_ALL=C tr '[:upper:]' '[:lower:]' | LC_ALL=C tr ' ' '-' | LC_ALL=C tr -cd 'a-z0-9-_')
else
    PROJECT_DIR_NAME=$(echo "$SITE_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-_')
fi

PROJECT_PATH="$PROJECTS_DIR/$PROJECT_DIR_NAME"

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

KAVERA_PROMPT="$KAVERA_AGENT_INITIAL_PROMPT"
if [[ -z "$KAVERA_PROMPT" ]]; then
    KAVERA_PROMPT="Build a unique website for this project by following the instructions found in storage/app/private/agent-brief.txt (project brief) and AGENTS.md (project rules). Use them as a source of truth when deciding what pages to create, how they should look, and how to handle images, forms, and JSON-LD."
    echo-yellow "KAVERA_AGENT_INITIAL_PROMPT is not set in /etc/podium-cli/.env; using built-in default prompt (not saved to config)."
    echo-white
fi

echo-cyan "Launching AI agent for this project using 'podium ai'..."
echo-white
podium ai "$KAVERA_PROMPT"
