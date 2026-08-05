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
# Compose profile flags for whatever optional shared services are enabled on
# this machine (OPTIONAL_SERVICES in /etc/podium-cli/.env). Empty when none are,
# so the default `docker compose up` behaviour is untouched.
podium_profile_args() {
    local svc
    for svc in ${OPTIONAL_SERVICES:-}; do
        printf -- '--profile\n%s\n' "$svc"
    done
}

dockerup() { 
    if [[ "$JSON_OUTPUT" == "1" ]]; then
        # Clear the log file first, then pipe Docker output to temp file for JSON mode
        > /tmp/podium-docker-progress.log
        mapfile -t _profiles < <(podium_profile_args)
        docker compose "${_profiles[@]}" up -d "$@" > /tmp/podium-docker-progress.log 2>&1
    else
        # Interactive mode - show normal progress
        mapfile -t _profiles < <(podium_profile_args)
        docker compose "${_profiles[@]}" up -d "$@"
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
# ---------------------------------------------------------------------------
# Update check
# ---------------------------------------------------------------------------
# Three rules, all learned the hard way elsewhere in this tree:
#
#   1. NEVER block a command on the network. The refresh runs detached and
#      writes a cache; every command only ever reads that cache. An offline or
#      slow-DNS machine costs nothing -- `podium status` is on the GUI's hot
#      path and already had a 60s hang once.
#   2. Silent on failure. No release yet, no network, rate-limited -- all mean
#      "say nothing", never a warning on every command.
#   3. Notify at most once a day. A nag on every invocation trains people to
#      ignore it.
PODIUM_UPDATE_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/podium/update.json"
PODIUM_UPDATE_MAX_AGE=86400   # refresh at most daily
PODIUM_NOTIFY_MAX_AGE=86400   # tell the user at most daily

_podium_cache_field() {
    [ -f "$PODIUM_UPDATE_CACHE" ] || return 1
    python3 -c "
import json,sys
try: print(json.load(open('$PODIUM_UPDATE_CACHE')).get('$1','') or '')
except Exception: pass
" 2>/dev/null
}

# Fire-and-forget refresh. Detached, output discarded, never awaited.
podium_update_refresh_async() {
    local now checked
    now=$(date +%s)
    # `|| true` is load-bearing: with no cache file the helper returns 1, and
    # under `set -e` an assignment from a failing command substitution aborts
    # the whole script. That made `podium --version` exit 1 printing nothing on
    # any machine without a cache -- i.e. every machine, on first run.
    checked=$(_podium_cache_field checked 2>/dev/null || true)
    [ -n "$checked" ] && [ $(( now - checked )) -lt $PODIUM_UPDATE_MAX_AGE ] && return 0
    mkdir -p "$(dirname "$PODIUM_UPDATE_CACHE")" 2>/dev/null || return 0
    (
        # NOT /releases/latest -- that endpoint EXCLUDES pre-releases and 404s
        # when every release is one, which is the case for the whole beta. Using
        # it would have made this check silently do nothing until 1.0 final.
        # The list endpoint is newest-first and includes pre-releases.
        tag=$(curl -fsS --max-time 8 \
            "https://api.github.com/repos/CaneBayComputers/podium-cli/releases?per_page=10" 2>/dev/null \
            | python3 -c "
import json,sys
try:
    rs=[r for r in json.load(sys.stdin) if not r.get('draft')]
    print(rs[0].get('tag_name','') if rs else '')
except Exception:
    print('')
" 2>/dev/null) || tag=""
        printf '{"latest": "%s", "checked": %s, "notified": %s}\n' \
            "$tag" "$(date +%s)" "$(_podium_cache_field notified 2>/dev/null || echo 0)" \
            > "$PODIUM_UPDATE_CACHE" 2>/dev/null
    ) >/dev/null 2>&1 &
    disown 2>/dev/null || true
}

# Is a newer release available? Cache read only -- no network, no blocking.
podium_update_available() {
    local latest current
    latest=$(_podium_cache_field latest 2>/dev/null) || return 1
    [ -n "$latest" ] || return 1
    current="$(podium_version)"
    [ "$current" = "unknown" ] && return 1
    latest="${latest#v}"; current="${current#v}"
    [ "$latest" = "$current" ] && return 1
    # newest-first sort: if latest sorts above current, it is newer
    [ "$(printf '%s\n%s\n' "$latest" "$current" | sort -rV | head -1)" = "$latest" ] || return 1
    echo "$latest"
}

# One line, at most daily, never under --json-output.
podium_update_notice() {
    [[ "$JSON_OUTPUT" == "1" ]] && return 0
    local newer now notified
    newer=$(podium_update_available) || return 0
    now=$(date +%s)
    notified=$(_podium_cache_field notified 2>/dev/null || echo 0)
    [ -n "$notified" ] && [ $(( now - notified )) -lt $PODIUM_NOTIFY_MAX_AGE ] && return 0
    python3 -c "
import json
p='$PODIUM_UPDATE_CACHE'
try:
    d=json.load(open(p)); d['notified']=$now; json.dump(d,open(p,'w'))
except Exception: pass
" 2>/dev/null
    echo-yellow "Podium $newer is available (you have $(podium_version)) — run 'podium update'"
}

# Was this CLI installed by a package manager, or from a git checkout?
#
# The two update paths are mutually destructive: `podium update` does a git pull,
# while `apt upgrade` replaces the same files from a .deb. Whichever runs last
# wins and the other's state is silently wrong. So `podium update` has to know
# which kind of install it is standing in and defer rather than fight.
#
# dpkg is asked directly rather than inferred from the path -- a packaged install
# and a git checkout can sit at the same location, and only dpkg knows the truth.
podium_install_is_packaged() {
    command -v dpkg-query >/dev/null 2>&1 || return 1
    dpkg-query -W -f='${Status}' podium-cli 2>/dev/null | grep -q "install ok installed" || return 1
    # A checkout inside a packaged path is still git-managed; .git decides.
    [ -d "${SCRIPT_DIR%/scripts}/../.git" ] && return 1
    return 0
}

# Podium's own version, from the VERSION file at the repo root.
#
# SCRIPT_DIR is <repo>/src, so VERSION sits one level up. Falls back to
# "unknown" rather than failing: a missing VERSION should never break a command,
# and callers can distinguish it from a real version string.
podium_version() {
    local f="${SCRIPT_DIR%/scripts}/../VERSION"
    [ -f "$f" ] || f="$DEV_DIR/../VERSION"
    if [ -f "$f" ]; then
        tr -d ' \t\n\r' < "$f"
    else
        echo "unknown"
    fi
}

# Where the project root sits INSIDE the container.
#
# setup_project.sh mounts a project at html/ when it ships its own docroot
# (`public/`, or a Python/Node app), and at html/public when the project root IS
# the docroot -- plain PHP, WordPress, and October CMS, which puts index.php at
# its root. nginx's docroot is always html/public, so both layouts serve.
#
# Rather than re-deriving that decision (and getting it wrong for Python, which
# has no public/ yet still mounts at html/), ask Docker where the project is
# actually mounted. That is authoritative and cannot drift from the mount.
#
# October CMS is what exposed this: it is Laravel-shaped but ships no public/, so
# composer and artisan ran one directory above the project and failed.
podium_container_workdir() {
    local project_name="${1:-$(basename "$(pwd)")}"
    local dest
    dest=$(docker container inspect "$project_name" \
        --format '{{range .Mounts}}{{.Destination}}{{"\n"}}{{end}}' 2>/dev/null \
        | grep -m1 '^/usr/share/nginx/html')
    echo "${dest:-/usr/share/nginx/html}"
}

composer-docker() { 
    local project_name="$(basename "$(pwd)")"
    if [ -t 0 ]; then
        # Interactive mode (TTY available)
        docker container exec -it --user "$(id -u):$(id -g)" --workdir "$(podium_container_workdir)" "$project_name" composer "$@"
    else
        # Non-interactive mode (no TTY, for scripts)
        docker container exec --user "$(id -u):$(id -g)" --workdir "$(podium_container_workdir)" "$project_name" composer "$@"
    fi
}
# Drupal's equivalent of art-docker. drush is a Composer dependency rather than
# a global binary, so it is invoked through vendor/bin relative to the workdir.
drush-docker() {
    local project_name="$(basename "$(pwd)")"
    if [ -t 0 ]; then
        docker container exec -it --user "$(id -u):$(id -g)" --workdir "$(podium_container_workdir)" "$project_name" php vendor/bin/drush "$@"
    else
        docker container exec --user "$(id -u):$(id -g)" --workdir "$(podium_container_workdir)" "$project_name" php vendor/bin/drush "$@"
    fi
}
art-docker() {
    local project_name="$(basename "$(pwd)")"
    if [ -t 0 ]; then
        # Interactive mode (TTY available)
        docker container exec -it --user "$(id -u):$(id -g)" --workdir "$(podium_container_workdir)" "$project_name" php artisan "$@"
    else
        # Non-interactive mode (no TTY, for scripts)
        docker container exec --user "$(id -u):$(id -g)" --workdir "$(podium_container_workdir)" "$project_name" php artisan "$@"
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

# Hand the configured API key to an agent CLI through the environment.
#
# Both the claude and codex CLIs REMOVED their `--api-key` flags; passing one is
# a hard error ("unknown option '--api-key'"). Lives here rather than in ai.sh
# because resume.sh builds the same argv and drifted out of sync when the fix
# landed in only one of them.
#
# The prefix guard matters: a key for the wrong provider is worse than no key,
# because it replaces the CLI's own working sign-in with one that cannot work.
# Point an agent CLI at a custom endpoint. Podium stores it as AI_API_BASE
# (`podium ai-set --api-base URL`); each CLI reads it from a different variable.
#
# This is what makes cheap and local models work: an OpenAI-compatible endpoint
# covers OpenRouter, DeepInfra, Together, Ollama, LM Studio and vLLM. Claude Code
# speaks Anthropic's shape rather than OpenAI's, so pointing it at a local model
# needs a translating proxy (LiteLLM) in front -- the variable is still the right
# way to reach it.
_export_agent_base() {
    local var="$1"
    [[ -z "$AI_API_BASE" ]] && return 0
    export "$var=$AI_API_BASE"
}

_export_agent_key() {
    local var="$1" want="$2"
    [[ -z "$AI_API_KEY" ]] && return 0
    if [[ -n "$want" && "$AI_API_KEY" != ${want}* ]]; then
        echo-yellow "Configured AI_API_KEY doesn't look like a $AI_AGENT_CLI_NAME key (expected ${want}...) - ignoring it and using the CLI's own sign-in." >&2
        return 0
    fi
    export "$var=$AI_API_KEY"
}

# Send a command to Memcached and print the reply.
#
# The memcached image ships no netcat, so this talks to the daemon over bash's
# /dev/tcp built-in from inside the container. The protocol needs CRLF line
# endings, and a trailing `quit` so the server closes the socket rather than
# leaving `cat` blocked waiting for more input.
#
# $1 = command line to send. $2 = optional payload for storage commands, which
# are two-line: the header declares the byte count, then the data follows.
memcache-send() {
    local command="$1"
    local payload="${2-}"

    if ! check-memcached; then
        echo-red "Memcached is not running. Start it with: podium start-services"
        return 1
    fi

    docker container exec -i "$MEMCACHED_CONTAINER_NAME" bash -c '
        exec 3<>/dev/tcp/127.0.0.1/11211 || exit 1
        if [ -n "$2" ]; then
            printf "%s\r\n%s\r\nquit\r\n" "$1" "$2" >&3
        else
            printf "%s\r\nquit\r\n" "$1" >&3
        fi
        cat <&3
    ' _ "$command" "$payload" | tr -d "\r"
}

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

# Set KEY=VALUE in an env file, adding the line when it isn't there yet.
#
# sudo-podium-sed-change silently does nothing when its pattern matches no line,
# so keys introduced after an install was provisioned (e.g. AI_API_BASE) would
# never persist on an existing /etc/podium-cli/.env. Upsert instead.
sudo-podium-env-set() {
    local key="$1"
    local value="$2"
    local file="$3"

    if grep -q "^$key=" "$file" 2>/dev/null; then
        sudo-podium-sed-change "/^$key=/" "$key=$value" "$file"
    else
        printf '%s=%s\n' "$key" "$value" | sudo tee -a "$file" >/dev/null
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

# Constrain a database engine to what the chosen framework actually supports.
# Source of truth is src/catalog/frameworks.json, so the rules live in one place
# instead of being scattered special cases (WordPress was hardcoded in
# new_project.sh; Django silently rewrote mongodb to mysql inside its settings
# template, which looked like data loss to anyone who asked for Mongo).
#
# Echoes the engine to use. Falls back to the framework's first supported
# engine, warning when it had to override.
#   $1 framework slug   $2 requested engine
resolve_framework_database() {
    local framework="$1" requested="$2"
    local catalog="$DEV_DIR/catalog/frameworks.json"
    [[ ! -f "$catalog" ]] && { printf '%s' "$requested"; return 0; }

    local resolved
    resolved=$(python3 - "$catalog" "$framework" "$requested" << 'PYEOF_DB'
import json, sys
catalog, framework, requested = sys.argv[1], sys.argv[2], (sys.argv[3] or "").lower()
ALIAS = {"mariadb": "mysql", "postgresql": "postgres", "pgsql": "postgres",
         "mongo": "mongodb", "sqlite3": "sqlite"}
requested = ALIAS.get(requested, requested)
fws = {f["slug"]: f for f in json.load(open(catalog))["frameworks"]}
fw = fws.get(framework)
if not fw:
    print(requested or "")
    sys.exit(0)
allowed = fw.get("databases") or []
if not allowed or not requested or requested in allowed:
    print(requested or (allowed[0] if allowed else ""))
    sys.exit(0)
print(f"{allowed[0]}\t{fw['display']}\t{fw.get('note', '')}")
PYEOF_DB
)
    if [[ "$resolved" == *$'\t'* ]]; then
        local engine display note
        IFS=$'\t' read -r engine display note <<< "$resolved"
        # Warnings MUST go to stderr: the caller captures stdout as the engine
        # name, so anything printed here would end up inside $DATABASE.
        echo-yellow "$display does not support '$requested' — using $engine." >&2
        [[ -n "$note" ]] && echo-white "  $note" >&2
        printf '%s' "$engine"
    else
        printf '%s' "$resolved"
    fi
}

# Idempotently ensure a database exists. Never errors if it already exists.
# Args: $1 = database name, $2 = database engine (mysql|postgres|mongo|"")
ensure_database() {
    local db_name="$1"
    local engine="$2"
    case "$engine" in
        sqlite|sqlite3)
            # SQLite is a file, not a server — nothing to create on a shared
            # service. The file has to live inside the project directory: that
            # is the only path bind-mounted into the container, so a database
            # anywhere else is silently destroyed when the container is
            # recreated on `podium up`, taking the user's data with it.
            # Runs with the project directory as cwd (setup_project.sh cd's in).
            local sqlite_rel="${FRAMEWORK_SQLITE_PATH:-database.sqlite}"
            echo-cyan "Ensuring SQLite database file '$sqlite_rel' exists ..."; echo-white
            mkdir -p "$(dirname "$sqlite_rel")" 2>/dev/null || true
            if [ ! -f "$sqlite_rel" ]; then
                : > "$sqlite_rel"
            fi
            chmod 664 "$sqlite_rel" 2>/dev/null || true
            echo-green "SQLite database ready: $sqlite_rel"; echo-white
            return 0
            ;;
    esac

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

# ---------------------------------------------------------------------------
# Aider argument construction
# ---------------------------------------------------------------------------
# Aider is the odd one out among the supported agents: codex/claude/gemini all
# have their own subscription login, while aider is bring-your-own key and talks
# to whatever provider the model name points at. That means AI_MODEL is
# effectively required, AI_API_KEY has to carry a provider tag, and an
# OpenAI-compatible endpoint (Ollama, LM Studio, OpenRouter, vLLM) needs
# AI_API_BASE.
#
# Fills the global AIDER_ARGS array with everything except the prompt.
build_aider_args() {
    # --yes-always auto-confirms every aider prompt. Gated like the other agents'
    # approval bypasses: consent is asked once at install time and recorded in
    # ~/.aider.conf.yml, not forced here on every run.
    AIDER_ARGS=(--no-check-update)
    [[ "${PODIUM_AI_AUTO_APPROVE:-0}" == "1" ]] && AIDER_ARGS+=(--yes-always)

    # Aider renders through a rich console that hard-wraps at the terminal width
    # and pads with trailing spaces. That corrupts any machine-readable reply —
    # a wrap landing inside a JSON string inserts a raw newline, which is
    # illegal JSON, and it's what broke `podium create`'s classifier.
    AIDER_ARGS+=(--no-pretty)

    # The other agents leave their edits in the working tree; aider commits each
    # change by default. Match the rest of Podium and leave the tree dirty.
    #
    # Aider's other git-side default is left alone: on first run in a repo it
    # appends `.aider*` to .gitignore (auto-accepted here because of
    # --yes-always). That's a visible one-line working-tree change, and without
    # it aider's history/cache files show up as untracked clutter.
    AIDER_ARGS+=(--no-auto-commits)

    # --yes-always answers "yes" to aider's "create a git repo?" prompt, which
    # would silently git-init a project that deliberately isn't one. Only let
    # aider use git when there's already a repo here.
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        AIDER_ARGS+=(--no-git)
    fi

    # Aider walks up to the nearest enclosing repo, which is not necessarily the
    # project: if the projects directory lives under a repo (a git-backed home
    # directory, say), it adopts that entire tree as the working repo. Confine
    # it to the project. Measured on one classifier call: 324 files scanned and
    # 12k tokens sent, down to 0 files and 2.5k.
    AIDER_ARGS+=(--subtree-only)

    if [[ -n "$AI_MODEL" ]]; then
        AIDER_ARGS+=("--model" "$AI_MODEL")
    fi

    if [[ -n "$AI_API_KEY" ]]; then
        # Aider wants `provider=key` (it exports PROVIDER_API_KEY). Podium
        # stores a bare key, so tag it with the provider implied by the model
        # prefix — `openai/gpt-4o` -> openai, `anthropic/...` -> anthropic.
        # An unprefixed model means OpenAI (also the right answer for a custom
        # OpenAI-compatible endpoint). A key that already contains `=` is
        # assumed to be pre-tagged and passed through untouched.
        if [[ "$AI_API_KEY" == *=* ]]; then
            AIDER_ARGS+=("--api-key" "$AI_API_KEY")
        elif [[ "$AI_MODEL" == */* ]]; then
            AIDER_ARGS+=("--api-key" "${AI_MODEL%%/*}=$AI_API_KEY")
        else
            AIDER_ARGS+=("--api-key" "openai=$AI_API_KEY")
        fi
    fi

    if [[ -n "$AI_API_BASE" ]]; then
        AIDER_ARGS+=(--openai-api-base "$AI_API_BASE")
    fi
}

# Aider has no "seed this prompt then stay interactive" flag — --message
# processes the prompt and exits. --load runs in-chat /commands at launch and
# then hands over to the user, so seed the session with `/code <prompt>`.
# Writes the file path to the global AIDER_SEED_FILE; caller removes it.
#
# /commands are dispatched a line at a time, so a multi-line prompt would lose
# everything after the first newline — flatten it.
write_aider_seed_file() {
    local prompt="$1"

    AIDER_SEED_FILE=$(mktemp "${TMPDIR:-/tmp}/podium-aider-seed.XXXXXX")
    printf '/code %s\n' "$(printf '%s' "$prompt" | tr '\n' ' ')" > "$AIDER_SEED_FILE"
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
# ---------------------------------------------------------------------------
# Project-level AGENTS.md
# ---------------------------------------------------------------------------
# Podium hands projects off to an AI CLI as a single one-off prompt rather than
# a long-lived session, so the durable context has to live on disk. This writes
# an AGENTS.md into the project that any agent can read to pick the project up
# cold.
#
# Idempotent: the generated content lives between markers. A re-run refreshes
# only that block and leaves anything the user wrote outside it untouched.
#
# Args:
#   $1  project name (required)
#   $2  optional project directory (defaults to $PROJECTS_DIR_PATH/$1)
write_project_agents_md() {
    local project_name="$1"
    local project_dir="${2:-$PROJECTS_DIR_PATH/$project_name}"
    [[ -z "$project_name" ]] && return 0
    [[ ! -d "$project_dir" ]] && return 0

    local env_file="$project_dir/.env"
    local db_conn="" db_name="" db_host=""
    if [[ -f "$env_file" ]]; then
        db_conn=$(grep -E "^[[:space:]]*DB_CONNECTION=" "$env_file" 2>/dev/null | head -1 | cut -d= -f2- | tr -d "\"' ")
        db_name=$(grep -E "^[[:space:]]*DB_DATABASE=" "$env_file" 2>/dev/null | head -1 | cut -d= -f2- | tr -d "\"' ")
        db_host=$(grep -E "^[[:space:]]*DB_HOST=" "$env_file" 2>/dev/null | head -1 | cut -d= -f2- | tr -d "\"' ")
    fi

    local db_line="none detected"
    if [[ -n "$db_conn" ]]; then
        db_line="$db_conn"
        [[ -n "$db_name" ]] && db_line="$db_line — database \`$db_name\`"
        [[ -n "$db_host" ]] && db_line="$db_line on host \`$db_host\`"
    fi

    PODIUM_PROJECT_NAME="$project_name" \
    PODIUM_PROJECT_DIR="$project_dir" \
    PODIUM_DB_LINE="$db_line" \
    python3 - "$project_dir/AGENTS.md" << 'PYAGENTS'
import os, re, sys

path = sys.argv[1]
name = os.environ["PODIUM_PROJECT_NAME"]
pdir = os.environ["PODIUM_PROJECT_DIR"]
dbline = os.environ["PODIUM_DB_LINE"]

BEGIN = "<!-- BEGIN PODIUM CONTEXT -->"
END = "<!-- END PODIUM CONTEXT -->"

block = f"""{BEGIN}
<!-- Generated by Podium. This block is regenerated automatically —
     put your own notes OUTSIDE it and they will be preserved. -->

# {name}

Managed by **Podium**, a Docker-based local development environment manager.
You are the developer on this project.

## At a glance

| | |
|---|---|
| Local URL | http://{name}/ |
| Container name | `{name}` |
| Project directory | `{pdir}` |
| Database | {dbline} |

## Working in this project

Project tooling runs **inside the container**, never on the host:

```bash
podium exec <cmd>              # run a command in the container (no TTY, automation-safe)
podium shell                   # framework-aware interactive shell / REPL
podium up {name}
podium down {name}
podium status {name}
podium supervisor restart all  # restart in-container processes
```

Shared services are already running and resolve by hostname from inside the
container: `podium-postgres`, `podium-mariadb`, `podium-redis`, `podium-mongo`,
`podium-memcached`, `podium-mailhog`.

Credentials: postgres `root`/`password`, mariadb `root`/(empty),
mongo `root`/`password`. Redis and memcached need no auth.

## Rules

- Never pass `--json-output` to a podium command — it suppresses the
  success/failure distinction so you cannot tell whether it worked.
- Do not install runtimes or services directly on the host.
- Python containers provide `python3`, not `python`.
- Use `podium supervisor restart all`, never `podium exec supervisorctl ...`.
- After changing code, restart the app before verifying:
  `podium supervisor restart all`. A running server keeps serving the code it
  started with, so a 200 from the old process can hide a broken app.
- Before reporting done, verify: `curl -sI --max-time 10 http://{name}/`
  must return 2xx or 3xx **after that restart**.

Full Podium reference for agents: `/usr/local/share/podium-cli/AGENTS.md`
(run `podium --help` for the complete command list).
{END}"""

if os.path.exists(path):
    existing = open(path, encoding="utf-8").read()
    if BEGIN in existing and END in existing:
        out = re.sub(re.escape(BEGIN) + r".*?" + re.escape(END), lambda _: block,
                     existing, count=1, flags=re.DOTALL)
    else:
        out = block + "\n\n" + existing
else:
    out = block + "\n"

open(path, "w", encoding="utf-8").write(out)
PYAGENTS
}

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

    # Write the durable handoff context into the project before invoking the
    # agent. The seed prompt only has to point at it.
    write_project_agents_md "$project_name" "$project_dir"

    if [[ -z "$seed_prompt" ]]; then
        seed_prompt="Read AGENTS.md in this directory first — it describes this Podium-managed project, its local URL, its database, and the commands to use. Then read README.md if present. The project is running at http://$project_name/. You are the developer on it."
    fi

    echo-return
    echo-cyan "Wrote AGENTS.md handoff context to $project_name."
    echo-cyan "Starting AI session in $project_name..."
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

# =============================================================================
# Folding an arbitrary repository into Podium
# =============================================================================
# `podium clone` used to force every repo through framework classification and a
# regex-based compose adapter. That works for repos shaped like Podium's own
# templates and fails for everything else: service names that don't match the
# patterns survive as bundled databases, connection strings inside DSNs are never
# rewritten, and credentials are never reconciled against the shared services.
#
# The fold replaces the guessing with a one-off AI pass that reads the actual
# repo. The deterministic parts — IP allocation, /etc/hosts, registration — stay
# in bash, because they are shared state across projects rather than judgment
# calls. See podium_fold_project below.

# Emit the live shared-service inventory as prompt-ready text: hostname, port and
# the real credentials, so the agent rewrites config to something that actually
# connects instead of inventing plausible values.
#
# Credentials mirror docker-stack/docker-compose.services.yaml. If that file
# changes, change this too — a wrong password here produces a project that looks
# adapted and cannot connect.
podium_shared_service_facts() {
    local optional="${OPTIONAL_SERVICES:-}"

    cat << EOF
ALWAYS RUNNING (use these — do not bundle your own):
  MariaDB/MySQL   host: ${MARIADB_CONTAINER_NAME:-podium-mariadb}      port: 3306   user: root   password: (empty)
  PostgreSQL      host: ${POSTGRES_CONTAINER_NAME:-podium-postgres}    port: 5432   user: root   password: password   default db: postgres
  MongoDB         host: ${MONGO_CONTAINER_NAME:-podium-mongo}          port: 27017  user: root   password: password
  Redis           host: ${REDIS_CONTAINER_NAME:-podium-redis}          port: 6379   no auth
  Memcached       host: ${MEMCACHED_CONTAINER_NAME:-podium-memcached}  port: 11211  no auth
  SMTP (Mailpit)  host: ${MAILHOG_CONTAINER_NAME:-podium-mailhog}      port: 1025   no auth   web UI on host port 8025
EOF

    if [[ " $optional " == *" minio "* ]]; then
        echo "  MinIO (S3)      host: ${MINIO_CONTAINER_NAME:-podium-minio}          port: 9000   user: ${MINIO_ROOT_USER:-root}   password: ${MINIO_ROOT_PASSWORD:-password}"
    fi
    if [[ " $optional " == *" meilisearch "* ]]; then
        echo "  Meilisearch     host: ${MEILISEARCH_CONTAINER_NAME:-podium-meilisearch}  port: 7700   master key: ${MEILI_MASTER_KEY:-podium-dev-master-key}"
    fi

    local disabled=""
    [[ " $optional " != *" minio "* ]]       && disabled="$disabled minio"
    [[ " $optional " != *" meilisearch "* ]] && disabled="$disabled meilisearch"
    if [ -n "$disabled" ]; then
        echo ""
        echo "NOT ENABLED on this machine:$disabled"
        echo "  Do not point the app at these. If the app genuinely needs one, say so in your"
        echo "  summary and tell the user to run: podium enable-service <name>"
    fi
}

# Install project dependencies based on FILES PRESENT, not on framework
# classification. This is the fix for "doesn't fit the Podium mold": the old
# gating ran npm only when FRAMEWORK_IS_NODE was set and pip only when
# FRAMEWORK_IS_PYTHON was set, so a cloned repo that classified as something else
# — or as nothing — silently got no dependencies installed.
#
# Runs inside the project container so the toolchain versions match what the app
# will actually run against, falling back to the host only when the container
# lacks the tool.
#   $1 project name
install_project_dependencies() {
    local project_name="$1"
    local workdir; workdir="$(podium_container_workdir)"
    local ran=0

    _in_container() { docker container exec --user "$(id -u):$(id -g)" --workdir "$workdir" "$project_name" "$@"; }
    _has_in_container() { docker container exec "$project_name" sh -c "command -v $1 >/dev/null 2>&1"; }

    # --- PHP -----------------------------------------------------------------
    # composer install includes dev requirements unless --no-dev is passed, so
    # this already covers "with devs".
    if [ -f "composer.json" ]; then
        echo-cyan "composer.json found — installing PHP dependencies ..."; echo-white
        if _has_in_container composer; then
            _in_container composer install --no-interaction || echo-yellow "composer install failed — continuing."
        else
            echo-yellow "composer not present in the container; skipping."
        fi
        ran=1
    fi

    # --- Node ----------------------------------------------------------------
    # Lockfile decides the package manager. Guessing npm when the repo ships a
    # pnpm or yarn lockfile produces a different dependency tree than the authors
    # tested with, which is worse than not installing.
    if [ -f "package.json" ]; then
        local pm="npm" pm_args="install --no-audit --no-fund --no-progress"
        if   [ -f "pnpm-lock.yaml" ]; then pm="pnpm"; pm_args="install"
        elif [ -f "yarn.lock" ];      then pm="yarn"; pm_args="install"
        fi
        echo-cyan "package.json found — installing Node dependencies with $pm ..."; echo-white
        if _has_in_container "$pm"; then
            _in_container "$pm" $pm_args || echo-yellow "$pm install failed — continuing."
        elif command -v "$pm" >/dev/null 2>&1; then
            echo-yellow "$pm not in the container; installing on the host instead."
            $pm $pm_args || echo-yellow "$pm install failed — continuing."
        else
            echo-yellow "$pm available neither in the container nor on the host; skipping."
        fi
        ran=1
    fi

    # --- Python --------------------------------------------------------------
    if [ -f "requirements.txt" ]; then
        echo-cyan "requirements.txt found — installing Python dependencies ..."; echo-white
        _in_container pip3 install --break-system-packages -r requirements.txt \
            || echo-yellow "pip install failed — continuing."
        ran=1
    elif [ -f "pyproject.toml" ]; then
        echo-cyan "pyproject.toml found — installing Python project ..."; echo-white
        _in_container pip3 install --break-system-packages -e . \
            || echo-yellow "pip install -e . failed — continuing."
        ran=1
    fi
    if [ -f "Pipfile" ] && [ ! -f "requirements.txt" ]; then
        echo-yellow "Pipfile found but pipenv is not managed by Podium — install manually if needed."
    fi

    unset -f _in_container _has_in_container
    [ "$ran" = "0" ] && echo-cyan "No composer.json, package.json or Python requirements found — nothing to install."
    return 0
}

# Build the pre-prompt that folds a freshly cloned repo into Podium.
#   $1 project name   $2 static IP   $3 host port
podium_fold_prompt() {
    local project_name="$1" ip="$2" port="$3"
    local upstream_note=""

    if [ -f "docker-compose.upstream.yaml" ]; then
        upstream_note="This repo SHIPPED ITS OWN COMPOSE. The original is preserved at
docker-compose.upstream.yaml — read it first; it is the authoritative description of what
services this app expects. docker-compose.yaml is Podium's automated first attempt at
adapting it and may well be wrong. Treat the upstream file as the source of truth and
rewrite docker-compose.yaml from it."
    else
        upstream_note="This repo shipped NO compose file. docker-compose.yaml was generated by
Podium from a framework template. Verify it actually matches how this app runs — check for a
Procfile, Dockerfile, Makefile, CI config or README run instructions before trusting it."
    fi

    cat << EOF
You are folding a freshly cloned repository into Podium. Work only in this directory.

## What Podium is

Podium runs many projects side by side on one machine against a set of SHARED backing
services. Every project is a container on the external Docker network 'podium-cli_vpc',
reachable by hostname. Projects do NOT run their own database, cache or mail container —
they connect to the shared ones, which are already running.

## This project's identity (already allocated — do not change these)

  Project name : $project_name
  Hostname/URL : http://$project_name/   (resolves via /etc/hosts to $ip)
  Static IP    : $ip
  Host port    : $port

## Shared services available

$(podium_shared_service_facts)

## Your job

$upstream_note

## The web service MUST use a Podium base image (this is the important one)

Use one of these for the main application service:

  canebaycomputers/cbc:nginx-php8      PHP 8.3 + nginx + supervisor
  canebaycomputers/cbc:nginx-python3   Python 3 + nginx + supervisor
  canebaycomputers/cbc:nginx-node      Node 22 + nginx + supervisor

Pick the one matching the app's language and DISCARD the upstream image or Dockerfile for
that service. This is not cosmetic. Podium's tooling — 'podium php', 'podium python',
'podium npm', 'podium composer', 'podium shell' — runs
'docker exec --user developer' against this container. An arbitrary upstream image has no
'developer' user, so every one of those commands fails outright. These images also serve the
app through nginx on port 80, which is what makes http://$project_name/ resolve at all; an
app listening on its own port in its own image is simply unreachable.

Adapt the app to the image, not the image to the app: put its start command under supervisor
and let nginx serve or proxy it, exactly as the upstream Dockerfile's CMD would have run it.

These three images are deliberately broad — nginx, supervisor and the database drivers are
already compiled in — and they cover essentially any PHP, Python or Node web application.
**If the app is written in PHP, Python or Node, use the matching image. No exceptions.**

A pinned version is NOT a reason to escape. A repo asking for Node 18, Python 3.9 or PHP 8.1
still runs on these images in all but pathological cases. Try it and let it fail before
concluding otherwise — an unnecessary escape silently costs the user every 'podium' command
for the life of the project.

ESCAPE HATCH — reserved for a genuinely different runtime that these images cannot execute at
all: a compiled binary (Go, Rust), or a JVM/.NET application. Nothing else qualifies. If you
take it, keep the upstream image, make it listen on port 80, and state prominently in your
summary that 'podium php/python/npm/composer/shell' will NOT work for this project and why.

Helper services (workers, schedulers) may keep their own images — the passthrough commands
only target the main container.

Produce a working docker-compose.yaml and matching app configuration:

1. **Delete bundled backing services.** Any database, cache, queue broker, search or mail
   container defined in the compose must go, replaced by the shared equivalents above.
   mysql AND mariadb both map to ${MARIADB_CONTAINER_NAME:-podium-mariadb}. Keep application
   services (web, worker, scheduler, websocket) — those are the app itself.

2. **Rewrite every reference to a deleted service.** This is the part that is usually missed:
   look inside connection strings and DSNs, not just plain host variables. A value like
   DATABASE_URL=postgres://app:secret@db:5432/app must become
   postgres://root:password@${POSTGRES_CONTAINER_NAME:-podium-postgres}:5432/<dbname>.
   Search the whole repo — .env, .env.example, config files, settings modules, and any
   defaults compiled into the app.

3. **Use the real shared credentials** listed above. Do not keep the upstream compose's
   invented usernames and passwords; those accounts do not exist on the shared servers.

4. **Wire the networking exactly:**
   - The web service gets: container_name: $project_name
   - and a static address on the shared network:
       networks:
         default:
           ipv4_address: $ip
   - Other services attach with a plain: networks: [default]
   - The network block at the bottom must be:
       networks:
         default:
           external: true
           name: podium-cli_vpc
   - Do NOT publish ports with 'ports:' on any service. Projects are reached by hostname on
     the shared network; published ports collide with other Podium projects.

5. **Create the database if the app needs one.** The shared servers are running but this
   project's database may not exist yet. Use the project name with dashes replaced by
   underscores unless the app's config clearly expects a different name.

   You cannot run migrations yourself — the container is not up while you work. Instead, end
   your summary with a MIGRATE: line giving the exact command, e.g.
     MIGRATE: podium art migrate
     MIGRATE: podium python manage.py migrate
   or 'MIGRATE: none' if the app has no migrations. This is the only way the user finds out
   how to finish setup, so do not omit it.

6. **Do not run** podium new, podium clone, podium install, or create another project.
   Do not start containers yourself — Podium starts them after you finish.

## When you are done

Print a short summary: which services you removed, what you pointed them at, which files you
edited beyond docker-compose.yaml, and anything you could not resolve that the user must
handle. Be explicit about guesses — a wrong guess stated plainly is far more useful than a
confident one.
EOF
}

# Run the fold, then verify it. Verification matters: without it we would have
# traded a bad deterministic adaptation for an unverified generated one.
#   $1 project name   $2 static IP   $3 host port
podium_fold_project() {
    local project_name="$1" ip="$2" port="$3"
    local ai_script="$DEV_DIR/scripts/ai.sh"

    if [ ! -f "$ai_script" ]; then
        echo-yellow "ai.sh not found — skipping fold."
        return 1
    fi

    echo-return
    echo-cyan "Folding $project_name into Podium with the AI agent ($AI_AGENT) ..."
    echo-white "This reads the repo and rewrites docker-compose.yaml and app config."
    echo-return

    local prompt; prompt="$(podium_fold_prompt "$project_name" "$ip" "$port")"

    if [[ "$JSON_OUTPUT" == "1" ]]; then
        bash "$ai_script" "$prompt" > /tmp/podium-fold-$$.log 2>&1 || true
    else
        bash "$ai_script" "$prompt" || true
    fi

    # --- verify -------------------------------------------------------------
    if [ ! -f "docker-compose.yaml" ] && [ ! -f "docker-compose.yml" ]; then
        echo-red "Fold produced no docker-compose file."
        return 1
    fi

    if ! docker compose config >/dev/null 2>&1; then
        echo-yellow "docker compose config rejected the generated file — asking the agent to fix it ..."
        local err; err="$(docker compose config 2>&1 | head -20)"
        bash "$ai_script" "The docker-compose.yaml you just wrote is invalid. Fix it in place.
Do not change the networking contract described earlier: external network podium-cli_vpc,
container_name $project_name, ipv4_address $ip, and no published ports.

docker compose config reported:
$err" || true

        if ! docker compose config >/dev/null 2>&1; then
            echo-red "docker-compose.yaml is still invalid after one repair attempt."
            echo-white "The original is preserved at docker-compose.upstream.yaml."
            return 1
        fi
    fi

    # Guard the two contract items an agent most often drops. These are cheap to
    # check and expensive to debug later: a project on the wrong network appears
    # to start and then cannot reach any shared service.
    if ! grep -q "podium-cli_vpc" docker-compose.yaml 2>/dev/null; then
        echo-yellow "Warning: generated compose does not reference podium-cli_vpc — shared services will be unreachable."
    fi
    if ! grep -q "$ip" docker-compose.yaml 2>/dev/null; then
        echo-yellow "Warning: generated compose does not pin $ip — http://$project_name/ may not resolve to this project."
    fi

    echo-green "Fold complete and compose validates."
    return 0
}

# Report which `podium <tool>` passthroughs will actually work against this
# project's container. Run AFTER the container is up.
#
# Every passthrough is `docker exec --user developer`, so a project on a
# non-Podium image loses all of them at once — and the failure surfaces later as
# a confusing "unable to find user: developer" rather than at setup time. Saying
# it plainly here is the difference between a known limitation and a bug report.
#   $1 project name
podium_report_container_capabilities() {
    local project_name="$1"

    docker container inspect "$project_name" >/dev/null 2>&1 || return 0

    if ! docker container exec "$project_name" id developer >/dev/null 2>&1; then
        echo-return
        echo-yellow "Heads up: this project runs on a non-Podium image (no 'developer' user)."
        echo-yellow "These will NOT work for it:"
        echo-white  "  podium php / python / npm / node / composer / art / shell / exec"
        echo-white  "Use 'docker exec -it $project_name <cmd>' instead, or re-run with"
        echo-white  "  podium clone ... --image canebaycomputers/cbc:nginx-php8"
        echo-white  "to force a Podium base image."
        return 0
    fi

    local available="" missing=""
    local tool
    for tool in php python3 node npm composer; do
        if docker container exec "$project_name" sh -c "command -v $tool >/dev/null 2>&1"; then
            available="$available $tool"
        else
            missing="$missing $tool"
        fi
    done
    [ -n "$available" ] && echo-green "Container toolchain:$available"
    [ -n "$missing" ]   && echo-cyan  "Not in this image:$missing (expected — images are language-specific)"
    return 0
}

# Pre-flight compatibility check, run on a freshly cloned repo BEFORE the fold.
#
# Podium serves every project from one of three base images (PHP 8.3, Python 3,
# Node 22). That is not a soft preference — the passthrough commands exec as the
# 'developer' user and nginx serves on port 80, neither of which survives a
# foreign image. So "is this repo PHP, Python or Node?" is the whole
# compatibility question, and it is answerable from the file tree.
#
# Catching it here is worth real money: without this, an incompatible repo burns
# a full AI fold and leaves a registered project that can never start.
#
# Echoes findings. Returns 0 compatible, 1 incompatible.
podium_preflight_check() {
    local hard="" soft="" lang=""

    # --- is there anything here at all? -------------------------------------
    if [ -z "$(ls -A . 2>/dev/null | grep -v '^\.git$')" ]; then
        echo-red "Repository is empty."
        return 1
    fi

    # --- primary runtime ----------------------------------------------------
    # Order matters: a Rails app ships a package.json for assets, so the
    # disqualifying markers are checked before the supported ones.
    if   [ -f "go.mod" ];                                    then hard="Go (go.mod)"
    elif [ -f "Cargo.toml" ];                                then hard="Rust (Cargo.toml)"
    elif [ -f "pom.xml" ] || ls build.gradle* >/dev/null 2>&1; then hard="Java/Kotlin (Maven/Gradle)"
    elif ls ./*.csproj ./*.sln >/dev/null 2>&1;              then hard=".NET"
    elif [ -f "mix.exs" ];                                   then hard="Elixir (mix.exs)"
    elif [ -f "Gemfile" ] || [ -f "config.ru" ];             then hard="Ruby (Gemfile) — Podium has no Ruby image"
    elif [ -f "pubspec.yaml" ];                              then hard="Dart/Flutter"
    elif [ -d "android" ] && [ -d "ios" ];                   then hard="a mobile app, not a web app"
    fi

    if [ -z "$hard" ]; then
        if   [ -f "composer.json" ] || [ -f "artisan" ] || [ -f "index.php" ] || [ -f "wp-config.php" ]; then
            lang="PHP"
        elif [ -f "manage.py" ] || [ -f "requirements.txt" ] || [ -f "pyproject.toml" ] || [ -f "Pipfile" ]; then
            lang="Python"
        elif [ -f "package.json" ]; then
            lang="Node"
        elif ls ./*.php >/dev/null 2>&1;                     then lang="PHP"
        elif ls ./*.py  >/dev/null 2>&1;                     then lang="Python"
        else
            hard="no recognisable PHP, Python or Node application"
        fi
    fi

    if [ -n "$hard" ]; then
        echo-return
        echo-red   "Incompatible with Podium: this repo is $hard."
        echo-white "Podium serves projects from PHP 8.3, Python 3 or Node 22 base images. Its"
        echo-white "tooling (podium php/python/npm/composer/shell) execs as the 'developer' user"
        echo-white "inside those images, and nginx serves the app on port 80 — neither works on a"
        echo-white "foreign runtime."
        echo-white ""
        echo-white "Clone it outside Podium and run it with its own docker-compose, or re-run with"
        echo-white "  --no-preflight   to attempt it anyway (expect the passthrough commands to fail)"
        return 1
    fi

    # --- soft warnings: proceed, but say what will need attention ------------
    local compose=""
    [ -f "docker-compose.yaml" ] && compose="docker-compose.yaml"
    [ -f "docker-compose.yml" ]  && compose="docker-compose.yml"

    if [ -n "$compose" ]; then
        local unsupported
        unsupported=$(grep -ioE 'image:[[:space:]]*[a-z0-9./_-]*(elasticsearch|opensearch|rabbitmq|kafka|clickhouse|cassandra|neo4j|influxdb|nats|vault|consul)' "$compose" 2>/dev/null \
                      | sed -E 's/.*(elasticsearch|opensearch|rabbitmq|kafka|clickhouse|cassandra|neo4j|influxdb|nats|vault|consul).*/\1/I' | sort -u | tr '\n' ' ')
        [ -n "$unsupported" ] && soft="$soft\n  • Needs services Podium does not provide:$unsupported\n    These stay as project-local containers; they will not be shared."

        if grep -qE '(minio|s3)' "$compose" 2>/dev/null && [[ " ${OPTIONAL_SERVICES:-} " != *" minio "* ]]; then
            soft="$soft\n  • Wants object storage. Enable it first:  podium enable-service minio"
        fi
        if grep -qiE '(meilisearch|typesense)' "$compose" 2>/dev/null && [[ " ${OPTIONAL_SERVICES:-} " != *" meilisearch "* ]]; then
            soft="$soft\n  • Wants a search engine. Enable it first:  podium enable-service meilisearch"
        fi
        if grep -qE 'capabilities:.*gpu|runtime:[[:space:]]*nvidia' "$compose" 2>/dev/null; then
            soft="$soft\n  • Requests GPU access. Podium projects run CPU-only."
        fi
        grep -q 'laravel/sail' "$compose" 2>/dev/null && \
            soft="$soft\n  • Laravel Sail compose — it will be discarded for a Podium image (Sail cannot build before composer install)."
    fi

    [ -f ".gitmodules" ] && soft="$soft\n  • Has git submodules — run 'git submodule update --init' if the app needs them."
    if [ -f "package.json" ] && grep -qE '"(workspaces|nx|turbo)"' package.json 2>/dev/null; then
        soft="$soft\n  • Looks like a monorepo — the app to serve may be ambiguous; check the result."
    fi

    echo-green "Pre-flight OK — detected a $lang application."
    if [ -n "$soft" ]; then
        echo-yellow "Worth knowing before it is set up:"
        printf "%b\n" "$soft" | sed '/^$/d'
    fi
    return 0
}

# =============================================================================
# Agent autonomy consent
# =============================================================================
# Podium runs agents non-interactively: `podium create` and `podium clone --fold`
# hand a prompt to the agent and expect it to edit files and finish without a
# human at the keyboard. That requires the agent to skip its own per-action
# approval prompts.
#
# Podium used to force this by passing --dangerously-skip-permissions and
# --dangerously-bypass-approvals-and-sandbox on every invocation. That is a
# reasonable personal default and an unreasonable thing to impose on someone
# else's machine without asking — a tool that silently disables another tool's
# safety prompts is a fair thing to be angry about.
#
# So the flags are gone from the invocation. Instead we ASK ONCE, at install
# time, and record the answer in the agent's OWN config file, where the user can
# see it, audit it and revoke it with the agent's own documentation.
#
#   $1 agent name
podium_offer_agent_autonomy() {
    local agent="$1"
    local cfg desc

    case "$agent" in
        claude) cfg="$HOME/.claude/settings.json"; desc='"permissions": {"defaultMode": "bypassPermissions"}' ;;
        codex)  cfg="$HOME/.codex/config.toml";    desc='approval_policy = "never", sandbox_mode = "danger-full-access"' ;;
        gemini) cfg="$HOME/.gemini/settings.json"; desc='"autoAccept": true' ;;
        qwen)   cfg="$HOME/.qwen/settings.json";   desc='"autoAccept": true' ;;
        aider)  cfg="$HOME/.aider.conf.yml";       desc='yes-always: true' ;;
        *) return 0 ;;
    esac

    # Caller already stated intent (--allow-unattended / --no-allow-unattended),
    # so asking again would be noise.
    [ "${PODIUM_UNATTENDED_EXPLICIT:-0}" = "1" ] && return 0

    # Never prompt in automation — silence there means "no", which is the safe
    # default for a permissions question.
    if [[ "$JSON_OUTPUT" == "1" ]] || [ ! -t 0 ]; then
        echo-cyan "Note: $agent may prompt for approval on each action, which stalls non-interactive"
        echo-cyan "runs like 'podium create'. Run 'podium ai-set --agent $agent' from a terminal to set this up."
        return 0
    fi

    echo-return
    echo-yellow "One question about how $agent should run under Podium."
    echo-white  ""
    echo-white  "Podium drives the agent non-interactively — 'podium create' and 'podium clone'"
    echo-white  "hand it a task and expect it to finish unattended. By default $agent asks for"
    echo-white  "approval before each file edit or command, which stalls those runs."
    echo-white  ""
    echo-white  "Podium can record your preference in $agent's own config:"
    echo-white  "  $cfg"
    echo-white  "  $desc"
    echo-white  ""
    echo-white  "This lets the agent edit files and run commands in your projects WITHOUT asking."
    echo-white  "That is what makes Podium's AI features work, and it is a real reduction in"
    echo-white  "safety — the agent can change anything your user account can. It is written to"
    echo-white  "$agent's own config, so you can inspect or undo it there at any time."
    echo-white  ""
    echo-white  "Say no and Podium still works; the agent will just prompt you, and unattended"
    echo-white  "commands may stall waiting for input."
    echo-return

    local answer=""
    read -r -p "Allow $agent to run unattended? [y/N] " answer
    case "$answer" in
        [Yy]*) ;;
        *) echo-cyan "Left $agent's settings alone. You can change this later in $cfg."
           return 0 ;;
    esac

    podium_write_agent_autonomy "$agent" "$cfg"
}

