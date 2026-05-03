#!/bin/bash

set -e


ORIG_DIR=$(pwd)

cd "$(dirname "$(realpath "$0")")"

cd ..

DEV_DIR=$(pwd)

source scripts/pre_check.sh

# Initialize variables
JSON_OUTPUT="${JSON_OUTPUT:-}"
NO_COLOR="${NO_COLOR:-}"
REPOSITORY=""
PROJECT_NAME=""
OVERWRITE_DOCKER_COMPOSE=""
DATABASE_ENGINE=""
DISPLAY_NAME=""
PROJECT_DESCRIPTION=""
PROJECT_EMOJI=""
CREATE_GITHUB=""
ORGANIZATION=""
NO_STORAGE_SYMLINK=0
REQUEST_FORK=0
FORK_USED=0
GIT_CLONE_ARGS=()

# Function to display usage
usage() {
    echo-white "Usage: $0 <repository> [OPTIONS] [project_name]"
    echo-white "Clone a Git repository and set up as Podium project"
    echo-white ""
    echo-white "Arguments:"
    echo-white "  repository        Git repository URL to clone"
    echo-white "  project_name      Optional: Local project name (defaults to repo name)"
    echo-white ""
    echo-white "Options:"
    echo-white "  --json-output                Output results in JSON format"
    echo-white "  --no-colors                  Disable colored output"
    echo-white "  --debug                      Enable debug logging to /tmp/podium-cli-debug.log"
    echo-white "  --overwrite-docker-compose   Overwrite existing docker-compose.yaml without prompting"
    echo-white "  --database ENGINE            Database type: mysql, postgres, mongo (default: mysql)"
    echo-white "  --display-name NAME          Display name for project (optional)"
    echo-white "  --description TEXT           Project description (optional)"
    echo-white "  --emoji EMOJI                Project emoji (default: 🚀)"
    echo-white "  --no-github                  Skip GitHub repository creation (default)"
    echo-white "  --github                     Create GitHub repository in user account"
    echo-white "  --github-org ORG             Create GitHub repository in organization"
    echo-white "  --no-storage-symlink         Skip creating public/storage symlink (Laravel)"
    echo-white "  --framework FRAMEWORK        Force framework detection (laravel, wordpress, php, fastapi, django, express, nestjs, fastify, node)"
    echo-white "  --fork                       Prefer forking GitHub repo via gh (non-interactive)"
    echo-white "  --branch NAME                Check out only the given branch (passed to git clone)"
    echo-white "  --single-branch              Clone only the history leading to the branch tip (git clone --single-branch)"
    echo-white "  --help                       Show this help message"
    
    error "usage" 1
}

# Capture original arguments for debug logging
ORIGINAL_ARGS="$*"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --json-output)
            JSON_OUTPUT=1
            shift
            ;;
        --no-colors)
            NO_COLOR=1
            shift
            ;;
        --overwrite-docker-compose)
            OVERWRITE_DOCKER_COMPOSE=1
            shift
            ;;
        --database)
            if [ -n "$2" ] && [[ ! "$2" =~ ^-- ]]; then
                DATABASE_ENGINE="$2"
                shift 2
            else
                error "Error: --database requires a database type"
            fi
            ;;
        --display-name)
            if [ -n "$2" ] && [[ ! "$2" =~ ^-- ]]; then
                DISPLAY_NAME="$2"
                shift 2
            else
                error "Error: --display-name requires a name"
            fi
            ;;
        --description)
            if [ -n "$2" ] && [[ ! "$2" =~ ^-- ]]; then
                PROJECT_DESCRIPTION="$2"
                shift 2
            else
                error "Error: --description requires a description text"
            fi
            ;;
        --emoji)
            if [ -n "$2" ] && [[ ! "$2" =~ ^-- ]]; then
                PROJECT_EMOJI="$2"
                shift 2
            else
                error "Error: --emoji requires an emoji"
            fi
            ;;
        --no-storage-symlink)
            NO_STORAGE_SYMLINK=1
            shift
            ;;
        --no-github)
            CREATE_GITHUB="no"
            shift
            ;;
        --github)
            CREATE_GITHUB="yes"
            shift
            ;;
        --github-org)
            CREATE_GITHUB="org"
            if [ -n "$2" ] && [[ ! "$2" =~ ^-- ]]; then
                ORGANIZATION="$2"
                shift 2
            else
                error "Error: --github-org requires an organization name"
            fi
            ;;
        --framework)
            if [ -n "$2" ] && [[ ! "$2" =~ ^-- ]]; then
                FORCED_FRAMEWORK="$2"
                shift 2
            else
                error "Error: --framework requires a framework name"
            fi
            ;;
        --fork)
            REQUEST_FORK=1
            shift
            ;;
        --branch)
            if [ -n "$2" ] && [[ ! "$2" =~ ^-- ]]; then
                GIT_CLONE_ARGS+=("--branch" "$2")
                shift 2
            else
                error "Error: --branch requires a branch name"
            fi
            ;;
        --single-branch)
            GIT_CLONE_ARGS+=("--single-branch")
            shift
            ;;
        --debug)
            DEBUG=1
            shift
            ;;
        --help)
            usage
            ;;
        -*)
            error "Unknown option: $1"
            ;;
        *)
            if [ -z "$REPOSITORY" ]; then
                REPOSITORY="$1"
            elif [ -z "$PROJECT_NAME" ]; then
                PROJECT_NAME="$1"
            else
                error "Too many arguments"
            fi
            shift
            ;;
    esac
