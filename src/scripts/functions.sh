#!/bin/bash
# Podium - Internal Functions
# This file provides functions needed by Podium scripts without polluting user's shell

# Get the projects directory (configurable)
get_projects_dir() {
    # Get the directory where this script is located
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local podium_root="$(dirname "$script_dir")"
    
    # First check docker-stack/.env file (preferred method)
    if [ -f "$podium_root/docker-stack/.env" ]; then
        PROJECTS_DIR=$(grep "^PROJECTS_DIR=" "$podium_root/docker-stack/.env" 2>/dev/null | cut -d'=' -f2)
        if [ -n "$PROJECTS_DIR" ]; then
            # Expand tilde to home directory
            PROJECTS_DIR="${PROJECTS_DIR/#\~/$HOME}"
            echo "$PROJECTS_DIR"
            return
        fi
    fi
    
    # Fallback to legacy ~/.podium/config for backward compatibility
    if [ -f ~/.podium/config ]; then
        PROJECTS_DIR=$(grep "^PROJECTS_DIR=" ~/.podium/config | cut -d'=' -f2)
        if [ -n "$PROJECTS_DIR" ]; then
            echo "$PROJECTS_DIR"
            return
        fi
    fi
    
    # Default to ~/podium-projects
    echo "$HOME/podium-projects"
}

# Initialize projects directory if it doesn't exist
init_projects_dir() {
    local projects_dir="$(get_projects_dir)"
    if [ ! -d "$projects_dir" ]; then
        echo-cyan "Creating projects directory: $projects_dir"
        mkdir -p "$projects_dir"
    fi
}

# Color output functions (suppressed in JSON mode)
echo-red() { if [[ "$JSON_OUTPUT" == "1" ]]; then return; fi; if [[ "$NO_COLOR" != "1" ]]; then tput setaf 1 2>/dev/null; fi; echo "$@"; if [[ "$NO_COLOR" != "1" ]]; then tput sgr0 2>/dev/null; fi; }
echo-green() { if [[ "$JSON_OUTPUT" == "1" ]]; then return; fi; if [[ "$NO_COLOR" != "1" ]]; then tput setaf 2 2>/dev/null; fi; echo "$@"; if [[ "$NO_COLOR" != "1" ]]; then tput sgr0 2>/dev/null; fi; }
echo-yellow() { if [[ "$JSON_OUTPUT" == "1" ]]; then return; fi; if [[ "$NO_COLOR" != "1" ]]; then tput setaf 3 2>/dev/null; fi; echo "$@"; if [[ "$NO_COLOR" != "1" ]]; then tput sgr0 2>/dev/null; fi; }
echo-blue() { if [[ "$JSON_OUTPUT" == "1" ]]; then return; fi; if [[ "$NO_COLOR" != "1" ]]; then tput setaf 4 2>/dev/null; fi; echo "$@"; if [[ "$NO_COLOR" != "1" ]]; then tput sgr0 2>/dev/null; fi; }
echo-magenta() { if [[ "$JSON_OUTPUT" == "1" ]]; then return; fi; if [[ "$NO_COLOR" != "1" ]]; then tput setaf 5 2>/dev/null; fi; echo "$@"; if [[ "$NO_COLOR" != "1" ]]; then tput sgr0 2>/dev/null; fi; }
echo-cyan() { if [[ "$JSON_OUTPUT" == "1" ]]; then return; fi; if [[ "$NO_COLOR" != "1" ]]; then tput setaf 6 2>/dev/null; fi; echo "$@"; if [[ "$NO_COLOR" != "1" ]]; then tput sgr0 2>/dev/null; fi; }
echo-white() { if [[ "$JSON_OUTPUT" == "1" ]]; then return; fi; if [[ "$NO_COLOR" != "1" ]]; then tput setaf 7 2>/dev/null; fi; echo "$@"; if [[ "$NO_COLOR" != "1" ]]; then tput sgr0 2>/dev/null; fi; }

# JSON-aware echo function for regular output
echo-return() { if [[ "$JSON_OUTPUT" != "1" ]]; then echo "$@"; fi; }

