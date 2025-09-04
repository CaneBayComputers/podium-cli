#!/bin/bash

set -e


ORIG_DIR=$(pwd)

cd "$(dirname "$(realpath "$0")")"

cd ..

DEV_DIR=$(pwd)

source scripts/functions.sh

# Initialize variables
JSON_OUTPUT="${JSON_OUTPUT:-}"
NO_COLOR="${NO_COLOR:-}"
REPOSITORY=""
PROJECT_NAME=""
OVERWRITE_DOCKER_COMPOSE=""
PHP_VERSION=""

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

# Navigate to the configured projects directory
PROJECTS_DIR=$(get_projects_dir)
cd "$PROJECTS_DIR"

if [ -d "$PROJECT_NAME" ]; then
    error "Error: Project name already exists."
fi

echo-return

# Clone repository
if [[ "$JSON_OUTPUT" == "1" ]]; then
    git clone "$REPOSITORY" "$PROJECT_NAME" > /dev/null 2>&1
else
    git clone "$REPOSITORY" "$PROJECT_NAME"
fi

echo-return

# Check if cloned project has existing docker-compose.yaml with Podium metadata
# If so, replace hardcoded ipv4_address with IPV4_ADDRESS placeholder
if [ -f "$PROJECTS_DIR/$PROJECT_NAME/docker-compose.yaml" ]; then
    cd "$PROJECTS_DIR/$PROJECT_NAME"
    
    # Check if this is a Podium project by looking for x-metadata
    if grep -q "type: \"podium-project\"" docker-compose.yaml 2>/dev/null; then
        echo-white "Detected existing Podium project, updating IP address configuration..."
        
        # Replace any hardcoded ipv4_address with IPV4_ADDRESS placeholder
        # This allows setup_project.sh to assign a new IP that works with current installation
        podium-sed 's/ipv4_address: [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+/ipv4_address: IPV4_ADDRESS/g' docker-compose.yaml
        
        echo-white "IP address configuration updated for current environment"
    fi
    
    cd ..
fi

cd ..

# Build setup options to pass along
SETUP_OPTIONS=""
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
    SETUP_OUTPUT=$(source "$DEV_DIR/scripts/setup_project.sh" $PROJECT_NAME $SETUP_OPTIONS 2>&1)
    SETUP_EXIT_CODE=$?
    
    if [ $SETUP_EXIT_CODE -eq 0 ]; then
        # Parse setup JSON and combine with clone info
        if echo "$SETUP_OUTPUT" | grep -q '"status": "success"'; then
            echo "{\"action\": \"clone_project\", \"project_name\": \"$PROJECT_NAME\", \"repository\": \"$REPOSITORY\", \"setup\": $SETUP_OUTPUT, \"status\": \"success\"}"
        else
            echo "$SETUP_OUTPUT"
        fi
    else
        # Setup failed
        if echo "$SETUP_OUTPUT" | grep -q '"status": "error"'; then
            echo "$SETUP_OUTPUT"
        else
            echo "{\"action\": \"clone_project\", \"project_name\": \"$PROJECT_NAME\", \"repository\": \"$REPOSITORY\", \"status\": \"error\", \"error\": \"setup_failed\"}"
        fi
    fi
else
    source "$DEV_DIR/scripts/setup_project.sh" $PROJECT_NAME $SETUP_OPTIONS
fi

cd "$ORIG_DIR"