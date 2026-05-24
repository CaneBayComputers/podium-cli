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
            # No interactive prompt — require the flag. The original compose is
            # always preserved as docker-compose.upstream.yaml, so overwriting is
            # recoverable, but we still make it an explicit choice.
            error "A docker-compose file already exists and is not a Podium project. Re-run with --overwrite-docker-compose to replace it (the original is saved as docker-compose.upstream.yaml)."
            ;;
    esac
}

# GitHub repository creation function
# Usage: create_github_repo PROJECT_NAME CREATE_GITHUB ORGANIZATION [EXISTING_REPO_URL] [VISIBILITY]
# VISIBILITY defaults to "private". Falls back to $GITHUB_VISIBILITY if unset.
# Returns 0 on success, 1 on failure
create_github_repo() {
    local project_name="$1"
    local create_github="$2"
    local organization="$3"
    local existing_repo_url="$4"
    local visibility="${5:-${GITHUB_VISIBILITY:-private}}"
    local existing_repo_name=""

    # Normalize visibility — anything other than "public" → "private"
    case "$visibility" in
        public)  visibility="public" ;;
        *)       visibility="private" ;;
    esac
    
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
    
    echo-cyan "Creating GitHub repository: $repo_name ($visibility)"
    
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
    if gh repo create "$repo_name" --"$visibility" --confirm >/dev/null 2>&1; then
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

# Prompt for GitHub repository creation in interactive mode.
# Sets the following globals:
#   CREATE_GITHUB        — "yes" | "org" | "no"
#   ORGANIZATION         — org name when CREATE_GITHUB="org"
#   GITHUB_VISIBILITY    — "private" (default) | "public"
prompt_github_creation() {
    # Check GitHub CLI availability
    local gh_available=false
    if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
        gh_available=true
    fi

    if [ "$gh_available" != true ]; then
        echo-yellow "GitHub CLI (gh) is not installed or not authenticated."
        echo-yellow "Skipping GitHub repository creation."
        echo-white "To enable GitHub integration, install gh CLI and run 'gh auth login'"
        CREATE_GITHUB="no"
        return
    fi

    # No interactive terminal — can't prompt. Default to skipping rather than
    # blocking on read. Use --github / --github-org to create non-interactively.
    if [[ ! -t 0 ]]; then
        echo-yellow "Non-interactive context — skipping GitHub repository creation."
        echo-white "Pass --github or --github-org <org> (with --public/--private) to create one non-interactively."
        CREATE_GITHUB="no"
        return
    fi

    echo-cyan "Would you like to create a GitHub repository?"
    echo-white "1) Yes, create GitHub repository"
    echo-white "2) No, skip GitHub repository"
    echo-yellow -n "Enter your choice (1-2): "
    read GITHUB_CHOICE

    case "$GITHUB_CHOICE" in
        1)
            CREATE_GITHUB="yes"

            # Pick personal account or an organization the user belongs to
            echo-return
            echo-cyan "Where should the repository live?"
            echo-white "1) Personal account"
            echo-white "2) Organization"
            echo-yellow -n "Enter your choice (1-2): "
            read OWNER_CHOICE

            if [ "$OWNER_CHOICE" = "2" ]; then
                mapfile -t ORGS < <(gh api user/orgs --jq '.[].login' 2>/dev/null | sort -f)

                if [ "${#ORGS[@]}" -eq 0 ]; then
                    echo-yellow "No organizations found on your GitHub account. Using personal account."
                else
                    echo-return
                    echo-cyan "Select an organization:"
                    local _i
                    for _i in "${!ORGS[@]}"; do
                        printf "  %2d) %s\n" "$((_i + 1))" "${ORGS[$_i]}"
                    done
                    echo-yellow -n "Enter number (1-${#ORGS[@]}, or Enter for personal): "
                    read ORG_NUM
                    if [[ "$ORG_NUM" =~ ^[0-9]+$ ]] \
                            && (( ORG_NUM >= 1 && ORG_NUM <= ${#ORGS[@]} )); then
                        ORGANIZATION="${ORGS[$((ORG_NUM - 1))]}"
                        CREATE_GITHUB="org"
                        echo-green "Repository will be created in organization: $ORGANIZATION"
                    else
                        echo-yellow "Invalid choice or empty input. Using personal account."
                    fi
                fi
            fi

            # Visibility (defaults to private if input is invalid/empty)
            echo-return
            echo-cyan "Repository visibility?"
            echo-white "1) Private (recommended)"
            echo-white "2) Public"
            echo-yellow -n "Enter your choice (1-2): "
            read VISIBILITY_CHOICE
            case "$VISIBILITY_CHOICE" in
                2) GITHUB_VISIBILITY="public" ;;
                *) GITHUB_VISIBILITY="private" ;;
            esac
            echo-green "Visibility: $GITHUB_VISIBILITY"
            ;;
        2)
            CREATE_GITHUB="no"
            ;;
        *)
            echo-yellow "Invalid choice. Skipping GitHub repository creation"
            CREATE_GITHUB="no"
            ;;
    esac
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

