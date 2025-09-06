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
PHP_VERSION=""
DATABASE_ENGINE=""
DISPLAY_NAME=""
PROJECT_DESCRIPTION=""
PROJECT_EMOJI=""

# Function to display usage
usage() {
    echo-white "Usage: $0 [OPTIONS] <repository> [project_name]"
    echo-white "Clone a Git repository and set up as Podium project"
    echo-white ""
    echo-white "Arguments:"
    echo-white "  repository        Git repository URL to clone"
    echo-white "  project_name      Optional: Local project name (defaults to repo name)"
    echo-white ""
    echo-white "Options:"
    echo-white "  --json-output                Output results in JSON format"
    echo-white "  --no-colors                  Disable colored output"
    echo-white "  --overwrite-docker-compose   Overwrite existing docker-compose.yaml without prompting"
    echo-white "  --php-version VERSION        Force specific PHP version (7 or 8)"
    echo-white "  --database ENGINE            Database type: mysql, postgres, mongo (default: mysql)"
    echo-white "  --display-name NAME          Display name for project (optional)"
    echo-white "  --description TEXT           Project description (optional)"
    echo-white "  --emoji EMOJI                Project emoji (default: 🚀)"
    echo-white "  --help                       Show this help message"
    
    error "usage" 1
}

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
        --php-version)
            if [ -n "$2" ] && [[ ! "$2" =~ ^-- ]]; then
                PHP_VERSION="$2"
                shift 2
            else
                error "Error: --php-version requires a version number"
            fi
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

# Check if repository argument is provided
if [ -z "$REPOSITORY" ]; then
    error "Error: Repository is required."
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

# Check repository for existing docker-compose.yaml before cloning (unless overwrite is already set)
if [[ "$OVERWRITE_DOCKER_COMPOSE" != "1" ]]; then
    echo-white "Checking repository for existing Docker configuration..."

    # Create a temporary directory to check the repo
    TEMP_CHECK_DIR=$(mktemp -d)
    cd "$TEMP_CHECK_DIR"

    # Clone just the top level to check for docker-compose.yaml (shallow clone)
    if git clone --depth 1 "$REPOSITORY" temp_check > /dev/null 2>&1; then
        cd temp_check
        
        # Use the new reusable function to handle docker-compose conflicts
        if ! handle_docker_compose_conflict "docker-compose.yaml" "clone"; then
            cd "$PROJECTS_DIR"
            rm -rf "$TEMP_CHECK_DIR"
            error "Clone cancelled due to Docker configuration conflict."
        fi
    else
        echo-yellow "⚠️  Could not check repository contents (private repo or network issue)"
        echo-white "Proceeding with clone - will handle conflicts during setup if needed"
    fi

    # Clean up temp directory
    cd "$PROJECTS_DIR"
    rm -rf "$TEMP_CHECK_DIR"
else
    echo-white "✅ Overwrite flag set - skipping Docker configuration check"
fi

echo-return

# Clone repository
if [[ "$JSON_OUTPUT" == "1" ]]; then
    git clone "$REPOSITORY" "$PROJECT_NAME" > /dev/null 2>&1
else
    git clone "$REPOSITORY" "$PROJECT_NAME"
fi

echo-return

cd ..

# Build setup options to pass along
SETUP_OPTIONS="$PROJECT_NAME"
if [[ -n "$DATABASE_ENGINE" ]]; then
    SETUP_OPTIONS="$SETUP_OPTIONS $DATABASE_ENGINE"
else
    SETUP_OPTIONS="$SETUP_OPTIONS mysql"  # default
fi
if [[ -n "$DISPLAY_NAME" ]]; then
    SETUP_OPTIONS="$SETUP_OPTIONS \"$DISPLAY_NAME\""
fi
if [[ -n "$PROJECT_DESCRIPTION" ]]; then
    SETUP_OPTIONS="$SETUP_OPTIONS \"$PROJECT_DESCRIPTION\""
fi
if [[ -n "$PROJECT_EMOJI" ]]; then
    SETUP_OPTIONS="$SETUP_OPTIONS \"$PROJECT_EMOJI\""
fi
# Add flags
if [[ "$JSON_OUTPUT" == "1" ]]; then
    SETUP_OPTIONS="$SETUP_OPTIONS --json-output"
fi
if [[ "$NO_COLOR" == "1" ]]; then
    SETUP_OPTIONS="$SETUP_OPTIONS --no-colors"
fi
if [[ "$OVERWRITE_DOCKER_COMPOSE" == "1" ]]; then
    SETUP_OPTIONS="$SETUP_OPTIONS --overwrite-docker-compose"
fi
if [[ -n "$PHP_VERSION" ]]; then
    SETUP_OPTIONS="$SETUP_OPTIONS --php-version $PHP_VERSION"
fi

# Setup project
if [[ "$JSON_OUTPUT" == "1" ]]; then
    SETUP_OUTPUT=$(source "$DEV_DIR/scripts/setup_project.sh" $SETUP_OPTIONS 2>&1)
    SETUP_EXIT_CODE=$?
    
    if [ $SETUP_EXIT_CODE -ne 0 ]; then
        # Setup failed - output the error and exit
        echo "$SETUP_OUTPUT"
        exit $SETUP_EXIT_CODE
    fi
else
    source "$DEV_DIR/scripts/setup_project.sh" $SETUP_OPTIONS
fi

# Setup handles startup internally, so we just output the setup results
if [[ "$JSON_OUTPUT" == "1" ]]; then
    echo "{\"action\": \"clone_project\", \"project_name\": \"$PROJECT_NAME\", \"repository\": \"$REPOSITORY\", \"setup_result\": $SETUP_OUTPUT, \"status\": \"success\"}"
fi

cd "$ORIG_DIR"