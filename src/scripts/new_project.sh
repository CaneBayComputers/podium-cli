#!/bin/bash

set -e


ORIG_DIR=$(pwd)

cd "$(dirname "$(realpath "$0")")"

cd ..

DEV_DIR=$(pwd)

source scripts/pre_check.sh

# Use projects directory from pre_check
PROJECTS_DIR="$PROJECTS_DIR_PATH"



# Function to get latest Laravel version from GitHub API
get_latest_laravel_version() {
    curl -s https://api.github.com/repos/laravel/laravel/tags | grep '"name"' | head -1 | sed 's/.*"v\([^"]*\)".*/\1/'
}

# Function to validate Laravel version exists
validate_laravel_version() {
    local version="$1"
    if [ "$version" = "latest" ]; then
        return 0
    fi
    
    # Handle version with or without 'v' prefix
    local version_with_v="$version"
    if [[ ! "$version" =~ ^v ]]; then
        version_with_v="v${version}"
    fi
    
    # Check if the version exists by querying the GitHub API with larger page size
    local tag_exists=$(curl -s "https://api.github.com/repos/laravel/laravel/tags?per_page=100" | grep -c "\"name\": \"${version_with_v}\"")
    [ "$tag_exists" -gt 0 ]
}

# Function to validate WordPress version exists
validate_wordpress_version() {
    local version="$1"
    if [ "$version" = "latest" ]; then
        return 0
    fi
    # Check if the WordPress version exists
    local status_code=$(curl -s -o /dev/null -w "%{http_code}" "https://wordpress.org/wordpress-${version}.tar.gz")
    [ "$status_code" = "200" ]
}

# Function to display usage
usage() {
    echo-white "Usage: $0 <project_name> [organization] [version] [options]"
    echo-white "Creates a new Laravel or WordPress project"
    echo-white ""
    echo-white "Arguments:"
    echo-white "  project_name    Name of the project to create"
    echo-white "  organization    GitHub organization (optional)"
    echo-white "  version         Framework version (optional)"
    echo-white ""
    echo-white "Options:"
    echo-white "  --framework TYPE        Framework type: laravel, wordpress, php (required with --json-output)"
    echo-white "  --display-name NAME     Display name for project (required with --json-output)"
    echo-white "  --version VERSION       Framework/PHP version (laravel/wordpress: latest, php: 8 or 7)"
    echo-white "  --database TYPE         Database type: mysql, postgres, mongo (default: mysql)"
    echo-white "  --description TEXT      Project description (optional)"
    echo-white "  --emoji EMOJI           Project emoji (will prompt if not provided)"
    echo-white "  --github                Create GitHub repository in user account"
    echo-white "  --github-org ORG        Create GitHub repository in organization"
    echo-white "  --json-output           Output JSON responses (for programmatic use)"
    echo-white "  --no-colors             Disable colored output"
    echo-white "  --debug                 Enable debug logging to /tmp/podium-cli-debug.log"
    echo-white ""
    echo-white "Examples:"
    echo-white "  $0 my-app --framework laravel --display-name \"My App\" --database postgres --github"
    echo-white "  $0 my-blog --framework wordpress --display-name \"My Blog\" --github-org myorg"
    error "usage" 1
}

# Initialize variables
PROJECT_NAME=""
DISPLAY_NAME=""
PROJECT_DESCRIPTION=""
PROJECT_EMOJI=""
ORGANIZATION=""
VERSION="latest"
FRAMEWORK=""
DATABASE=""
CREATE_GITHUB=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --framework)
            FRAMEWORK="$2"
            shift 2
            ;;
        --version)
            VERSION="$2"
            shift 2
            ;;
        --database)
            DATABASE="$2"
            shift 2
            ;;
        --display-name)
            DISPLAY_NAME="$2"
            shift 2
            ;;
        --description)
            PROJECT_DESCRIPTION="$2"
            shift 2
            ;;
        --emoji)
            PROJECT_EMOJI="$2"
            shift 2
            ;;
        --github)
            CREATE_GITHUB="yes"
            shift
            ;;
        --github-org)
            CREATE_GITHUB="org"
            ORGANIZATION="$2"
            shift 2
            ;;
        --json-output)
            JSON_OUTPUT=1
            shift
            ;;
        --no-colors)
            NO_COLOR=1
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
            echo-red "Unknown option: $1"
            usage
            ;;
        *)
            if [ -z "$PROJECT_NAME" ]; then
                PROJECT_NAME="$1"
            elif [ -z "$ORGANIZATION" ]; then
                ORGANIZATION="$1"
            elif [ -z "$VERSION" ]; then
                VERSION="$1"
            else
                echo-red "Too many arguments"
                usage
            fi
            shift
            ;;
    esac