# Decide whether a framework should (re)write its env/config file.
# Returns 0 (proceed/write) when the file is absent or --overwrite-env was passed
# (OVERWRITE_ENV=1); returns 1 (skip) when the file already exists and no override.
# When overwriting an EXISTING file while adopting an existing project (an
# upstream compose was present), the original is preserved once as <file>.upstream.
# Usage: should_write_env ".env" || return 0
should_write_env() {
    local config_file="$1"
    if [ -f "$config_file" ] && [ "${OVERWRITE_ENV:-0}" != "1" ]; then
        echo-yellow "Existing $config_file found — keeping it (pass --overwrite-env to regenerate)."
        return 1
    fi
    # Preserve the original once when adopting an existing project (not greenfield).
    if [ -f "$config_file" ] && [ -n "${EXISTING_COMPOSE_FILE:-}" ] && [ ! -f "${config_file}.upstream" ]; then
        cp "$config_file" "${config_file}.upstream"
        echo-cyan "Backed up existing $config_file to ${config_file}.upstream"
    fi
    return 0
}

# Rewrite a single KEY=VALUE in .env, but only if the key already exists.
# (podium-sed-change's c\ no-ops when the pattern doesn't match, but we guard
# explicitly so we never append keys a non-Laravel .env never had.)
_env_set_if_present() {
    local key="$1" val="$2"
    if grep -qE "^#*[[:space:]]*${key}=" .env 2>/dev/null; then
        podium-sed-change "/^#*[[:space:]]*${key}=/" "${key}=${val}" .env
    fi
}

# Rewrite an existing project's .env CONNECTION settings to point at Podium's
# shared services, in place — for adopting an existing app (e.g. a complex/
# adapted compose) without nuking its real config. Only rewrites keys that
# already exist; APP_KEY and everything else are preserved. Backs the original
# up to .env.upstream once. Does NOT run migrations (that's destructive on a
# populated DB — left to the user).
# Args: $1 = database name, $2 = database engine (mysql|postgres|mongo|"")
rewrite_env_for_shared_services() {
    local db_name="$1"
    local engine="$2"

    if [ ! -f ".env" ]; then
        echo-yellow "No .env found — nothing to rewrite. (Configure connection settings manually if the app needs a database.)"
        return 0
    fi

    # Preserve the original .env once (mirrors docker-compose.upstream.yaml).
    if [ ! -f ".env.upstream" ]; then
        cp .env .env.upstream
        echo-cyan "Backed up original .env to .env.upstream"
    fi

    # If engine wasn't explicitly chosen, detect it from the existing .env.
    if [ -z "$engine" ] || [ "$engine" = "mariadb" ]; then
        local conn
        conn=$(grep -E "^#*[[:space:]]*DB_CONNECTION=" .env 2>/dev/null | head -1 | cut -d= -f2- | tr -d "\"' ")
        case "$conn" in
            pgsql|postgres|postgresql) engine="postgres" ;;
            mongodb|mongo)             engine="mongo" ;;
            *)                         engine="mysql" ;;
        esac
    fi

    local db_host db_port db_user db_pass
    case "$engine" in
        postgres|postgresql|pgsql)
            db_host="$POSTGRES_CONTAINER_NAME"; db_port="5432"; db_user="root"; db_pass="password" ;;
        mongo|mongodb)
            db_host="$MONGO_CONTAINER_NAME";    db_port="27017"; db_user="root"; db_pass="password" ;;
        *)
            db_host="$MARIADB_CONTAINER_NAME";  db_port="3306";  db_user="root"; db_pass="" ;;
    esac

    echo-cyan "Rewriting .env connection settings for Podium shared services ..."
    _env_set_if_present "DB_HOST"        "$db_host"
    _env_set_if_present "DB_PORT"        "$db_port"
    _env_set_if_present "DB_DATABASE"    "$db_name"
    _env_set_if_present "DB_USERNAME"    "$db_user"
    _env_set_if_present "DB_PASSWORD"    "$db_pass"
    _env_set_if_present "REDIS_HOST"     "$REDIS_CONTAINER_NAME"
    _env_set_if_present "MEMCACHED_HOST" "$MEMCACHED_CONTAINER_NAME"
    _env_set_if_present "MAIL_HOST"      "$MAILHOG_CONTAINER_NAME"
    echo-green ".env connection settings updated (APP_KEY and other settings preserved)."
}