done

# Helper to detect GitHub repository URLs
is_github_repo() {
    local repo_url="$1"
    if [[ "$repo_url" =~ github\.com[:/].+ ]]; then
        return 0
    fi
    return 1
}

# Initialize debug logging
debug "Script started: clone_project.sh with args: $ORIGINAL_ARGS"

# Check if repository argument is provided
if [ -z "$REPOSITORY" ]; then
    error "Error: Repository is required."
fi

# Normalize GitHub shorthand (owner/repo or owner/repo.git) into full HTTPS URL
if ! is_github_repo "$REPOSITORY"; then
    if [[ "$REPOSITORY" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+(\.git)?$ ]]; then
        REPOSITORY="https://github.com/$REPOSITORY"
    fi
fi

# Validate GitHub options in JSON mode
if [[ "$JSON_OUTPUT" == "1" ]]; then
    # GitHub organization validation
    if [ -z "$CREATE_GITHUB" ]; then
        CREATE_GITHUB="no"
    elif [ "$CREATE_GITHUB" = "org" ] && [ -z "$ORGANIZATION" ]; then
        json_error "organization is required when using --github-org"
    fi
    
    # GitHub CLI validation
    if [ "$CREATE_GITHUB" != "no" ]; then
        if ! command -v gh >/dev/null 2>&1; then
            json_error "GitHub CLI (gh) is not installed. Install it first or remove --github option"
        elif ! gh auth status >/dev/null 2>&1; then
            json_error "GitHub CLI (gh) is not authenticated. Run 'gh auth login' first or remove --github option"
        fi
    fi
else
    # Interactive mode - check GitHub CLI availability and warn if not available
    if [ "$CREATE_GITHUB" != "no" ]; then
        if ! command -v gh >/dev/null 2>&1; then
            echo-yellow "Warning: GitHub CLI (gh) is not installed."
            echo-yellow "GitHub repository creation has been disabled."
            echo-white "To enable GitHub integration, install gh CLI and run 'gh auth login'"
            CREATE_GITHUB="no"
        elif ! gh auth status >/dev/null 2>&1; then
            echo-yellow "Warning: GitHub CLI (gh) is not authenticated."
            echo-yellow "GitHub repository creation has been disabled."
            echo-white "To enable GitHub integration, run 'gh auth login'"
            CREATE_GITHUB="no"
        fi
    fi
fi


# Set project name
if [ -z "$PROJECT_NAME" ]; then

    PROJECT_NAME=$(basename -s .git "$REPOSITORY")

fi


# Display the provided arguments
echo-return
echo-white "Repository: $REPOSITORY"
echo-white "Project Name: $PROJECT_NAME"

# Convert to lowercase, replace spaces with dashes, and remove non-alphanumeric characters (macOS-compatible)
if [[ "$OSTYPE" == "darwin"* ]]; then
    PROJECT_NAME=$(echo "$PROJECT_NAME" | LC_ALL=C tr '[:upper:]' '[:lower:]' | LC_ALL=C tr ' ' '-' | LC_ALL=C tr -cd 'a-z0-9-_')
else
    PROJECT_NAME=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-_')
fi

# Navigate to the configured projects directory (from pre_check)
cd "$PROJECTS_DIR_PATH"

if [ -d "$PROJECT_NAME" ]; then
    error "Error: Project name already exists."
