#!/bin/bash

set -e

cd "$(cd "$(dirname "$0")" 2>/dev/null && pwd -P)"
cd ..
DEV_DIR=$(pwd)

source scripts/pre_check.sh

SKIP_INTERACTIVE=0
APP=""
PROJECT_NAME=""
CUSTOM_IMAGE=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --one-off) SKIP_INTERACTIVE=1; shift ;;
        --image)
            if [ -n "$2" ] && [[ ! "$2" =~ ^-- ]]; then
                CUSTOM_IMAGE="$2"
                shift 2
            else
                error "Error: --image requires a Docker image reference (e.g. canebaycomputers/cbc:nginx-php8)"
            fi
            ;;
        *)
            # Positional order: <app> [name]. The app selects the installer; the
            # optional name is the project directory/hostname (defaults to app).
            if [ -z "$APP" ]; then
                APP="$1"
            elif [ -z "$PROJECT_NAME" ]; then
                PROJECT_NAME="$1"
            else
                error "Too many arguments. Usage: podium install <app> [name] [--image <ref>]"
            fi
            shift
            ;;
    esac
done

# Project name defaults to the app slug when not given a custom name.
if [ -z "$PROJECT_NAME" ]; then
    PROJECT_NAME="$APP"
fi

# List available installers
if [ "$APP" = "--list" ] || [ "$APP" = "-l" ]; then
    echo-return
    echo-white "Available installers:"
    for f in "$DEV_DIR/installers/"*.sh; do
        [ -f "$f" ] && echo-cyan "  podium install $(basename "$f" .sh)"
    done
    echo-return
    exit 0
fi

if [ -z "$APP" ]; then
    # An app name is required — no interactive picker.
    echo-red "No app specified."
    echo-white "Usage: podium install <app> [name] [--image <ref>]     (run 'podium install --list' to see all)"
    exit 1
fi

INSTALLER="$DEV_DIR/installers/$APP.sh"
if [ ! -f "$INSTALLER" ]; then
    echo-red "No installer found for: $APP"
    echo-white "Run 'podium install --list' to see available apps."
    exit 1
fi

PROJECTS_DIR="$(get_projects_dir)"
PROJECT_DIR="$PROJECTS_DIR/$PROJECT_NAME"

# Already installed? (only skip if actually running)
if grep -qE "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+${PROJECT_NAME}$" /etc/hosts 2>/dev/null; then
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${PROJECT_NAME}$"; then
        echo-yellow "$PROJECT_NAME is already installed and running."
        echo-white "Visit: http://$PROJECT_NAME/"
        exit 0
    fi
fi

# Defaults (overridable by installer)
INSTALL_DISPLAY="$PROJECT_NAME"
INSTALL_CREDENTIALS=""
INSTALL_NOTES=""

source "$INSTALLER"

echo-return
echo-green "Installing $INSTALL_DISPLAY..."
echo-return

# Pre-install hook (DB creation, key generation, etc.)
if declare -f pre_install > /dev/null 2>&1; then
    pre_install
fi

# Write project files
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"
write_files

# Setup and start.
# Prebuilt-image apps (the default) only need their compose adapted, then a start —
# so setup runs with --no-startup and 'podium up' brings the container online.
# Source-based apps (INSTALL_SETUP_FULL=1, e.g. a Laravel scaffold) need the full
# setup pipeline — composer install, front-end build, .env wiring, migrations — which
# only runs when setup is NOT given --no-startup. Setup starts the container itself in
# that case, so no separate 'podium up' is required.
# Forward a user-supplied --image override to setup (empty array → no extra args).
IMAGE_ARGS=()
[ -n "$CUSTOM_IMAGE" ] && IMAGE_ARGS=(--image "$CUSTOM_IMAGE")

if [ "${INSTALL_SETUP_FULL:-0}" = "1" ]; then
    podium setup "$PROJECT_NAME" ${INSTALL_SETUP_DB:-} "${IMAGE_ARGS[@]}"
else
    podium setup "$PROJECT_NAME" --no-startup "${IMAGE_ARGS[@]}"
    podium up "$PROJECT_NAME"
fi

# Verify
echo-return
echo-white "Waiting for $INSTALL_DISPLAY to be ready..."
RETRIES=0
HTTP_CODE="000"
while [ $RETRIES -lt 15 ]; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://$PROJECT_NAME/" 2>/dev/null || echo "000")
    first_digit="${HTTP_CODE:0:1}"
    if [ "$first_digit" = "2" ] || [ "$first_digit" = "3" ]; then
        break
    fi
    RETRIES=$((RETRIES + 1))
    sleep 5
done

echo-return
first_digit="${HTTP_CODE:0:1}"
if [ "$first_digit" = "2" ] || [ "$first_digit" = "3" ]; then
    echo-green "$INSTALL_DISPLAY is ready! (HTTP $HTTP_CODE)"
    echo-return
    echo-white "  URL: http://$PROJECT_NAME/"
    [ -n "$INSTALL_CREDENTIALS" ] && echo-white "  Credentials: $INSTALL_CREDENTIALS"
    [ -n "$INSTALL_NOTES" ] && echo-yellow "  Note: $INSTALL_NOTES"
else
    echo-yellow "$INSTALL_DISPLAY returned HTTP $HTTP_CODE — it may still be initializing."
    echo-white "  Check: curl -sI http://$PROJECT_NAME/"
    echo-white "  Logs:  podium logs $PROJECT_NAME"
fi
echo-return

# Drop into an interactive AI session inside the project (skipped when --one-off,
# JSON mode, non-TTY, or no AI agent configured).
INSTALL_CMD="podium install $APP"
[ "$PROJECT_NAME" != "$APP" ] && INSTALL_CMD="podium install $APP $PROJECT_NAME"
ai_handoff "$PROJECT_NAME" "This project is managed by the Podium CLI — a Docker-based local development environment manager — and was created by running '$INSTALL_CMD'. Before doing anything: (1) read /usr/local/share/podium-cli/AGENTS.md for how Podium works; (2) run 'podium help' for the full command list. $INSTALL_DISPLAY is running at http://$PROJECT_NAME/. You are the developer."