# Docker aliases used by scripts (JSON-aware for clean output)
dockerup() { 
    if [[ "$JSON_OUTPUT" == "1" ]]; then
        # Clear the log file first, then pipe Docker output to temp file for JSON mode
        > /tmp/podium-docker-progress.log
        timeout 300 docker compose up -d "$@" > /tmp/podium-docker-progress.log 2>&1
    else
        # Interactive mode - show normal progress
        docker compose up -d "$@"
    fi
}
dockerdown() { 
    if [[ "$JSON_OUTPUT" == "1" ]]; then
        docker compose down "$@" > /dev/null 2>&1
    else
        docker compose down "$@"
    fi
}
dockerexec() { docker container exec -it "$@"; }
dockerls() { docker container ls "$@"; }
dockerrm() { docker container rm "$@"; }

# JSON-aware command wrappers
json-mysql() {
    if [[ "$JSON_OUTPUT" == "1" ]]; then
        mysql "$@" > /dev/null 2>&1
    else
        mysql "$@"
    fi
}

json-composer() {
    if [[ "$JSON_OUTPUT" == "1" ]]; then
        timeout 600 composer-docker "$@" > /dev/null 2>&1
    else
        composer-docker "$@"
    fi
}

json-artisan() {
    if [[ "$JSON_OUTPUT" == "1" ]]; then
        timeout 300 art "$@" > /dev/null 2>&1
    else
        art "$@"
    fi
}

# JSON error function for consistent error responses
json_error() {
    local error_message="$1"
    echo "{\"action\": \"new_project\", \"status\": \"error\", \"error\": \"$error_message\"}"
    exit 1
}

# Project-specific Docker commands (run inside project containers)
composer-docker() { 
    local project_name="$(basename "$(pwd)")"
    if [ -t 0 ]; then
        # Interactive mode (TTY available)
        docker container exec -it --user "$(id -u):$(id -g)" --workdir /usr/share/nginx/html "$project_name" composer "$@"
    else
        # Non-interactive mode (no TTY, for scripts)
        docker container exec --user "$(id -u):$(id -g)" --workdir /usr/share/nginx/html "$project_name" composer "$@"
    fi
}
art-docker() { 
    local project_name="$(basename "$(pwd)")"
    if [ -t 0 ]; then
        # Interactive mode (TTY available)
        docker container exec -it --user "$(id -u):$(id -g)" --workdir /usr/share/nginx/html "$project_name" php artisan "$@"
    else
        # Non-interactive mode (no TTY, for scripts)
        docker container exec --user "$(id -u):$(id -g)" --workdir /usr/share/nginx/html "$project_name" php artisan "$@"
    fi
}

# Check if services are running
check-mariadb() { [ "$(docker ps -q -f name=mariadb)" ] && return 0 || return 1; }
check-phpmyadmin() { [ "$(docker ps -q -f name=phpmyadmin)" ] && return 0 || return 1; }
check-redis() { [ "$(docker ps -q -f name=redis)" ] && return 0 || return 1; }
check-memcached() { [ "$(docker ps -q -f name=memcached)" ] && return 0 || return 1; }
check-mongo() { [ "$(docker ps -q -f name=mongo)" ] && return 0 || return 1; }
check-postgres() { [ "$(docker ps -q -f name=postgres)" ] && return 0 || return 1; }
check-mailhog() { [ "$(docker ps -q -f name=mailhog)" ] && return 0 || return 1; }
check-ollama() { [ "$(docker ps -q -f name=ollama)" ] && return 0 || return 1; }

# Utility functions
divider() { if [[ "$JSON_OUTPUT" != "1" ]]; then echo; echo-white '==============================='; echo; fi; }
whatismyip() { dig +short myip.opendns.com @resolver1.opendns.com 2>/dev/null || echo "Unable to get IP"; }

# Cross-platform sed function
podium-sed() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

# Cross-platform sudo sed function
sudo-podium-sed() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sudo sed -i '' "$@"
    else
        sudo sed -i "$@"
    fi
}

# Safe sudo function (doesn't override user's sudo)
podium-sudo() {
    if command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        "$@"
    fi
}
