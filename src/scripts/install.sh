#!/bin/bash

set -e

cd "$(cd "$(dirname "$0")" 2>/dev/null && pwd -P)"
cd ..
DEV_DIR=$(pwd)

source scripts/pre_check.sh

SKIP_INTERACTIVE=0
APP=""
for arg in "$@"; do
    case "$arg" in
        --one-off) SKIP_INTERACTIVE=1 ;;
        *)
            if [ -z "$APP" ]; then
                APP="$arg"
            fi
            ;;
    esac
done

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
    echo-white "Usage: podium install <app>     (run 'podium install --list' to see all)"
    exit 1
fi

INSTALLER="$DEV_DIR/installers/$APP.sh"
if [ ! -f "$INSTALLER" ]; then
    echo-red "No installer found for: $APP"
    echo-white "Run 'podium install --list' to see available apps."
    exit 1
fi

PROJECTS_DIR="$(get_projects_dir)"
PROJECT_DIR="$PROJECTS_DIR/$APP"

# Already installed? (only skip if actually running)
if grep -qE "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+${APP}$" /etc/hosts 2>/dev/null; then
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${APP}$"; then
        echo-yellow "$APP is already installed and running."
        echo-white "Visit: http://$APP/"
        exit 0
    fi
fi

# Defaults (overridable by installer)
INSTALL_DISPLAY="$APP"
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

# Setup and start
podium setup "$APP" --no-startup
podium up "$APP"

# Verify
echo-return
echo-white "Waiting for $INSTALL_DISPLAY to be ready..."
RETRIES=0
HTTP_CODE="000"
while [ $RETRIES -lt 15 ]; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://$APP/" 2>/dev/null || echo "000")
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
    echo-white "  URL: http://$APP/"
    [ -n "$INSTALL_CREDENTIALS" ] && echo-white "  Credentials: $INSTALL_CREDENTIALS"
    [ -n "$INSTALL_NOTES" ] && echo-yellow "  Note: $INSTALL_NOTES"
else
    echo-yellow "$INSTALL_DISPLAY returned HTTP $HTTP_CODE — it may still be initializing."
    echo-white "  Check: curl -sI http://$APP/"
    echo-white "  Logs:  podium logs $APP"
fi
echo-return

# Drop into an interactive AI session inside the project (skipped when --one-off,
# JSON mode, non-TTY, or no AI agent configured).
ai_handoff "$APP" "This project is managed by the Podium CLI — a Docker-based local development environment manager — and was created by running 'podium install $APP'. Before doing anything: (1) read /usr/local/share/podium-cli/AGENTS.md for how Podium works; (2) run 'podium help' for the full command list. $INSTALL_DISPLAY is running at http://$APP/. You are the developer."
