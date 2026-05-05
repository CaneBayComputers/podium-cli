#!/bin/bash
# Podium - Internal Functions
# This file provides functions needed by Podium scripts without polluting user's shell

# Load primary configuration if available (for container names, paths, etc.)
if [ -f "/etc/podium-cli/.env" ]; then
    # shellcheck disable=SC1091
    source "/etc/podium-cli/.env"
fi

# Get the projects directory (configurable)
get_projects_dir() {
    # Get the directory where this script is located
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
    local podium_root="$(dirname "$script_dir" 2>/dev/null)"
    
    # First check /etc/podium-cli/.env file (primary config location)
    if [ -f "/etc/podium-cli/.env" ]; then
        PROJECTS_DIR=$(grep "^PROJECTS_DIR=" "/etc/podium-cli/.env" 2>/dev/null | cut -d'=' -f2)
        if [ -n "$PROJECTS_DIR" ]; then
            # Expand tilde to home directory
            PROJECTS_DIR="${PROJECTS_DIR/#\~/$HOME}"
            echo "$PROJECTS_DIR"
            return
        fi
    # Fallback to old location for backward compatibility
    elif [ -f "$podium_root/docker-stack/.env" ]; then
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

# Detect terminal color support once. When stdout isn't a terminal or $TERM
# is unset/invalid (e.g. plain `ssh host cmd` without -t), `tput` exits
# non-zero — combined with `set -e` in the calling script, that would abort
# the script silently. Force NO_COLOR=1 in that case so we skip tput entirely.
if [[ -z "${NO_COLOR:-}" ]] && ! tput setaf 1 >/dev/null 2>&1; then
    NO_COLOR=1
fi

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
        docker compose up -d "$@" > /tmp/podium-docker-progress.log 2>&1
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
    # Always execute the MariaDB client from inside the mariadb container so we don't
    # require a host-side mariadb-client installation.
    if [[ "$JSON_OUTPUT" == "1" ]]; then
        docker container exec "$MARIADB_CONTAINER_NAME" mariadb "$@" > /dev/null 2>&1
    else
        docker container exec -i "$MARIADB_CONTAINER_NAME" mariadb "$@"
    fi
}

json-postgres() {
    if [[ "$JSON_OUTPUT" == "1" ]]; then
        docker container exec -e PGPASSWORD=password "$POSTGRES_CONTAINER_NAME" psql -U root "$@" > /dev/null 2>&1
    else
        docker container exec -e PGPASSWORD=password -i "$POSTGRES_CONTAINER_NAME" psql -U root "$@"
    fi
}

json-composer() {
    if [[ "$JSON_OUTPUT" == "1" ]]; then
        if [[ "$DEBUG" == "1" ]]; then
            # In debug mode, run composer and log that it's running, but don't capture output
            debug "Running composer-docker $* (debug mode - output suppressed for JSON)"
            composer-docker "$@" > /dev/null 2>&1
            local exit_code=$?
            debug "composer-docker completed with exit code: $exit_code"
            return $exit_code
        else
            # Run composer silently in non-debug JSON mode
            composer-docker "$@" > /dev/null 2>&1
        fi
    else
        composer-docker "$@"
    fi
}

