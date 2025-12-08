#!/bin/bash

set -e

CALLER_DIR=$(pwd)

cd "$(dirname "$(realpath "$0")")"
cd ..

DEV_DIR=$(pwd)

# Run standard pre-checks (loads /etc/podium-cli/.env, validates projects dir, etc.)
source scripts/pre_check.sh

# Initialize flags
JSON_OUTPUT="${JSON_OUTPUT:-}"
NO_COLOR="${NO_COLOR:-}"

ORIGINAL_ARGS="$*"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --json-output)
            JSON_OUTPUT=1
            shift
            ;;
        --no-colors)
            NO_COLOR=1
            shift
            ;;
        --help|-h)
            echo "Usage: podium update [OPTIONS]"
            echo
            echo "Update Podium CLI and its base Docker images."
            echo
            echo "This command:"
            echo "  - Updates canebaycomputers/cbc:nginx-php8 and nginx-php7 Docker images (best-effort)."
            echo "  - Re-runs the Podium CLI install script for your platform from GitHub."
            echo
            echo "Options:"
            echo "  --json-output     Reserved for future JSON output support"
            echo "  --no-colors       Disable colored output"
            echo "  -h, --help        Show this help message"
            exit 0
            ;;
        *)
            error "Unknown option: $1. Use --help for usage information."
            ;;
    esac
done

echo-return
echo-cyan "Stopping all Podium projects and shared services before update ..."; echo-white

if command -v docker >/dev/null 2>&1; then
    if [[ -n "$PROJECTS_DIR_PATH" && -d "$PROJECTS_DIR_PATH" ]]; then
        (
            cd "$PROJECTS_DIR_PATH"
            "$DEV_DIR/scripts/shutdown.sh" || true
        )
    else
        echo-yellow "Projects directory not found; skipping shutdown."
    fi
else
    echo-yellow "Docker is not available on this system. Skipping shutdown."
fi

echo-return
echo-cyan "Updating Podium base Docker images ..."; echo-white

if ! command -v docker >/dev/null 2>&1; then
    echo-yellow "Docker is not available on this system. Skipping image updates."
else
    # Remove shared service images so they are re-pulled fresh
    COMPOSE_FILE="/etc/podium-cli/docker-compose.yaml"
    if [ -f "$COMPOSE_FILE" ]; then
        SERVICE_IMAGES=""
        RENDERED_COMPOSE=$(mktemp)
        if docker compose -f "$COMPOSE_FILE" config > "$RENDERED_COMPOSE" 2>/dev/null; then
            SOURCE_FILE="$RENDERED_COMPOSE"
        else
            SOURCE_FILE="$COMPOSE_FILE"
        fi

        SERVICE_IMAGES=$(awk '/^[[:space:]]*image:/ {print $2}' "$SOURCE_FILE" | sort -u)

        if [ -n "$SERVICE_IMAGES" ]; then
            echo-white "Removing Podium shared service images so they will be re-pulled ..."
            for image in $SERVICE_IMAGES; do
                echo-white "Removing image: $image"
                docker rmi "$image" >/dev/null 2>&1 || echo-yellow "Could not remove image: $image (it may not exist or is in use). Skipping."
            done
            echo-return
        fi

        rm -f "$RENDERED_COMPOSE"
    fi

    BASE_IMAGES=(
        "canebaycomputers/cbc:nginx-php8"
        "canebaycomputers/cbc:nginx-php7"
    )

    for image in "${BASE_IMAGES[@]}"; do
        echo-white "Pulling image: $image"
        if docker pull "$image"; then
            echo-green "Image updated (or already up to date): $image"
        else
            echo-yellow "Could not pull image: $image (it may not exist or the registry is unavailable). Skipping."
        fi
        echo-return
    done
fi

echo-return
echo-cyan "Updating Podium CLI from GitHub install script ..."; echo-white

INSTALL_SCRIPT=""

# Detect platform to choose the correct installer
if [[ "$OSTYPE" == "darwin"* ]]; then
    INSTALL_SCRIPT="install-mac.sh"
elif [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    case "$ID" in
        arch|manjaro|endeavouros)
            INSTALL_SCRIPT="install-arch.sh"
            ;;
        ubuntu|debian|linuxmint|pop)
            INSTALL_SCRIPT="install-ubuntu.sh"
            ;;
        *)
            INSTALL_SCRIPT=""
            ;;
    esac
fi

if [[ -n "$INSTALL_SCRIPT" ]]; then
    UPDATE_URL="https://raw.githubusercontent.com/CaneBayComputers/podium-cli/master/$INSTALL_SCRIPT"
    echo-white "Running remote installer: $INSTALL_SCRIPT"
    if curl -fsSL "$UPDATE_URL" | bash; then
        echo-green "Podium CLI updated via $INSTALL_SCRIPT."
    else
        echo-yellow "Failed to run remote installer: $INSTALL_SCRIPT"
        echo-yellow "Please check your network connection or run the appropriate install script manually."
    fi
else
    echo-yellow "Could not detect a supported platform (ubuntu/arch/mac) for automatic CLI update."
    echo-yellow "Please update Podium CLI manually using the install scripts from the repository."
fi

echo-return
echo-green "podium update completed."; echo-white

cd "$CALLER_DIR"