done

# Initialize debug logging
debug "Script started: new_project.sh with args: $*"

# Validation for JSON output mode
debug "Starting validation phase"
if [[ "$JSON_OUTPUT" == "1" ]]; then
    debug "JSON output mode enabled"
    # Required options validation
    if [ -z "$PROJECT_NAME" ]; then
        json_error "project name is required when using --json-output"
    fi
    
    # Set defaults for JSON mode
    if [ -z "$FRAMEWORK" ]; then
        FRAMEWORK="laravel"
    fi
    
    if [ -z "$DISPLAY_NAME" ]; then
        DISPLAY_NAME="$PROJECT_NAME"
    fi
    
    # Set version defaults based on framework
    if [ -z "$VERSION" ] || [ "$VERSION" = "latest" ]; then
        case "$FRAMEWORK" in
            "laravel"|"wordpress")
                VERSION="latest"
                ;;
            "php")
                VERSION="8"
                ;;
            *)
                VERSION="latest"
                ;;
        esac
    fi
    
    # Set default database
    if [ -z "$DATABASE" ]; then
        DATABASE="mysql"
    fi
    
    # Framework validation
    case "$FRAMEWORK" in
        "laravel"|"wordpress"|"php")
            # Valid frameworks
            ;;
        *)
            json_error "invalid framework: $FRAMEWORK (must be laravel, wordpress, or php)"
            ;;
    esac

    # Database validation
    case "$DATABASE" in
        "mysql"|"postgres"|"mongo")
            # Valid databases
            ;;
        *)
            json_error "invalid database: $DATABASE (must be mysql, postgres, or mongo)"
            ;;
    esac
    
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

# Interactive mode if no project name provided
if [ -z "$PROJECT_NAME" ]; then
    echo-return
    echo-cyan "🚀 Create a New Podium Project"
    echo-return
    echo-white -n "Enter project name: "
    read PROJECT_NAME
    
    if [ -z "$PROJECT_NAME" ]; then
        error "Project name cannot be empty!"
    fi
    
    echo-white -n "Enter organization name (optional): "
    read ORGANIZATION
fi


# Convert to lowercase, replace spaces with dashes, and remove non-alphanumeric characters (macOS-compatible)
if [[ "$OSTYPE" == "darwin"* ]]; then
    PROJECT_NAME=$(echo "$PROJECT_NAME" | LC_ALL=C tr '[:upper:]' '[:lower:]' | LC_ALL=C tr ' ' '-' | LC_ALL=C tr -cd 'a-z0-9-_')
else
    PROJECT_NAME=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-_')
fi

# Check for duplicate project names
while [ -d "$PROJECTS_DIR/$PROJECT_NAME" ]; do
    if [[ "$JSON_OUTPUT" == "1" ]]; then
        json_error "project name '$PROJECT_NAME' already exists"
    else
        echo-red "Error: Project name '$PROJECT_NAME' already exists!"
        echo-yellow -n "Enter a different project name: "
        read NEW_PROJECT_NAME
        if [ -z "$NEW_PROJECT_NAME" ]; then
            error "Project name cannot be empty!"
        fi
        # Cleanse the new name (macOS-compatible)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            PROJECT_NAME=$(echo "$NEW_PROJECT_NAME" | LC_ALL=C tr '[:upper:]' '[:lower:]' | LC_ALL=C tr ' ' '-' | LC_ALL=C tr -cd 'a-z0-9-_')
        else
            PROJECT_NAME=$(echo "$NEW_PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-_')
        fi
    fi
done


# Project type selection
# Framework selection
if [ -z "$FRAMEWORK" ]; then
    echo-return; echo-cyan "What type of project would you like to create?"
    echo-white "1) Laravel (PHP Framework)"
    echo-white "2) WordPress (CMS)"
    echo-white "3) PHP (Plain PHP project)"
    echo-return; echo-yellow -n "Enter your choice (1-3): "
    read FRAMEWORK_CHOICE
    
    case $FRAMEWORK_CHOICE in
        1)
            FRAMEWORK="laravel"
            ;;
        2)
            FRAMEWORK="wordpress"
            ;;
        3)
            FRAMEWORK="php"
            ;;
        *)
            error "Invalid choice. Exiting..."
            ;;
    esac