fi

echo-return

# Decide whether to fork via GitHub CLI
FORK_CHOICE=""
if is_github_repo "$REPOSITORY"; then
    # Non-interactive flag: always prefer fork when possible
    if [[ "$REQUEST_FORK" -eq 1 ]]; then
        if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
            FORK_USED=1
        else
            # gh not available or not authenticated; fall back to clone
            echo-yellow "GitHub CLI (gh) is not installed or not authenticated. Cloning original repository instead of forking."
            FORK_USED=0
        fi
    # Interactive prompt (only when no explicit GitHub options are set)
    elif [[ "$JSON_OUTPUT" != "1" ]] && [ -z "$CREATE_GITHUB" ]; then
        if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
            echo-cyan "GitHub repository detected."
            echo-white "How would you like to work with this repository?"
            echo-white "1) Work directly with the original repository"
            echo-white "2) Fork to your GitHub account and work from the fork"
            echo-white "3) Create a new private GitHub repository for this project (no fork)"
            echo-yellow -n "Enter your choice (1-3): "
            read FORK_CHOICE
            
            case "$FORK_CHOICE" in
                1)
                    FORK_USED=0
                    CREATE_GITHUB="no"
                    ;;
                2)
                    FORK_USED=1
                    CREATE_GITHUB="no"
                    ;;
                3)
                    FORK_USED=0
                    CREATE_GITHUB="yes"
                    ;;
                *)
                    FORK_USED=0
                    CREATE_GITHUB="no"
                    ;;
            esac
        fi
    fi
fi