json-artisan() {
    if [[ "$JSON_OUTPUT" == "1" ]]; then
        art "$@" > /dev/null 2>&1
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
check-mariadb() { [ "$(docker ps -q -f name="$MARIADB_CONTAINER_NAME")" ] && return 0 || return 1; }
check-phpmyadmin() { [ "$(docker ps -q -f name="$PHPMYADMIN_CONTAINER_NAME")" ] && return 0 || return 1; }
check-redis() { [ "$(docker ps -q -f name="$REDIS_CONTAINER_NAME")" ] && return 0 || return 1; }
check-memcached() { [ "$(docker ps -q -f name="$MEMCACHED_CONTAINER_NAME")" ] && return 0 || return 1; }
check-mongo() { [ "$(docker ps -q -f name="$MONGO_CONTAINER_NAME")" ] && return 0 || return 1; }
check-postgres() { [ "$(docker ps -q -f name="$POSTGRES_CONTAINER_NAME")" ] && return 0 || return 1; }
check-mailhog() { [ "$(docker ps -q -f name="$MAILHOG_CONTAINER_NAME")" ] && return 0 || return 1; }

# Utility functions
divider() { if [[ "$JSON_OUTPUT" != "1" ]]; then echo; echo-white '==============================='; echo; fi; }
whatismyip() { dig +short "$WHATISMYIP_DNS_NAME" @"$WHATISMYIP_DNS_SERVER" 2>/dev/null || echo "Unable to get IP"; }

# Cross-platform sed function
podium-sed() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

# Cross-platform sed change function (handles c\ command differences)
podium-sed-change() {
    local pattern="$1"
    local replacement="$2"
    local file="$3"
    
    # Go back to the working c\ approach but fix it properly
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS BSD sed - use printf to handle the newline properly
        printf '%s\n' "$pattern c\\" "$replacement" | sed -i '' -f - "$file"
    else
        # Linux GNU sed can do it on one line
        sed -i "$pattern c\\$replacement" "$file"
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

# Cross-platform sudo sed change function
sudo-podium-sed-change() {
    local pattern="$1"
    local replacement="$2"
    local file="$3"
    
    # Go back to the working c\ approach but fix it properly with sudo
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS BSD sed - use printf to handle the newline properly
        printf '%s\n' "$pattern c\\" "$replacement" | sudo sed -i '' -f - "$file"
    else
        # Linux GNU sed can do it on one line
        sudo sed -i "$pattern c\\$replacement" "$file"
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

# JSON error output function
json_error() {
    local message="$1"
    local exit_code="${2:-1}"
    echo "{\"status\": \"error\", \"message\": \"$message\"}"
    exit "$exit_code"
}

# Universal error function - handles both interactive and JSON output modes
error() {
    local message="$1"
    local exit_code="${2:-1}"
    
    if [[ "$JSON_OUTPUT" == "1" ]]; then
        json_error "$message" "$exit_code"
    else
        echo-red "$message"
        exit "$exit_code"
    fi
}

# Output spacing function that respects JSON_OUTPUT
echo-return() { if [[ "$JSON_OUTPUT" != "1" ]]; then echo "$@"; fi; }

# Docker Compose checking functions
check_docker_compose_type() {
    local compose_file="$1"
    
    if [ ! -f "$compose_file" ]; then
        echo "none"
        return 0
    fi
    
    # Check if this is a Podium project
    if grep -q "podium-cli_vpc" "$compose_file" 2>/dev/null; then
        echo "podium-project"
        return 0
    fi
    
    # Has docker-compose but not a Podium project
    echo "non-podium"
    return 0
}

handle_docker_compose_conflict() {
    local compose_file="$1"
    local operation_name="${2:-setup}"
    
    # If overwrite is already set, no conflict handling needed
    if [[ "$OVERWRITE_DOCKER_COMPOSE" == "1" ]]; then
        return 0
    fi
    
    local compose_type=$(check_docker_compose_type "$compose_file")
    
    case "$compose_type" in
        "none")
            echo-white "✅ No existing Docker configuration found - will create new setup"
            return 0
            ;;
        "podium-project")
            echo-white "✅ Detected existing Podium project - will be automatically reconfigured"
            OVERWRITE_DOCKER_COMPOSE=1
            return 0
            ;;
        "non-podium")
            if [[ "$JSON_OUTPUT" == "1" ]]; then
                error "A docker-compose file already exists and is not a Podium project. Use --overwrite-docker-compose to force overwrite."
            else
                echo-yellow "⚠️  Found a docker-compose file that is not from Podium."
                echo-yellow "Overwriting it with a Podium-managed configuration is recommended so Podium can manage the project correctly."
                echo-yellow -n "Do you want to continue and overwrite it? (Y/n): "
                read OVERWRITE_RESPONSE
                if [[ -n "$OVERWRITE_RESPONSE" && ! "$OVERWRITE_RESPONSE" =~ ^[Yy]$ ]]; then
                    error "$operation_name cancelled. Use --overwrite-docker-compose to force overwrite."
                fi
                OVERWRITE_DOCKER_COMPOSE=1
            fi
            return 0
            ;;
    esac
}