fi

case $FRAMEWORK in
    laravel)
        echo-return; echo-cyan "Laravel project selected!"
        
        # Laravel version selection
        if [[ "$JSON_OUTPUT" == "1" ]]; then
            # In JSON mode, validate the provided version
            if ! validate_laravel_version "$VERSION"; then
                json_error "invalid Laravel version: $VERSION"
            fi
            
            # Set the version for download in JSON mode
            if [ "$VERSION" = "latest" ]; then
                LATEST_VERSION=$(get_latest_laravel_version)
                CUR_LARAVEL_BRANCH="v${LATEST_VERSION}"
            else
                # Ensure version has 'v' prefix for download URL
                if [[ ! "$VERSION" =~ ^v ]]; then
                    CUR_LARAVEL_BRANCH="v${VERSION}"
                else
                    CUR_LARAVEL_BRANCH="$VERSION"
                fi
            fi
        else
            # In interactive mode, ask for version first, then validate
            echo-yellow -n "Enter Laravel version [latest]: "
            read USER_VERSION
            if [ -z "$USER_VERSION" ]; then
                VERSION="latest"
            else
                VERSION="$USER_VERSION"
            fi
            
            # Validate and loop if invalid
            while ! validate_laravel_version "$VERSION"; do
                echo-red "Invalid Laravel version: $VERSION"
                echo-yellow -n "Enter Laravel version [latest]: "
                read USER_VERSION
                if [ -z "$USER_VERSION" ]; then
                    VERSION="latest"
                else
                    VERSION="$USER_VERSION"
                fi
            done
        fi
        
        # Set the version for download
        if [ "$VERSION" = "latest" ]; then
            LATEST_VERSION=$(get_latest_laravel_version)
            CUR_LARAVEL_BRANCH="v${LATEST_VERSION}"
            echo-green "Using latest Laravel version: $LATEST_VERSION"
        else
            # Ensure version has 'v' prefix for download URL
            if [[ ! "$VERSION" =~ ^v ]]; then
                CUR_LARAVEL_BRANCH="v${VERSION}"
            else
                CUR_LARAVEL_BRANCH="$VERSION"
            fi
            echo-green "Laravel $VERSION selected!"
        fi
        ;;
    wordpress)
        echo-return; echo-cyan "WordPress project selected!"
        
        # WordPress version selection
        if [[ "$JSON_OUTPUT" == "1" ]]; then
            # In JSON mode, validate the provided version
            if ! validate_wordpress_version "$VERSION"; then
                json_error "invalid WordPress version: $VERSION"
            fi
        else
            # In interactive mode, ask for version first, then validate
            echo-yellow -n "Enter WordPress version [latest]: "
            read USER_VERSION
            if [ -z "$USER_VERSION" ]; then
                VERSION="latest"
            else
                VERSION="$USER_VERSION"
            fi
            
            # Validate and loop if invalid
            while ! validate_wordpress_version "$VERSION"; do
                echo-red "Invalid WordPress version: $VERSION"
                echo-yellow -n "Enter WordPress version [latest]: "
                read USER_VERSION
                if [ -z "$USER_VERSION" ]; then
                    VERSION="latest"
                else
                    VERSION="$USER_VERSION"
                fi
            done
        fi
        
        WP_VERSION="$VERSION"
        if [ "$VERSION" = "latest" ]; then
            echo-green "Using latest WordPress version"
        else
            echo-green "WordPress $VERSION selected!"
        fi
        
        # WordPress only supports MySQL
        if [ "$DATABASE" != "mysql" ] && [ "$DATABASE" != "mariadb" ] && [ -n "$DATABASE" ]; then
            if [[ "$JSON_OUTPUT" == "1" ]]; then
                json_error "WordPress only supports MySQL/MariaDB database"
            else
                echo-yellow "Warning: WordPress only supports MySQL/MariaDB. Switching to MySQL."
                DATABASE="mysql"
            fi
        fi
        ;;
    php)
        echo-return; echo-cyan "PHP project selected!"
        
        # PHP projects don't need version validation
        echo-green "PHP project will be created with basic structure"
        ;;
    *)
        error "Unknown framework '$FRAMEWORK'. Exiting..."
        ;;
esac

