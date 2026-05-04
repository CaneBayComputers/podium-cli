#!/bin/bash

set -e

CALLER_DIR=$(pwd)

cd "$(cd "$(dirname "$0")" 2>/dev/null && pwd -P)"
cd ..

DEV_DIR=$(pwd)

# Run standard pre-checks (loads /etc/podium-cli/.env, validates projects dir, etc.)
source scripts/pre_check.sh

# Initialize flags
JSON_OUTPUT="${JSON_OUTPUT:-}"
NO_COLOR="${NO_COLOR:-}"
FULL_UPDATE=0

ORIGINAL_ARGS="$*"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --full)
            FULL_UPDATE=1
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
        --help|-h)
            echo "Usage: podium update [OPTIONS]"
            echo
            echo "Update Podium CLI from GitHub."
            echo
            echo "By default this only does a 'git pull' on the Podium CLI install"
            echo "directory — no system packages are updated, no Docker images are"
            echo "touched, and running projects keep going."
            echo
            echo "Pass --full to also run the platform install script (apt-get update,"
            echo "Docker / dependency refresh) and remove/re-pull the Podium shared"
            echo "service and base Docker images. This will stop running projects."
            echo
            echo "Options:"
            echo "  --full            Run platform installer and re-pull Docker images"
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

if [[ "$FULL_UPDATE" == "1" ]]; then
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
            "canebaycomputers/cbc:nginx-node"
            "canebaycomputers/cbc:nginx-python3"
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
fi

if [[ "$FULL_UPDATE" == "1" ]]; then
    echo-return
    echo-cyan "Running platform install script ..."; echo-white

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
        # cd to /tmp before running the installer — it removes and re-clones /usr/local/share/podium-cli,
        # which would invalidate the CWD if we stayed inside it.
        if cd /tmp && curl -fsSL "$UPDATE_URL" | bash; then
            echo-green "Podium CLI updated via $INSTALL_SCRIPT."
        else
            echo-yellow "Failed to run remote installer: $INSTALL_SCRIPT"
            echo-yellow "Please check your network connection or run the appropriate install script manually."
        fi
    else
        echo-yellow "Could not detect a supported platform (ubuntu/arch/mac) for automatic CLI update."
        echo-yellow "Please update Podium CLI manually using the install scripts from the repository."
    fi
else
    echo-return
    echo-cyan "Pulling latest Podium CLI from GitHub ..."; echo-white

    # DEV_DIR is .../podium-cli/src — the install dir is its parent.
    INSTALL_DIR="$(dirname "$DEV_DIR")"

    if [[ ! -d "$INSTALL_DIR/.git" ]]; then
        echo-yellow "Podium CLI install dir is not a git checkout: $INSTALL_DIR"
        echo-yellow "Run 'podium update --full' to reinstall via the platform installer."
    else
        # Use sudo if the checkout isn't writable by the current user
        if [[ -w "$INSTALL_DIR/.git" ]]; then
            GIT_PULL=(git -C "$INSTALL_DIR" pull --ff-only)
        else
            GIT_PULL=(sudo git -C "$INSTALL_DIR" pull --ff-only)
        fi

        if "${GIT_PULL[@]}"; then
            echo-green "Podium CLI code updated."
        else
            echo-yellow "git pull failed in $INSTALL_DIR."
            echo-yellow "If the working tree has local changes or has diverged, resolve them"
            echo-yellow "or run 'podium update --full' to reinstall from scratch."
        fi
    fi
fi

echo-return
echo-green "podium update completed."; echo-white

cd "$CALLER_DIR"
