#!/bin/bash

set -e


ORIG_DIR=$(pwd)

cd "$(dirname "$(realpath "$0")")"

cd ..

DEV_DIR=$(pwd)

source scripts/functions.sh

# Get projects directory
PROJECTS_DIR="$(get_projects_dir)"

# Main
source "$DEV_DIR/scripts/pre_check.sh"



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
    # Check if the version exists by trying to access the GitHub release
    local status_code=$(curl -s -o /dev/null -w "%{http_code}" "https://github.com/laravel/laravel/archive/refs/tags/v${version}.tar.gz")
    [ "$status_code" = "200" ]
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
    echo "Usage: $0 <project_name> [organization] [version] [options]"
    echo "Creates a new Laravel or WordPress project"
    echo ""
    echo "Arguments:"
    echo "  project_name    Name of the project to create"
    echo "  organization    GitHub organization (optional)"
    echo "  version         Framework version (optional)"
    echo ""
    echo "Options:"
    echo "  --framework TYPE        Framework type: laravel, wordpress, php (required with --json-output)"
    echo "  --display-name NAME     Display name for project (required with --json-output)"
    echo "  --version VERSION       Framework/PHP version (laravel/wordpress: latest, php: 8 or 7)"
    echo "  --database TYPE         Database type: mysql, postgres, mongo (default: mysql)"
    echo "  --description TEXT      Project description (optional)"
    echo "  --emoji EMOJI           Project emoji (default: 🚀)"
    echo "  --github                Create GitHub repository in user account"
    echo "  --github-org ORG        Create GitHub repository in organization"
    echo "  --json-output           Output JSON responses (for programmatic use)"
    echo "  --no-colors             Disable colored output"
    echo ""
    echo "Examples:"
    echo "  $0 my-app --framework laravel --display-name \"My App\" --database postgres --github"
    echo "  $0 my-blog --framework wordpress --display-name \"My Blog\" --github-org myorg"
    error "usage" 1
}

# Initialize variables
PROJECT_NAME=""
DISPLAY_NAME=""
PROJECT_DESCRIPTION=""
PROJECT_EMOJI="🚀"
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

# Validation for JSON output mode
if [[ "$JSON_OUTPUT" == "1" ]]; then
    # Required options validation
    if [ -z "$PROJECT_NAME" ]; then
        json_error "project name is required when using --json-output"
    fi
    
    if [ -z "$FRAMEWORK" ]; then
        json_error "framework is required when using --json-output"
    fi
    
    if [ -z "$DISPLAY_NAME" ]; then
        json_error "display-name is required when using --json-output"
    fi
    
    # GitHub organization validation
    if [ -z "$CREATE_GITHUB" ]; then
        CREATE_GITHUB="no"
    elif [ "$CREATE_GITHUB" = "org" ] && [ -z "$ORGANIZATION" ]; then
        json_error "organization is required when using --github-org"
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

    # Set default database
    if [ -z "$DATABASE" ]; then
        DATABASE="mysql"
    fi

    # Database validation
    case "$DATABASE" in
        "mysql"|"postgres"|"mongo")
            # Valid databases
            ;;
        *)
            json_error "invalid database: $DATABASE (must be mysql, postgres or mongo)"
            ;;
    esac
fi

# Interactive mode if no project name provided
if [ -z "$PROJECT_NAME" ]; then
    echo-return; echo-cyan "🚀 Create a New Podium Project"
    echo
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
            CUR_LARAVEL_BRANCH=$(get_latest_laravel_version)
            echo-green "Using latest Laravel version: $CUR_LARAVEL_BRANCH"
        else
            CUR_LARAVEL_BRANCH="$VERSION"
            echo-green "Laravel $CUR_LARAVEL_BRANCH selected!"
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
    echo-return; echo-cyan "Downloading Laravel project..."
    
    # Download Laravel from GitHub releases
    if [[ "$JSON_OUTPUT" == "1" ]]; then
        curl -sL "https://github.com/laravel/laravel/archive/refs/tags/v${CUR_LARAVEL_BRANCH}.tar.gz" | tar -xz --strip-components=1 > /dev/null 2>&1
    else
        curl -L "https://github.com/laravel/laravel/archive/refs/tags/v${CUR_LARAVEL_BRANCH}.tar.gz" | tar -xz --strip-components=1
    fi
    
    # Gitignore setup will be handled by setup_project.sh
    
    echo-green "Laravel project structure created!"