# Database selection
if [ -z "$DATABASE" ]; then
    echo-return; echo-cyan "Which database would you like to use?"
    echo-white "1) MySQL/MariaDB (Default)"
    echo-white "2) PostgreSQL"
    echo-white "3) MongoDB"
    echo-return; echo-yellow -n "Enter your choice (1-3): "
    read DB_CHOICE
    
    case $DB_CHOICE in
        1)
            DATABASE_TYPE="mysql"
            echo-green "MySQL/MariaDB selected!"
            ;;
        2)
            DATABASE_TYPE="postgres"
            echo-green "PostgreSQL selected!"
            ;;
        3)
            DATABASE_TYPE="mongo"
            echo-green "MongoDB selected!"
            ;;
        *)
            echo-yellow "Invalid choice. Defaulting to MySQL/MariaDB"
            DATABASE_TYPE="mysql"
            ;;
    esac
else
    case "$DATABASE" in
        mysql|mariadb)
            DATABASE_TYPE="mysql"
            echo-return; echo-cyan "MySQL/MariaDB selected!"
            ;;
        postgres|postgresql|postgressql)
            DATABASE_TYPE="postgres"
            echo-return; echo-cyan "PostgreSQL selected!"
            ;;
        mongo|mongodb)
            DATABASE_TYPE="mongo"
            echo-return; echo-cyan "MongoDB selected!"
            ;;
        *)
            echo-yellow "Unknown database '$DATABASE'. Defaulting to MySQL/MariaDB"
            DATABASE_TYPE="mysql"
            ;;
    esac
fi

echo-return; echo-return

# GitHub organization prompt for interactive mode
if [[ "$JSON_OUTPUT" != "1" ]] && [ "$CREATE_GITHUB" = "yes" ] && [ -z "$ORGANIZATION" ]; then
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
fi

# Set project name
cd "$PROJECTS_DIR"

if [ -d "$PROJECT_NAME" ]; then

	    error "Error: Project name already exists"

fi

mkdir "$PROJECT_NAME"

cd "$PROJECT_NAME"

if [ "$FRAMEWORK" = "laravel" ]; then
    debug "Starting Laravel download for version: $CUR_LARAVEL_BRANCH"
    echo-return; echo-cyan "Downloading Laravel project..."
    
    # Download Laravel from GitHub releases
    if [[ "$JSON_OUTPUT" == "1" ]]; then
        debug "Downloading Laravel in JSON mode"
        if ! curl -sL "https://github.com/laravel/laravel/archive/refs/tags/${CUR_LARAVEL_BRANCH}.tar.gz" | tar -xz --strip-components=1 > /dev/null 2>&1; then
            debug "Laravel download failed"
            echo "{\"action\": \"new_project\", \"project_name\": \"$PROJECT_NAME\", \"framework\": \"$FRAMEWORK\", \"status\": \"error\", \"error\": \"download_failed\", \"details\": \"Failed to download Laravel ${CUR_LARAVEL_BRANCH}\"}"
            exit 1
        fi
        debug "Laravel download completed successfully"
    else
        debug "Downloading Laravel in interactive mode"
        curl -L "https://github.com/laravel/laravel/archive/refs/tags/${CUR_LARAVEL_BRANCH}.tar.gz" | tar -xz --strip-components=1
        debug "Laravel download completed"
    fi
    
    # Gitignore setup will be handled by setup_project.sh
    
    echo-green "Laravel project structure created!"

elif [ "$FRAMEWORK" = "wordpress" ]; then
    echo-return; echo-cyan "Downloading WordPress..."
    
    if [ "$WP_VERSION" = "latest" ]; then
        if [[ "$JSON_OUTPUT" == "1" ]]; then
            curl -O https://wordpress.org/latest.tar.gz > /dev/null 2>&1
            tar -xzf latest.tar.gz --strip-components=1 > /dev/null 2>&1
            rm latest.tar.gz > /dev/null 2>&1
        else
            curl -O https://wordpress.org/latest.tar.gz
            tar -xzf latest.tar.gz --strip-components=1
            rm latest.tar.gz
        fi
    else
        if [[ "$JSON_OUTPUT" == "1" ]]; then
            curl -O https://wordpress.org/wordpress-${WP_VERSION}.tar.gz > /dev/null 2>&1
            tar -xzf wordpress-${WP_VERSION}.tar.gz --strip-components=1 > /dev/null 2>&1
            rm wordpress-${WP_VERSION}.tar.gz > /dev/null 2>&1
        else
            curl -O https://wordpress.org/wordpress-${WP_VERSION}.tar.gz
            tar -xzf wordpress-${WP_VERSION}.tar.gz --strip-components=1
            rm wordpress-${WP_VERSION}.tar.gz
        fi
    fi
    
    # Initialize git for WordPress
    if [[ "$JSON_OUTPUT" == "1" ]]; then
        git init > /dev/null 2>&1
        git add . > /dev/null 2>&1
        git commit -m "Initial WordPress setup" > /dev/null 2>&1
    else
        git init
        git add .
        git commit -m "Initial WordPress setup"
    fi
    
    # Gitignore setup will be handled by setup_project.sh
    
    echo-green "WordPress downloaded and initialized!"

