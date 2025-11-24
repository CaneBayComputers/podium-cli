#!/bin/bash

set -e

ORIG_DIR=$(pwd)

cd "$(dirname "$(realpath "$0")")"
cd ..

DEV_DIR=$(pwd)

source scripts/functions.sh

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
            echo "  - Attempts to update the Podium CLI via your system package manager (if applicable)."
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
echo-cyan "Updating Podium base Docker images ..."; echo-white

if ! command -v docker >/dev/null 2>&1; then
    echo-yellow "Docker is not available on this system. Skipping image updates."
else
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
echo-cyan "Updating Podium CLI (if managed by a package manager) ..."; echo-white

CLI_UPDATED=false

# Homebrew (macOS)
if command -v brew >/dev/null 2>&1 && brew list podium-cli >/dev/null 2>&1; then
    echo-white "Detected Homebrew-managed installation."
    if brew update && brew upgrade podium-cli; then
        echo-green "Podium CLI updated via Homebrew."
        CLI_UPDATED=true
    else
        echo-yellow "Homebrew update for podium-cli failed. Please run 'brew upgrade podium-cli' manually."
    fi

# Debian/Ubuntu (apt)
elif command -v apt-get >/dev/null 2>&1 && dpkg -s podium-cli >/dev/null 2>&1; then
    echo-white "Detected apt-managed installation."
    if sudo apt-get update -y -q && sudo apt-get install -y --only-upgrade podium-cli; then
        echo-green "Podium CLI updated via apt."
        CLI_UPDATED=true
    else
        echo-yellow "apt update for podium-cli failed. Please run 'sudo apt-get install --only-upgrade podium-cli' manually."
    fi

# Arch (pacman)
elif command -v pacman >/dev/null 2>&1 && pacman -Qi podium-cli >/dev/null 2>&1; then
    echo-white "Detected pacman-managed installation."
    if sudo pacman -Syu --noconfirm podium-cli; then
        echo-green "Podium CLI updated via pacman."
        CLI_UPDATED=true
    else
        echo-yellow "pacman update for podium-cli failed. Please run 'sudo pacman -Syu podium-cli' manually."
    fi

else
    echo-yellow "Podium CLI does not appear to be managed by Homebrew, apt, or pacman."
    echo-yellow "Skipping CLI update. Use your original install method to update the CLI itself."
fi

echo-return
echo-green "podium update completed."; echo-white

cd "$ORIG_DIR"