# Write the autonomy setting into the agent's own config, merging rather than
# clobbering — these files hold the user's model choice, hooks and auth.
#   $1 agent   $2 config path
podium_write_agent_autonomy() {
    local agent="$1" cfg="$2"
    mkdir -p "$(dirname "$cfg")"

    case "$agent" in
        claude|gemini|qwen)
            local key="permissions" 
            [ "$agent" = "claude" ] || key="autoAccept"
            if ! command -v python3 >/dev/null 2>&1; then
                echo-yellow "python3 not available — set this manually in $cfg."
                return 1
            fi
            python3 - "$cfg" "$agent" << 'PYEOF'
import json, os, sys
path, agent = sys.argv[1], sys.argv[2]
data = {}
if os.path.exists(path):
    try:
        with open(path) as f:
            data = json.load(f) or {}
    except Exception:
        # Never destroy a config we cannot parse.
        print("UNPARSEABLE"); sys.exit(2)
if agent == "claude":
    data.setdefault("permissions", {})["defaultMode"] = "bypassPermissions"
else:
    data["autoAccept"] = True
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print("OK")
PYEOF
            local rc=$?
            if [ $rc -eq 2 ]; then
                echo-yellow "$cfg exists but is not valid JSON — leaving it untouched."
                echo-white  "Add this yourself once it parses."
                return 1
            fi
            ;;
        codex)
            # Replace the key if present, append if not. Append-only looks safer
            # but silently no-ops when the key already exists with another value
            # — "allow" would report success and change nothing. Only these two
            # keys are touched, so other settings and [projects.*] tables survive.
            touch "$cfg"
            if grep -qE '^[[:space:]]*approval_policy' "$cfg" 2>/dev/null; then
                podium-sed 's|^[[:space:]]*approval_policy[[:space:]]*=.*|approval_policy = "never"|' "$cfg"
            else
                echo 'approval_policy = "never"' >> "$cfg"
            fi
            if grep -qE '^[[:space:]]*sandbox_mode' "$cfg" 2>/dev/null; then
                podium-sed 's|^[[:space:]]*sandbox_mode[[:space:]]*=.*|sandbox_mode = "danger-full-access"|' "$cfg"
            else
                echo 'sandbox_mode = "danger-full-access"' >> "$cfg"
            fi
            ;;
        aider)
            touch "$cfg"
            if grep -qE '^[[:space:]]*yes-always' "$cfg" 2>/dev/null; then
                podium-sed 's|^[[:space:]]*yes-always[[:space:]]*:.*|yes-always: true|' "$cfg"
            else
                echo 'yes-always: true' >> "$cfg"
            fi
            ;;
    esac

    echo-green "Recorded in $cfg — $agent will now run unattended under Podium."
    echo-white  "Undo it by editing that file."
    return 0
}