# Idempotently ensure a database exists. Never errors if it already exists.
# Args: $1 = database name, $2 = database engine (mysql|postgres|mongo|"")
ensure_database() {
    local db_name="$1"
    local engine="$2"
    echo-cyan "Ensuring database '$db_name' exists ..."; echo-white
    case "$engine" in
        postgres|postgresql|pgsql)
            if json-postgres -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$db_name';" 2>/dev/null | grep -q 1; then
                echo-yellow "Database '$db_name' already exists — continuing."
            elif json-postgres -d postgres -c "CREATE DATABASE \"$db_name\";" 2>/dev/null; then
                echo-green 'Database created!'; echo-white
            else
                echo-yellow "Could not create database '$db_name' (it may already exist, or shared services are down) — continuing."
            fi
            ;;
        mongo|mongodb)
            echo-white "MongoDB creates the database on first write — nothing to create."
            ;;
        *)
            if json-mysql -u"root" -e "CREATE DATABASE IF NOT EXISTS \`$db_name\`;"; then
                echo-green 'Database ready!'; echo-white
            else
                echo-yellow "Could not create database '$db_name' (it may already exist, or shared services are down) — continuing."
            fi
            ;;
    esac
}

# After a project is created/cloned/installed, hand off to an interactive AI session
# inside the project directory — same flow that podium create does in phase 2.
#
# Skipped (silently) when:
#   - JSON_OUTPUT mode (automation context)
#   - SKIP_INTERACTIVE=1 (caller passed --one-off)
#   - stdin is not a TTY (piped/scripted invocation)
#   - AI_AGENT is not configured
#   - the project directory doesn't exist
#
# Args:
#   $1  project name (required) — must be a directory in $PROJECTS_DIR_PATH
#   $2  optional override for the seed prompt
ai_handoff() {
    local project_name="$1"
    local seed_prompt="$2"

    # Always-skip cases
    [[ -z "$project_name" ]] && return 0
    [[ "$JSON_OUTPUT" == "1" ]] && return 0
    [[ "$SKIP_INTERACTIVE" == "1" ]] && return 0
    [[ ! -t 0 ]] && return 0
    [[ -z "$AI_AGENT" ]] && return 0

    local project_dir="$PROJECTS_DIR_PATH/$project_name"
    [[ ! -d "$project_dir" ]] && return 0

    # Resolve ai.sh — DEV_DIR is set by the calling script's pre_check.sh
    local ai_script="$DEV_DIR/scripts/ai.sh"
    [[ ! -f "$ai_script" ]] && return 0

    if [[ -z "$seed_prompt" ]]; then
        seed_prompt="This project is managed by the Podium CLI — a Docker-based local development environment manager. Before doing anything: (1) read /usr/local/share/podium-cli/AGENTS.md for how Podium works (shared services, hostname routing, runtime images, command patterns); (2) run 'podium help' for the full command list. Then read this project's README.md. The project is running at http://$project_name/. You are the developer."
    fi

    echo-return
    echo-cyan "Starting interactive AI session in $project_name..."
    echo-white "(skip with --one-off; configure agent with 'podium ai-set')"
    echo-return

    cd "$project_dir"
    exec "$ai_script" "$seed_prompt"
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