# GitHub repository creation function
# Usage: create_github_repo PROJECT_NAME CREATE_GITHUB ORGANIZATION [EXISTING_REPO_URL]
# Returns 0 on success, 1 on failure
create_github_repo() {
    local project_name="$1"
    local create_github="$2"
    local organization="$3"
    local existing_repo_url="$4"
    local existing_repo_name=""
    
    # Skip if GitHub creation is disabled
    if [ "$create_github" = "no" ] || [ -z "$create_github" ]; then
        echo-yellow "Skipping GitHub repository creation."
        return 0
    fi
    
    # Validate GitHub CLI is available and authenticated
    if ! command -v gh >/dev/null 2>&1; then
        echo-yellow "GitHub CLI (gh) is not installed. Skipping repository creation."
        return 1
    fi
    
    if ! gh auth status >/dev/null 2>&1; then
        echo-yellow "GitHub CLI (gh) is not authenticated. Skipping repository creation."
        return 1
    fi
    
    # Build repository name
    local repo_name="$project_name"
    if [ "$create_github" = "org" ] && [ -n "$organization" ]; then
        repo_name="$organization/$project_name"
    fi
    
    echo-cyan "Creating GitHub repository: $repo_name"
    
    # Derive existing repository name (if any) from the source URL
    if [ -n "$existing_repo_url" ]; then
        if [[ "$existing_repo_url" =~ github\.com[:/]([^/]+/[^/]+)(\.git)?$ ]]; then
            existing_repo_name="${BASH_REMATCH[1]}"
            existing_repo_name="${existing_repo_name%.git}"
        fi
        
        # If we're trying to create the same repo we just cloned from, skip to avoid conflicts
        if [ -n "$existing_repo_name" ] && [ "$repo_name" = "$existing_repo_name" ]; then
            echo-yellow "Warning: Attempting to create repository '$repo_name' which is the same as the cloned source."
            echo-yellow "Skipping GitHub repository creation to avoid conflicts."
            return 0
        fi
    fi
    
    # Create the repository first (without pushing)
    local repo_created=false
    if gh repo create "$repo_name" --private --confirm >/dev/null 2>&1; then
        echo-green "GitHub repository created successfully: $repo_name"
        repo_created=true
    else
        # Check if repository already exists
        if gh repo view "$repo_name" >/dev/null 2>&1; then
            echo-yellow "Repository '$repo_name' already exists. Skipping creation."
        else
            echo-yellow "GitHub repository creation failed, but project setup will continue."
            return 1
        fi
    fi
    
    # Ensure we are in a git repository
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo-yellow "Current directory is not a Git repository. Skipping initial push."
        return 1
    fi
    
    # Ensure there is at least one commit; if not, create an initial commit
    if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
        # Only create a commit if there are changes to commit
        if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
            echo-cyan "Creating initial commit before pushing to GitHub..."
            if ! git add . >/dev/null 2>&1; then
                git add .
            fi
            if ! git commit -m "Initial commit" >/dev/null 2>&1; then
                git commit -m "Initial commit"
            fi
        else
            echo-yellow "No commits and no changes to commit. Skipping initial push."
            return 1
        fi
    fi
    
    # Ensure a Git remote is configured for this repository
    local remote_name="origin"
    local current_origin_url
    current_origin_url=$(git remote get-url "$remote_name" 2>/dev/null || true)
    
    # If this project was cloned from another repository, preserve that remote as 'upstream'
    if [ -n "$existing_repo_name" ] && [ -n "$current_origin_url" ]; then
        if [[ "$current_origin_url" == *"$existing_repo_name"* ]]; then
            git remote rename "$remote_name" upstream >/dev/null 2>&1 || true
            current_origin_url=""
        fi
    fi
    
    # Point 'origin' at the newly created GitHub repository
    local repo_url
    repo_url=$(gh repo view "$repo_name" --json sshUrl,cloneUrl -q '.sshUrl // .cloneUrl' 2>/dev/null || true)
    if [ -z "$repo_url" ]; then
        repo_url="git@github.com:${repo_name}.git"
    fi
    
    if [ -n "$current_origin_url" ]; then
        git remote set-url "$remote_name" "$repo_url" >/dev/null 2>&1 || true
    else
        git remote add "$remote_name" "$repo_url" >/dev/null 2>&1 || true
    fi
    
    # Push local commits separately so push failures are not masked by creation success
    echo-cyan "Pushing local repository to GitHub..."
    if git push -u "$remote_name" HEAD >/dev/null 2>&1; then
        echo-green "Repository pushed successfully to GitHub: $repo_name"
        return 0
    else
        echo-yellow "Initial push to GitHub failed. Please check your Git remote and push manually."
        return 1
    fi
}