# Read whether an agent is currently configured to run unattended.
# Echoes: true | false | unknown   (never errors — the GUI renders "unknown"
# as unchecked-with-a-note, which is more useful than a failed call.)
#   $1 agent
podium_read_agent_autonomy() {
    local agent="$1" cfg

    case "$agent" in
        claude) cfg="$HOME/.claude/settings.json" ;;
        codex)  cfg="$HOME/.codex/config.toml" ;;
        gemini) cfg="$HOME/.gemini/settings.json" ;;
        qwen)   cfg="$HOME/.qwen/settings.json" ;;
        aider)  cfg="$HOME/.aider.conf.yml" ;;
        *) echo "unknown"; return 0 ;;
    esac

    [ -f "$cfg" ] || { echo "false"; return 0; }

    case "$agent" in
        claude|gemini|qwen)
            command -v python3 >/dev/null 2>&1 || { echo "unknown"; return 0; }
            python3 - "$cfg" "$agent" << 'PYEOF' 2>/dev/null || echo "unknown"
import json, sys
path, agent = sys.argv[1], sys.argv[2]
try:
    with open(path) as f:
        data = json.load(f) or {}
except Exception:
    print("unknown"); sys.exit(0)
if agent == "claude":
    print("true" if data.get("permissions", {}).get("defaultMode") == "bypassPermissions" else "false")
