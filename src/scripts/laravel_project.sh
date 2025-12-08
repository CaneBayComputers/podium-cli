#!/bin/bash

set -e


CALLER_DIR=$(pwd)

cd "$(dirname "$(realpath "$0")")"
cd ..

DEV_DIR=$(pwd)

# Run standard pre-checks (loads /etc/podium-cli/.env, validates projects dir, etc.)
source scripts/pre_check.sh

PROJECTS_DIR="$PROJECTS_DIR_PATH"

# Usage: podium laravel <site-name> [options]
if [ -z "$1" ]; then
    echo-red "Usage: podium laravel <site-name> [options]"
    echo-white "Creates a new Laravel project from the laravel/laravel GitHub repository using a GitHub fork."
    exit 1
fi

SITE_NAME="$1"
shift

FORWARD_ARGS=("$@")

echo-return
echo-cyan "Creating new Laravel project: $SITE_NAME"
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
    NEW_PROJECT_OUTPUT="$(NEW_PROJECT_FORCE_FORK=1 "$DEV_DIR/scripts/new_project.sh" "$SITE_NAME" --framework laravel --json-output "${FORWARD_ARGS[@]}" 2>&1)"
    NEW_PROJECT_EXIT=$?

    if [ $NEW_PROJECT_EXIT -ne 0 ]; then
        echo "{\"action\": \"laravel\", \"status\": \"error\", \"message\": \"new_project failed\", \"new_project\": $NEW_PROJECT_OUTPUT}"
        exit $NEW_PROJECT_EXIT
    fi

    echo "{\"action\": \"laravel\", \"status\": \"success\", \"new_project\": $NEW_PROJECT_OUTPUT}"
    exit 0
fi

# Non-JSON (interactive) mode
NEW_PROJECT_FORCE_FORK=1 "$DEV_DIR/scripts/new_project.sh" "$SITE_NAME" --framework laravel "${FORWARD_ARGS[@]}"

cd "$CALLER_DIR"