# Prompt for GitHub repository creation in interactive mode
# Usage: prompt_github_creation
# Sets CREATE_GITHUB and ORGANIZATION variables
prompt_github_creation() {
    # Check GitHub CLI availability
    local gh_available=false
    if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
        gh_available=true
    fi
    
    if [ "$gh_available" = true ]; then
        echo-cyan "Would you like to create a GitHub repository?"
        echo-white "1) Yes, create GitHub repository"
        echo-white "2) No, skip GitHub repository"
        echo-yellow -n "Enter your choice (1-2): "
        read GITHUB_CHOICE
        
        case $GITHUB_CHOICE in
            1)
                CREATE_GITHUB="yes"
                # Prompt for organization
                echo-cyan "GitHub repository will be created in your personal account."
                echo-yellow -n "Would you like to create it in an organization instead? (y/N): "
                read USE_ORG
                if [[ "$USE_ORG" =~ ^[Yy]$ ]]; then
                    echo-yellow -n "Enter organization name: "
                    read ORGANIZATION
                    if [ -n "$ORGANIZATION" ]; then
                        CREATE_GITHUB="org"
                        echo-green "Repository will be created in organization: $ORGANIZATION"
                    else
                        echo-yellow "No organization specified. Using personal account."
                    fi
                fi
                ;;
            2)
                CREATE_GITHUB="no"
                ;;
            *)
                echo-yellow "Invalid choice. Skipping GitHub repository creation"
                CREATE_GITHUB="no"
                ;;
        esac
    else
        echo-yellow "GitHub CLI (gh) is not installed or not authenticated."
        echo-yellow "Skipping GitHub repository creation."
        echo-white "To enable GitHub integration, install gh CLI and run 'gh auth login'"
        CREATE_GITHUB="no"
    fi
}

# Debug function - writes to log file when DEBUG=1
debug() {
    if [[ "$DEBUG" == "1" ]]; then
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        local script_name=$(basename "${BASH_SOURCE[1]}")
        local line_number="${BASH_LINENO[0]}"
        
        # Use custom debug log path if set, otherwise default to /tmp
        local debug_log_file="${DEBUG_LOG_PATH:-/tmp/podium-cli-debug.log}"
        
        # Initialize debug log file on first use
        if [[ -z "$DEBUG_STARTED" ]]; then
            # Create directory if it doesn't exist (for custom paths)
            local debug_dir=$(dirname "$debug_log_file")
            mkdir -p "$debug_dir" 2>/dev/null || true
            
            echo "=== PODIUM CLI DEBUG SESSION STARTED ===" > "$debug_log_file"
            echo "[$timestamp] [debug] Debug log path: $debug_log_file" >> "$debug_log_file"
            export DEBUG_STARTED=1
        fi
        
        echo "[$timestamp] [$script_name:$line_number] $1" >> "$debug_log_file"
    fi
}

# Helper function to append JSON results to debug log
debug_append_json() {
    if [[ "$DEBUG" == "1" && -n "$1" ]]; then
        local debug_log_file="${DEBUG_LOG_PATH:-/tmp/podium-cli-debug.log}"
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        
        echo "" >> "$debug_log_file"
        echo "=== JSON RESULT [$timestamp] ===" >> "$debug_log_file"
        echo "$1" >> "$debug_log_file"
        echo "=== END JSON RESULT ===" >> "$debug_log_file"
    fi
}