else:
    print("true" if data.get("autoAccept") is True else "false")
PYEOF
            ;;
        codex)
            if grep -qE '^[[:space:]]*approval_policy[[:space:]]*=[[:space:]]*"never"' "$cfg" 2>/dev/null; then
                echo "true"
            else
                echo "false"
            fi
            ;;
        aider)
            if grep -qE '^[[:space:]]*yes-always[[:space:]]*:[[:space:]]*true' "$cfg" 2>/dev/null; then
                echo "true"
            else
                echo "false"
            fi
            ;;
    esac
}

# Turn unattended mode back off.
#
# Sets explicit safe values rather than deleting lines. Deleting looks tidier but
# is dangerous here: a user may have set these keys themselves before Podium ever
# ran (approval_policy and sandbox_mode commonly are), and removing them would
# silently destroy their own configuration. Setting a value is honest about what
# changed, and every change is printed.
#   $1 agent
podium_revoke_agent_autonomy() {
    local agent="$1" cfg

    case "$agent" in
        claude) cfg="$HOME/.claude/settings.json" ;;
        codex)  cfg="$HOME/.codex/config.toml" ;;
        gemini) cfg="$HOME/.gemini/settings.json" ;;
        qwen)   cfg="$HOME/.qwen/settings.json" ;;
        aider)  cfg="$HOME/.aider.conf.yml" ;;
        *) echo-yellow "Unknown agent '$agent'."; return 1 ;;
    esac

    if [ ! -f "$cfg" ]; then
        echo-cyan "$cfg does not exist — $agent already prompts for approval."
        return 0
    fi

    case "$agent" in
        claude|gemini|qwen)
            command -v python3 >/dev/null 2>&1 || { echo-yellow "python3 unavailable — edit $cfg by hand."; return 1; }
            python3 - "$cfg" "$agent" << 'PYEOF'