# Clone repository (or fork via GitHub CLI if requested and available)
if [[ "$FORK_USED" -eq 1 ]]; then
    echo-cyan "Forking repository on GitHub and cloning your fork..."
    
    if [[ "$JSON_OUTPUT" == "1" ]]; then
        if ! gh repo fork "$REPOSITORY" --clone > /dev/null 2>&1; then
            echo-yellow "GitHub fork failed; falling back to cloning original repository."
            FORK_USED=0
        fi
    else
        if ! gh repo fork "$REPOSITORY" --clone; then
            echo-yellow "GitHub fork failed; falling back to cloning original repository."
            FORK_USED=0
        fi
    fi
    
    # If fork succeeded, rename directory (if needed) and configure remotes
    if [[ "$FORK_USED" -eq 1 ]]; then
        # Determine default directory name created by gh (basename of repo URL)
        FORK_DIR_NAME=$(basename -s .git "$REPOSITORY")
        if [ -z "$FORK_DIR_NAME" ]; then
            FORK_DIR_NAME="$PROJECT_NAME"
        fi
        
        # If user provided a custom project name, rename directory accordingly
        if [ "$FORK_DIR_NAME" != "$PROJECT_NAME" ] && [ -d "$FORK_DIR_NAME" ] && [ ! -d "$PROJECT_NAME" ]; then
            mv "$FORK_DIR_NAME" "$PROJECT_NAME"
        fi
        
        # Configure remotes: origin -> fork, <repo-name> -> original source
        if [ -d "$PROJECT_NAME/.git" ]; then
            cd "$PROJECT_NAME"
            
            # Base remote name on original repo slug (e.g., some-project)
            ORIGINAL_REMOTE_NAME=$(basename -s .git "$REPOSITORY")
            if [[ "$OSTYPE" == "darwin"* ]]; then
                ORIGINAL_REMOTE_NAME=$(echo "$ORIGINAL_REMOTE_NAME" | LC_ALL=C tr '[:upper:]' '[:lower:]' | LC_ALL=C tr ' ' '-' | LC_ALL=C tr -cd 'a-z0-9-_.')
            else
                ORIGINAL_REMOTE_NAME=$(echo "$ORIGINAL_REMOTE_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-_.')
            fi
            if [ -z "$ORIGINAL_REMOTE_NAME" ]; then
                ORIGINAL_REMOTE_NAME="upstream"
            fi
            
            # gh repo fork typically sets 'upstream' to the original source
            if git remote get-url upstream >/dev/null 2>&1; then
                # Only rename if the target name does not already exist
                if ! git remote get-url "$ORIGINAL_REMOTE_NAME" >/dev/null 2>&1; then
                    git remote rename upstream "$ORIGINAL_REMOTE_NAME" >/dev/null 2>&1 || true
                fi
            fi
            
            cd "$PROJECTS_DIR_PATH"

            if [[ "$JSON_OUTPUT" != "1" ]]; then
                echo-yellow "Note: GitHub controls fork visibility; forks are typically public by default."
                echo-yellow "If you need this fork to be private, update its visibility in the GitHub repository settings."
            fi
        fi
    fi
fi

# Fallback: standard git clone when not forking or when fork fails
if [[ "$FORK_USED" -ne 1 ]]; then
    if [[ "$JSON_OUTPUT" == "1" ]]; then
        git clone "${GIT_CLONE_ARGS[@]}" "$REPOSITORY" "$PROJECT_NAME" > /dev/null 2>&1
    else
        git clone "${GIT_CLONE_ARGS[@]}" "$REPOSITORY" "$PROJECT_NAME"
    fi
fi

echo-return

cd ..

# Build setup options to pass along (positional arguments expected by setup_project.sh)
# Use an array to preserve spaces and avoid quoting issues.
SETUP_ARGS=()

# setup_project.sh expects:
#   $1 = project_name
#   $2 = database_engine
#   $3 = display_name
#   $4 = description (optional)
#   $5 = emoji (optional)
SETUP_ARGS+=("$PROJECT_NAME")
if [[ -n "$DATABASE_ENGINE" ]]; then
    SETUP_ARGS+=("$DATABASE_ENGINE")
else
    SETUP_ARGS+=("mysql")  # default
fi

if [[ -z "$DISPLAY_NAME" ]]; then
    DISPLAY_NAME="$PROJECT_NAME"
fi
SETUP_ARGS+=("$DISPLAY_NAME")

if [[ -n "$PROJECT_DESCRIPTION" ]]; then
    SETUP_ARGS+=("$PROJECT_DESCRIPTION")
fi
if [[ -n "$PROJECT_EMOJI" ]]; then
    SETUP_ARGS+=("$PROJECT_EMOJI")
fi

# Add flags
if [[ "$JSON_OUTPUT" == "1" ]]; then
    SETUP_ARGS+=("--json-output")
fi
if [[ "$NO_COLOR" == "1" ]]; then
    SETUP_ARGS+=("--no-colors")
fi
if [[ "$DEBUG" == "1" ]]; then
    SETUP_ARGS+=("--debug")
fi
if [[ "$OVERWRITE_DOCKER_COMPOSE" == "1" ]]; then
    SETUP_ARGS+=("--overwrite-docker-compose")
fi
if [[ "$NO_STORAGE_SYMLINK" == "1" ]]; then
    SETUP_ARGS+=("--no-storage-symlink")
fi
if [[ -n "$FORCED_FRAMEWORK" ]]; then
    SETUP_ARGS+=("--framework" "$FORCED_FRAMEWORK")
fi

# Setup project
if [[ "$JSON_OUTPUT" == "1" ]]; then
    SETUP_OUTPUT=$(source "$DEV_DIR/scripts/setup_project.sh" "${SETUP_ARGS[@]}" 2>&1)
    SETUP_EXIT_CODE=$?
    
    if [ $SETUP_EXIT_CODE -ne 0 ]; then
        # Setup failed - output the error and exit
        echo "$SETUP_OUTPUT"
        exit $SETUP_EXIT_CODE
    fi
else
    source "$DEV_DIR/scripts/setup_project.sh" "${SETUP_ARGS[@]}"
fi

# GitHub repository creation (interactive prompts if not specified).
# Skip this when we already created a fork via gh.
if [[ "$FORK_USED" -ne 1 ]]; then
    if [[ "$JSON_OUTPUT" != "1" ]] && [ -z "$CREATE_GITHUB" ]; then
        prompt_github_creation
    fi
    
    # Create GitHub repository if requested
    if [ "$CREATE_GITHUB" != "no" ] && [ -n "$CREATE_GITHUB" ]; then
        cd "$PROJECTS_DIR_PATH/$PROJECT_NAME"
        create_github_repo "$PROJECT_NAME" "$CREATE_GITHUB" "$ORGANIZATION" "$REPOSITORY"
    fi
fi

# Setup handles startup internally, so we just output the setup results
if [[ "$JSON_OUTPUT" == "1" ]]; then
    echo "{\"action\": \"clone_project\", \"project_name\": \"$PROJECT_NAME\", \"repository\": \"$REPOSITORY\", \"setup_result\": $SETUP_OUTPUT, \"status\": \"success\"}"
fi

cd "$ORIG_DIR"