elif [ "$FRAMEWORK" = "wordpress" ]; then
    echo-return; echo-cyan "Downloading WordPress..."
    
    if [ "$WP_VERSION" = "latest" ]; then
        curl -O https://wordpress.org/latest.tar.gz
        tar -xzf latest.tar.gz --strip-components=1
        rm latest.tar.gz
    else
        curl -O https://wordpress.org/wordpress-${WP_VERSION}.tar.gz
        tar -xzf wordpress-${WP_VERSION}.tar.gz --strip-components=1
        rm wordpress-${WP_VERSION}.tar.gz
    fi
    
    # Initialize git for WordPress
    git init
    git add .
    git commit -m "Initial WordPress setup"
    
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
    git init
    git add .
    git commit -m "Initial PHP project setup"
    
    # Gitignore setup will be handled by setup_project.sh
    
    echo-green "PHP project structure created!"
fi


# GitHub repository creation
if [ -z "$CREATE_GITHUB" ]; then
    echo-return; echo-cyan "Would you like to create a GitHub repository?"
    echo-white "1) Yes, create GitHub repository"
    echo-white "2) No, skip GitHub repository"
    echo-return; echo-yellow -n "Enter your choice (1-2): "
    read GITHUB_CHOICE
    
    case $GITHUB_CHOICE in
        1)
            CREATE_GITHUB="yes"
            ;;
        2)
            CREATE_GITHUB="no"
            ;;
        *)
            echo-yellow "Invalid choice. Skipping GitHub repository creation"
            CREATE_GITHUB="no"
            ;;
    esac
fi

if [ "$CREATE_GITHUB" = "yes" ]; then
    REPO_NAME=$PROJECT_NAME
    if ! [ -z "$ORGANIZATION" ]; then 
        REPO_NAME="$ORGANIZATION/$PROJECT_NAME"
    fi

    echo-return; echo-cyan "Creating GitHub repository..."
    if gh repo create $REPO_NAME --private --source=. --push; then
        echo-green "GitHub repository created successfully!"
    else
        echo-yellow "GitHub repository creation failed, but project setup will continue."
    fi
else
    echo-return; echo-yellow "Skipping GitHub repository creation."
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
if [[ "$FRAMEWORK" == "php" && "$VERSION" != "8" && "$VERSION" != "latest" ]]; then
    SETUP_OPTIONS="$SETUP_OPTIONS --php-version $VERSION"
fi

if [[ "$JSON_OUTPUT" == "1" ]]; then
    # In JSON mode, capture setup output and combine with new_project info
    SETUP_OUTPUT=$(timeout 1800 bash -c "source '$DEV_DIR/scripts/setup_project.sh' $PROJECT_NAME $DATABASE_TYPE '$DISPLAY_NAME' '$PROJECT_DESCRIPTION' '$PROJECT_EMOJI' $SETUP_OPTIONS" 2>&1)
    SETUP_EXIT_CODE=$?
    
    if [ $SETUP_EXIT_CODE -eq 0 ]; then
        # Parse the setup JSON output and enhance it with new_project information
        if echo "$SETUP_OUTPUT" | grep -q '"status": "success"'; then
            # Extract setup info and combine with new_project info
            echo "{\"action\": \"new_project\", \"project_name\": \"$PROJECT_NAME\", \"framework\": \"$FRAMEWORK\", \"database\": \"$DATABASE_TYPE\", \"setup\": $SETUP_OUTPUT, \"status\": \"success\"}"
        else
            # Setup returned JSON error
            echo "$SETUP_OUTPUT"
        fi
    elif [ $SETUP_EXIT_CODE -eq 124 ]; then
        echo "{\"action\": \"new_project\", \"project_name\": \"$PROJECT_NAME\", \"framework\": \"$FRAMEWORK\", \"database\": \"$DATABASE_TYPE\", \"status\": \"error\", \"error\": \"timeout\"}"
    else
        # If setup failed but didn't return JSON, provide our own error
        if echo "$SETUP_OUTPUT" | grep -q '"status": "error"'; then
            echo "$SETUP_OUTPUT"
        else
            echo "{\"action\": \"new_project\", \"project_name\": \"$PROJECT_NAME\", \"framework\": \"$FRAMEWORK\", \"database\": \"$DATABASE_TYPE\", \"status\": \"error\", \"error\": \"setup_failed\"}"
        fi
    fi
else
    # In normal mode, run setup with full output
    source "$DEV_DIR/scripts/setup_project.sh" $PROJECT_NAME $DATABASE_TYPE "$DISPLAY_NAME" "$PROJECT_DESCRIPTION" "$PROJECT_EMOJI" $SETUP_OPTIONS
fi

cd "$ORIG_DIR"