import json, sys
path, agent = sys.argv[1], sys.argv[2]
try:
    with open(path) as f:
        data = json.load(f) or {}
except Exception:
    print("UNPARSEABLE"); sys.exit(2)
if agent == "claude":
    if data.get("permissions", {}).get("defaultMode") == "bypassPermissions":
        data["permissions"]["defaultMode"] = "default"
else:
    data["autoAccept"] = False
with open(path, "w") as f:
    json.dump(data, f, indent=2); f.write("\n")
print("OK")
PYEOF
            [ $? -eq 2 ] && { echo-yellow "$cfg is not valid JSON — left untouched."; return 1; }
            ;;
        codex)
            if grep -qE '^[[:space:]]*approval_policy' "$cfg"; then
                podium-sed 's|^[[:space:]]*approval_policy[[:space:]]*=.*|approval_policy = "on-request"|' "$cfg"
            fi
            if grep -qE '^[[:space:]]*sandbox_mode' "$cfg"; then
                podium-sed 's|^[[:space:]]*sandbox_mode[[:space:]]*=.*|sandbox_mode = "workspace-write"|' "$cfg"
                echo-yellow "Note: sandbox_mode was also reset to \"workspace-write\"."
            fi
            ;;
        aider)
            if grep -qE '^[[:space:]]*yes-always' "$cfg"; then
                podium-sed 's|^[[:space:]]*yes-always[[:space:]]*:.*|yes-always: false|' "$cfg"
            fi
            ;;
    esac

    echo-green "$agent will prompt for approval again (updated $cfg)."
    return 0
}

# Resolve an agent's config path. Single source of truth — the path appears in
# offer/write/read/revoke and drifts the moment one of them is edited alone.
podium_agent_config_path() {
    case "$1" in
        claude) echo "$HOME/.claude/settings.json" ;;
        codex)  echo "$HOME/.codex/config.toml" ;;
        gemini) echo "$HOME/.gemini/settings.json" ;;
        qwen)   echo "$HOME/.qwen/settings.json" ;;
        aider)  echo "$HOME/.aider.conf.yml" ;;
        *) return 1 ;;
    esac
}

# Non-interactive "allow" — the counterpart to podium_revoke_agent_autonomy, for
# --allow-unattended and for the GUI, which collects consent in its own UI.
podium_allow_agent_autonomy() {
    local agent="$1" cfg
    cfg="$(podium_agent_config_path "$agent")" || { echo-yellow "Unknown agent '$agent'."; return 1; }
    podium_write_agent_autonomy "$agent" "$cfg"
}