elif [ "$FRAMEWORK" = "php" ]; then
    echo-return; echo-cyan "Creating PHP project structure..."
    
    # Create basic PHP project structure
    mkdir -p public src
    
    # Create index.php
    cat > public/index.php << 'EOF'
<?php
echo "Hello, World! This is your PHP project.";
?>
EOF
    
    # Initialize git
    if [[ "$JSON_OUTPUT" == "1" ]]; then
        git init > /dev/null 2>&1
        git add . > /dev/null 2>&1
        git commit -m "Initial PHP project setup" > /dev/null 2>&1
    else
        git init
        git add .
        git commit -m "Initial PHP project setup"
    fi
    
    # Gitignore setup will be handled by setup_project.sh
    
    echo-green "PHP project structure created!"
fi


# GitHub repository creation
# GitHub repository creation (interactive prompts if not specified)
if [ -z "$CREATE_GITHUB" ]; then
    prompt_github_creation
fi

# Create GitHub repository if requested
if [ "$CREATE_GITHUB" != "no" ] && [ -n "$CREATE_GITHUB" ]; then
    create_github_repo "$PROJECT_NAME" "$CREATE_GITHUB" "$ORGANIZATION"
fi

cd ../..


# Setup project
# Build setup options
SETUP_OPTIONS=""
if [[ "$JSON_OUTPUT" == "1" ]]; then
    SETUP_OPTIONS="$SETUP_OPTIONS --json-output"
fi
if [[ "$NO_COLOR" == "1" ]]; then
    SETUP_OPTIONS="$SETUP_OPTIONS --no-colors"
fi
if [[ "$DEBUG" == "1" ]]; then
    SETUP_OPTIONS="$SETUP_OPTIONS --debug"
fi
if [[ "$FRAMEWORK" == "php" && "$VERSION" != "8" && "$VERSION" != "latest" ]]; then
    SETUP_OPTIONS="$SETUP_OPTIONS --php-version $VERSION"
fi

if [[ "$JSON_OUTPUT" == "1" ]]; then
    # In JSON mode, capture setup output and combine with new_project info
    SETUP_OUTPUT=$(source "$DEV_DIR/scripts/setup_project.sh" "$PROJECT_NAME" "$DATABASE" "$DISPLAY_NAME" "$PROJECT_DESCRIPTION" "$PROJECT_EMOJI" $SETUP_OPTIONS 2>&1)
    SETUP_EXIT_CODE=$?
    
    if [ $SETUP_EXIT_CODE -ne 0 ]; then
        # Setup failed - output error and exit
        echo "{\"action\": \"new_project\", \"project_name\": \"$PROJECT_NAME\", \"framework\": \"$FRAMEWORK\", \"database\": \"$DATABASE\", \"status\": \"error\", \"error\": \"setup_failed\", \"details\": \"$SETUP_OUTPUT\"}"
        exit $SETUP_EXIT_CODE
    fi
    
    # Setup handles startup internally, so we just output the setup results
    echo "{\"action\": \"new_project\", \"project_name\": \"$PROJECT_NAME\", \"framework\": \"$FRAMEWORK\", \"database\": \"$DATABASE\", \"setup_result\": $SETUP_OUTPUT, \"status\": \"success\"}"
else
    # In normal mode, run setup with full output (setup handles startup internally)
    source "$DEV_DIR/scripts/setup_project.sh" "$PROJECT_NAME" "$DATABASE" "$DISPLAY_NAME" "$PROJECT_DESCRIPTION" "$PROJECT_EMOJI" $SETUP_OPTIONS
fi

cd "$ORIG_DIR"