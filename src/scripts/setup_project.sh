#!/bin/bash

set -e


ORIG_DIR=$(pwd)

# Get the directory of this script, handling both direct execution and sourcing
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Script is being sourced
    SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
else
    # Script is being executed directly
    SCRIPT_DIR="$(dirname "$(realpath "$0")")"
fi

cd "$SCRIPT_DIR/.."

DEV_DIR=$(pwd)

# Pre check to make sure development is installed (also sources functions.sh and .env)
source "$DEV_DIR/scripts/pre_check.sh"


# Function to display usage
usage() {
    echo-white "Usage: $0 <project_name> [database_engine] [display_name] [description] [emoji] [options]"
    echo-white "Sets up a project in the projects directory"
    echo-white ""
    echo-white "Arguments:"
    echo-white "  project_name     Name of the project to setup"
    echo-white "  database_engine  Database type: mysql, postgres, mongo (default: mysql)"
    echo-white "  display_name     Display name for project (optional)"
    echo-white "  description      Project description (optional)"
    echo-white "  emoji            Project emoji (default: 🚀)"
    echo-white ""
    echo-white "Options:"
    echo-white "  --json-output           Output JSON responses (for programmatic use)"
    echo-white "  --no-colors             Disable colored output"
    echo-white "  --overwrite-docker-compose  Overwrite existing docker-compose.yaml without prompting"
    echo-white "  --php-version VERSION   Force specific PHP version (7 or 8)"
    echo-white ""
    echo-white "Examples:"
    echo-white "  $0 my-project mysql"
    echo-white "  $0 my-project postgres --json-output"
    
    error "usage" 1
}


# Initialize variables
PROJECT_NAME=""
DATABASE_ENGINE="mariadb"
DISPLAY_NAME=""
PROJECT_DESCRIPTION=""
PROJECT_EMOJI="🚀"
OVERWRITE_DOCKER_COMPOSE=""
FORCED_PHP_VERSION=""
JSON_OUTPUT="${JSON_OUTPUT:-}"
NO_COLOR="${NO_COLOR:-}"

# Parse command line arguments
POSITIONAL_ARGS=()
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
                FORCED_PHP_VERSION="$2"
                shift 2
            else
                error "Error: --php-version requires a version number"
            fi
            ;;
        --help)
            usage
            ;;
        -*)
            error "Unknown option: $1. Use --help for usage information"
            ;;
        *)
            # Collect positional arguments
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

# Assign positional arguments
if [ ${#POSITIONAL_ARGS[@]} -lt 1 ]; then
    error "Error: Project name is required."
fi

PROJECT_NAME="${POSITIONAL_ARGS[0]}"
if [ ${#POSITIONAL_ARGS[@]} -gt 1 ]; then
    DATABASE_ENGINE="${POSITIONAL_ARGS[1]}"
fi
if [ ${#POSITIONAL_ARGS[@]} -gt 2 ]; then
    DISPLAY_NAME="${POSITIONAL_ARGS[2]}"
fi
if [ ${#POSITIONAL_ARGS[@]} -gt 3 ]; then
    PROJECT_DESCRIPTION="${POSITIONAL_ARGS[3]}"
fi
if [ ${#POSITIONAL_ARGS[@]} -gt 4 ]; then
    PROJECT_EMOJI="${POSITIONAL_ARGS[4]}"
fi

# Interactive prompts for metadata (only in interactive mode)
if [[ "$JSON_OUTPUT" != "1" ]]; then
    # Prompt for display name if not provided
    if [ -z "$DISPLAY_NAME" ]; then
        echo-yellow -n "Enter project display name [$PROJECT_NAME]: "
        read USER_DISPLAY_NAME
        if [ -n "$USER_DISPLAY_NAME" ]; then
            DISPLAY_NAME="$USER_DISPLAY_NAME"
        else
            DISPLAY_NAME="$PROJECT_NAME"
        fi
    fi
    
    # Prompt for description if not provided
    if [ -z "$PROJECT_DESCRIPTION" ]; then
        echo-yellow -n "Enter project description (optional): "
        read USER_DESCRIPTION
        PROJECT_DESCRIPTION="$USER_DESCRIPTION"
    fi
    
    # Prompt for emoji if not provided
    if [ -z "$PROJECT_EMOJI" ] || [ "$PROJECT_EMOJI" = "🚀" ]; then
        echo-yellow "Choose project emoji:"
        echo-white "1)  🚀 Rocket     2)  💻 Computer   3)  🌟 Star       4)  🔥 Fire"
        echo-white "5)  ⚡ Lightning   6)  🎯 Target     7)  🏆 Trophy     8)  💎 Diamond"
        echo-white "9)  🎨 Art        10) 🔧 Wrench     11) 📱 Mobile     12) 🌐 Globe"
        echo-white "13) 🎮 Game       14) 📊 Chart      15) 🛡️ Shield"
        echo-yellow -n "Select emoji (1-15) [1]: "
        read USER_EMOJI_CHOICE
        
        case "${USER_EMOJI_CHOICE:-1}" in
            1) PROJECT_EMOJI="🚀" ;;
            2) PROJECT_EMOJI="💻" ;;
            3) PROJECT_EMOJI="🌟" ;;
            4) PROJECT_EMOJI="🔥" ;;
            5) PROJECT_EMOJI="⚡" ;;
            6) PROJECT_EMOJI="🎯" ;;
            7) PROJECT_EMOJI="🏆" ;;
            8) PROJECT_EMOJI="💎" ;;
            9) PROJECT_EMOJI="🎨" ;;
            10) PROJECT_EMOJI="🔧" ;;
            11) PROJECT_EMOJI="📱" ;;
            12) PROJECT_EMOJI="🌐" ;;
            13) PROJECT_EMOJI="🎮" ;;
            14) PROJECT_EMOJI="📊" ;;
            15) PROJECT_EMOJI="🛡️" ;;
            *) 
                echo-yellow "Invalid choice. Defaulting to 🚀 Rocket."
                PROJECT_EMOJI="🚀" 
                ;;
        esac
    fi
else
    # Set default display name if not provided (JSON mode)
    if [ -z "$DISPLAY_NAME" ]; then
        DISPLAY_NAME="$PROJECT_NAME"
    fi
fi

# Use the configured projects directory
PROJECTS_DIR="$PROJECTS_DIR_PATH"
PROJECT_DIR="$PROJECTS_DIR/$PROJECT_NAME"


# Check for project folder existence
if ! [ -d "$PROJECT_DIR" ]; then
    error "Project folder does not exist!"
fi


# Start micro services
if [[ "$JSON_OUTPUT" == "1" ]]; then
    START_SERVICES_OUTPUT=$(source "$DEV_DIR/scripts/start_services.sh" 2>&1)
    START_SERVICES_EXIT_CODE=$?
    if [ $START_SERVICES_EXIT_CODE -ne 0 ]; then
        echo "$START_SERVICES_OUTPUT"
        exit $START_SERVICES_EXIT_CODE
    fi
else
    source "$DEV_DIR/scripts/start_services.sh"
fi


# Only shutdown project if docker-compose.yaml already exists (existing project reconfiguration)
# For new projects, there's no need to shut down containers that don't exist yet
if [ -f "$PROJECT_DIR/docker-compose.yaml" ]; then
    echo-yellow "Existing project detected. Shutting down containers before reconfiguration..."
    if [[ "$JSON_OUTPUT" == "1" ]]; then
        SHUTDOWN_OUTPUT=$(source "$DEV_DIR/scripts/shutdown.sh" $PROJECT_NAME 2>&1) || true
    else
        source "$DEV_DIR/scripts/shutdown.sh" $PROJECT_NAME || true
    fi
else
    echo-green "New project detected. Skipping container shutdown."
fi


# Enter into project and get PHP version
cd "$PROJECT_DIR"

echo-return "$(pwd)"; echo-return

# Determine PHP version
PHP_VERSION=""

# Use forced version if provided
if [ -n "$FORCED_PHP_VERSION" ]; then
    if [[ "$FORCED_PHP_VERSION" == "7" || "$FORCED_PHP_VERSION" == "8" ]]; then
        PHP_VERSION="$FORCED_PHP_VERSION"
    else
        error "ERROR: Invalid PHP version '$FORCED_PHP_VERSION'. Must be 7 or 8."
    fi
fi

# If not forced, try to detect from existing files
if [ -z "$PHP_VERSION" ]; then
    # Check composer.json first
    if [ -f "composer.json" ]; then
        if grep -q '"php":\s*"^7' composer.json; then
            PHP_VERSION="7"
        elif grep -q '"php":\s*"^8' composer.json; then
            PHP_VERSION="8"
        fi
    fi
    
    # Check for WordPress readme.html if still not determined
    if [ -z "$PHP_VERSION" ] && [ -f "readme.html" ]; then
        if grep -q '<strong>8\.[0-9]\+</strong>' readme.html; then
            PHP_VERSION="8"
        elif grep -q '<strong>7\.[0-9]\+</strong>' readme.html; then
            PHP_VERSION="7"
        fi
    fi
    
    # If still not determined, handle based on mode and project type
    if [ -z "$PHP_VERSION" ]; then
        if [[ "$JSON_OUTPUT" != "1" ]]; then
            # Check if this looks like a new project (minimal files)
            FILE_COUNT=$(find . -maxdepth 1 -type f | wc -l)
            if [ "$FILE_COUNT" -le 3 ]; then  # Likely just index.php, maybe .gitignore, etc.
                PHP_VERSION="8"
            else
                # For existing projects with many files, ask the user
                echo-yellow "Could not determine PHP version automatically."
                echo-yellow -n "Which PHP version would you like to use? (7/8) [8]: "
                read USER_PHP_VERSION
                if [ -z "$USER_PHP_VERSION" ]; then
                    PHP_VERSION="8"
                elif [[ "$USER_PHP_VERSION" == "7" || "$USER_PHP_VERSION" == "8" ]]; then
                    PHP_VERSION="$USER_PHP_VERSION"
                else
                    echo-red "Invalid PHP version. Defaulting to 8."
                    PHP_VERSION="8"
                fi
            fi
        else
            # JSON mode - default to 8
            PHP_VERSION="8"
        fi
    fi
fi


# Display appropriate message based on how PHP version was determined
FILE_COUNT=$(find . -maxdepth 1 -type f | wc -l)
if [[ "$JSON_OUTPUT" != "1" ]] && [ "$FILE_COUNT" -le 3 ] && [ -z "$FORCED_PHP_VERSION" ]; then
    echo-green "New project detected. Defaulting to PHP $PHP_VERSION."
fi

echo-green "Using PHP version: $PHP_VERSION"


# Convert dashes to underscores
PROJECT_NAME_SNAKE=$(echo "$PROJECT_NAME" | sed 's/-/_/g')


# Get a random D class number and make sure it doesn' already exist in hosts file
echo-return -n "Docker IP Address: "

while true; do

    D_CLASS=$((RANDOM % (250 - 100 + 1) + 100))

    IP_ADDRESS="$VPC_SUBNET.$D_CLASS"

    if ! cat /etc/hosts | grep "$IP_ADDRESS"; then break; fi

done

# Write the new project host and Docker IP address
while true; do

    HOST_LINE=$(grep -n -m 1 " $PROJECT_NAME$" /etc/hosts | cut -d : -f 1)

    if ! [[ -z $HOST_LINE ]]; then

        sudo-podium-sed "${HOST_LINE}d" /etc/hosts

    else

        break

    fi

done


# Enter new Docker IP address
if [[ "$JSON_OUTPUT" == "1" ]]; then
        echo "$IP_ADDRESS      $PROJECT_NAME" | sudo tee -a /etc/hosts > /dev/null
    else
        echo "$IP_ADDRESS      $PROJECT_NAME" | sudo tee -a /etc/hosts
    fi

echo-return


# Check if docker-compose.yaml already exists and handle overwrite using reusable function
handle_docker_compose_conflict "docker-compose.yaml" "setup"


# Use absolute path to docker-stack directory
PODIUM_DIR="$DEV_DIR"
cp -f "$PODIUM_DIR/docker-stack/docker-compose.project.yaml" docker-compose.yaml

podium-sed "s/IPV4_ADDRESS/$IP_ADDRESS/g" docker-compose.yaml

podium-sed "s/CONTAINER_NAME/$PROJECT_NAME/g" docker-compose.yaml

podium-sed "s/PHP_VERSION/$PHP_VERSION/g" docker-compose.yaml

podium-sed "s/PROJECT_PORT/$D_CLASS/g" docker-compose.yaml

# Replace metadata fields - use sed with proper UTF-8 handling
# Ensure variables have default values to avoid issues with empty strings
PROJECT_EMOJI_SAFE="${PROJECT_EMOJI:-🚀}"
DISPLAY_NAME_SAFE="${DISPLAY_NAME:-$PROJECT_NAME}"
PROJECT_DESCRIPTION_SAFE="${PROJECT_DESCRIPTION:-}"

# Use a delimiter that's very unlikely to appear in the replacement text
podium-sed "s#PROJECT_EMOJI#$PROJECT_EMOJI_SAFE#g" docker-compose.yaml
podium-sed "s#PROJECT_NAME#$DISPLAY_NAME_SAFE#g" docker-compose.yaml  
podium-sed "s#PROJECT_DESCRIPTION#$PROJECT_DESCRIPTION_SAFE#g" docker-compose.yaml

if [ -d "public" ]; then

    podium-sed "s/PUBLIC//g" docker-compose.yaml

else

    podium-sed "s/PUBLIC/\/public/g" docker-compose.yaml

fi

# Start the project container before composer installation
cd "$PROJECT_DIR"

echo-cyan "Current directory: $(pwd)"

echo-cyan "Starting project container for composer installation..."

# Start the project and capture output if in JSON mode
if [[ "$JSON_OUTPUT" == "1" ]]; then
    STARTUP_OUTPUT=$(source "$DEV_DIR/scripts/startup.sh" "$PROJECT_NAME" 2>&1)
    STARTUP_EXIT_CODE=$?
else
    source "$DEV_DIR/scripts/startup.sh" "$PROJECT_NAME"
    STARTUP_EXIT_CODE=$?
fi

if [ $STARTUP_EXIT_CODE -ne 0 ]; then
    error "Failed to start project container"
fi

# Install Composer libraries
if [ -f "composer.json" ]; then

    echo-cyan "Installing vendor libs with composer ..."; echo-white

    json-composer install

    echo-green "Vendor libs installed!"; echo-white

fi


# Install and setup .env file
unalias cp 2>/dev/null || true

if [ -f ".env.example" ]; then

    echo-cyan "Setting up .env file ..."; echo-white

    cp -f .env.example .env

    APP_KEY="base64:$(head -c 32 /dev/urandom | base64)"

    podium-sed-change "/^#*\s*APP_NAME=/" "APP_NAME=$PROJECT_NAME" .env
    podium-sed-change "/^#*\s*APP_KEY=/" "APP_KEY=$APP_KEY" .env
    podium-sed-change "/^#*\s*APP_URL=/" "APP_URL=http://$PROJECT_NAME" .env
    # Configure database connection based on selected engine
    case $DATABASE_ENGINE in
        "postgresql")
            podium-sed-change "/^#*\s*DB_CONNECTION=/" "DB_CONNECTION=pgsql" .env
            podium-sed-change "/^#*\s*DB_HOST=/" "DB_HOST=postgres" .env
            podium-sed-change "/^#*\s*DB_PORT=/" "DB_PORT=5432" .env
            podium-sed-change "/^#*\s*DB_DATABASE=/" "DB_DATABASE=$PROJECT_NAME_SNAKE" .env
            podium-sed-change "/^#*\s*DB_USERNAME=/" "DB_USERNAME=postgres" .env
            podium-sed-change "/^#*\s*DB_PASSWORD=/" "DB_PASSWORD=postgres" .env
            ;;
        "mongodb")
            podium-sed-change "/^#*\s*DB_CONNECTION=/" "DB_CONNECTION=mongodb" .env
            podium-sed-change "/^#*\s*DB_HOST=/" "DB_HOST=mongo" .env
            podium-sed-change "/^#*\s*DB_PORT=/" "DB_PORT=27017" .env
            podium-sed-change "/^#*\s*DB_DATABASE=/" "DB_DATABASE=$PROJECT_NAME_SNAKE" .env
            podium-sed-change "/^#*\s*DB_USERNAME=/" "DB_USERNAME=root" .env
            podium-sed-change "/^#*\s*DB_PASSWORD=/" "DB_PASSWORD=root" .env
            ;;
        *)
            podium-sed-change "/^#*\s*DB_CONNECTION=/" "DB_CONNECTION=mysql" .env
            podium-sed-change "/^#*\s*DB_HOST=/" "DB_HOST=mariadb" .env
            podium-sed-change "/^#*\s*DB_PORT=/" "DB_PORT=3306" .env
            podium-sed-change "/^#*\s*DB_DATABASE=/" "DB_DATABASE=$PROJECT_NAME_SNAKE" .env
            podium-sed-change "/^#*\s*DB_USERNAME=/" "DB_USERNAME=root" .env
            podium-sed-change "/^#*\s*DB_PASSWORD=/" "DB_PASSWORD=" .env
            ;;
    esac
    podium-sed-change "/^#*\s*CACHE_DRIVER=/" "CACHE_DRIVER=redis" .env
    podium-sed-change "/^#*\s*SESSION_DRIVER=/" "SESSION_DRIVER=redis" .env
    podium-sed-change "/^#*\s*QUEUE_CONNECTION=/" "QUEUE_CONNECTION=redis" .env
    podium-sed-change "/^#*\s*CACHE_STORE=/" "CACHE_STORE=redis" .env
    podium-sed-change "/^#*\s*CACHE_PREFIX=/" "CACHE_PREFIX=$PROJECT_NAME" .env
    podium-sed-change "/^#*\s*MEMCACHED_HOST=/" "MEMCACHED_HOST=memcached" .env
    podium-sed-change "/^#*\s*REDIS_HOST=/" "REDIS_HOST=redis" .env
    # Configure MailHog for development email testing
    podium-sed-change "/^#*\s*MAIL_MAILER=/" "MAIL_MAILER=smtp" .env
    podium-sed-change "/^#*\s*MAIL_HOST=/" "MAIL_HOST=mailhog" .env
    podium-sed-change "/^#*\s*MAIL_PORT=/" "MAIL_PORT=1025" .env
    podium-sed-change "/^#*\s*MAIL_USERNAME=/" "MAIL_USERNAME=null" .env
    podium-sed-change "/^#*\s*MAIL_PASSWORD=/" "MAIL_PASSWORD=null" .env
    podium-sed-change "/^#*\s*MAIL_ENCRYPTION=/" "MAIL_ENCRYPTION=null" .env
    podium-sed-change "/^#*\s*MAIL_FROM_ADDRESS=/" "MAIL_FROM_ADDRESS=\"hello@$PROJECT_NAME.local\"" .env
    podium-sed-change "/^#*\s*MAIL_FROM_NAME=/" "MAIL_FROM_NAME=\"$PROJECT_NAME\"" .env
    echo "" >> .env
    echo "XDG_CONFIG_HOME=/usr/share/nginx/html/storage/app" >> .env

    echo-green "The .env file has been created!"; echo-white

# Install config.inc file
elif [ -f "config.example.inc.php" ]; then

    cp -f config.example.inc.php config.inc.php

    podium-sed "s/DB_HOSTNAME/mariadb/" config.inc.php
    podium-sed "s/DB_USERNAME/root/" config.inc.php
    podium-sed "s/DB_PASSWORD//" config.inc.php
    podium-sed "s/DB_NAME/$PROJECT_NAME_SNAKE/" config.inc.php

# Install wp-config file
elif [ -f "wp-config-sample.php" ]; then

    echo-cyan "Configuring WordPress for containerized setup..."
    
    # WordPress only supports MySQL/MariaDB - force to mariadb if anything else is specified
    if [[ "$DATABASE_ENGINE" != "mysql" && "$DATABASE_ENGINE" != "mariadb" ]]; then
        echo-yellow "Warning: WordPress only supports MySQL/MariaDB. Switching to MariaDB."
        DATABASE_ENGINE="mariadb"
    fi
    
    DB_HOST_VALUE="mariadb"
    
    # Create wp-config.php with database connection
    cat > wp-config.php << EOF
<?php
define('DB_NAME', '$PROJECT_NAME_SNAKE');
define('DB_USER', 'root');
define('DB_PASSWORD', '');
define('DB_HOST', '$DB_HOST_VALUE');
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');

define('AUTH_KEY',         '$(openssl rand -base64 32)');
define('SECURE_AUTH_KEY',  '$(openssl rand -base64 32)');
define('LOGGED_IN_KEY',    '$(openssl rand -base64 32)');
define('NONCE_KEY',        '$(openssl rand -base64 32)');
define('AUTH_SALT',        '$(openssl rand -base64 32)');
define('SECURE_AUTH_SALT', '$(openssl rand -base64 32)');
define('LOGGED_IN_SALT',   '$(openssl rand -base64 32)');
define('NONCE_SALT',       '$(openssl rand -base64 32)');

\$table_prefix = 'wp_';

define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
define('WP_DEBUG_DISPLAY', false);

if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}

require_once ABSPATH . 'wp-settings.php';
EOF
    
    echo-green "WordPress configuration created!"
    echo-white
    echo-cyan "WordPress will be automatically set up when the container starts."
    echo-white "After setup completes, visit http://$PROJECT_NAME to complete the WordPress installation."

fi

echo-return; echo-return


# Make storage writable for all
if [ -d "storage" ]; then

    echo-cyan 'Setting folder permissions ...'; echo-white

    find storage -type d -exec chmod 777 {} +

    find storage -type d -exec setfacl -m "default:group::rw" {} +

    echo-green 'Storage folder permissions set!'; echo-white

fi

# Create new database, run migration and seed
echo-cyan "Creating database $PROJECT_NAME_SNAKE ..."; echo-white

json-mysql -h"mariadb" -u"root" -e "CREATE DATABASE IF NOT EXISTS $PROJECT_NAME_SNAKE;"

echo-green 'Database created!'; echo-white

if [ -f "artisan" ]; then

    echo-cyan 'Running migrations ...'; echo-white

    if [[ "$JSON_OUTPUT" == "1" ]]; then
        art-docker migrate:fresh > /dev/null 2>&1
        MIGRATE_SUCCESS=$?
    else
        art-docker migrate:fresh
        MIGRATE_SUCCESS=$?
    fi
    
    if [ $MIGRATE_SUCCESS -eq 0 ]; then

        echo-green 'Migrations successful'; echo-white

        echo-cyan 'Seeding database ...'; echo-white

        if [[ "$JSON_OUTPUT" == "1" ]]; then
            art-docker db:seed > /dev/null 2>&1
            SEED_SUCCESS=$?
        else
            art-docker db:seed
            SEED_SUCCESS=$?
        fi
        
        if [ $SEED_SUCCESS -eq 0 ]; then

            echo-green 'Database seeded!'; echo-white

        fi

    fi

elif [ -f "create_tables.sql" ]; then

    echo-cyan 'Creating tables ...'; echo-white

    mysql -h"mariadb" -u"root" $PROJECT_NAME_SNAKE < create_tables.sql

fi

echo-return; echo-return


# Setup gitignore if not already present
setup_gitignore() {
    local framework_type=""
    
    # Detect framework type
    if [ -f "artisan" ]; then
        framework_type="laravel"
    elif [ -f "wp-config-sample.php" ] || [ -f "wp-config.php" ]; then
        framework_type="wordpress"
    else
        framework_type="php"
    fi
    
    # Only create .gitignore if it doesn't exist
    if [ ! -f ".gitignore" ]; then
        case $framework_type in
            "laravel")
                # Laravel should already have .gitignore, but add docker-compose.yaml if missing
                if ! grep -q "docker-compose.yaml" .gitignore 2>/dev/null; then
                    echo "" >> .gitignore
                    echo "# Docker infrastructure" >> .gitignore
                    echo "docker-compose.yaml" >> .gitignore
                fi
                ;;
            "wordpress")
                cat > .gitignore << 'EOF'
# Docker infrastructure
docker-compose.yaml

# WordPress core files
wp-config.php
wp-content/uploads/
wp-content/cache/
wp-content/backup-db/
wp-content/advanced-cache.php
wp-content/wp-cache-config.php
wp-content/plugins/hello.php
wp-content/plugins/akismet/
wp-content/upgrade/
wp-content/debug.log

# Environment files
.env
.env.local

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db
EOF
                ;;
            "php")
                cat > .gitignore << 'EOF'
# Docker infrastructure
docker-compose.yaml

# Dependencies
vendor/
node_modules/

# Environment files
.env
.env.local

# IDE files
.vscode/
.idea/
*.swp
*.swo

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db
EOF
                ;;
        esac
        
        if [[ "$JSON_OUTPUT" != "1" ]]; then
            echo-green ".gitignore file created for $framework_type project!"
        fi
    else
        # Ensure docker-compose.yaml is in existing .gitignore
        if ! grep -q "docker-compose.yaml" .gitignore; then
            echo "" >> .gitignore
            echo "# Docker infrastructure" >> .gitignore
            echo "docker-compose.yaml" >> .gitignore
            echo-green "Added docker-compose.yaml to existing .gitignore"
        fi
    fi
}

# Setup gitignore
setup_gitignore

# Setup completed
if [[ "$JSON_OUTPUT" == "1" ]]; then
    # Build JSON response with optional fields
    JSON_RESPONSE="{\"action\": \"setup_project\", \"project_name\": \"$PROJECT_NAME\", \"database\": \"$DATABASE_ENGINE\", \"php_version\": \"$PHP_VERSION\", \"status\": \"success\""
    
    # Add shutdown result if captured
    if [ -n "$SHUTDOWN_OUTPUT" ]; then
        JSON_RESPONSE="$JSON_RESPONSE, \"shutdown_result\": $SHUTDOWN_OUTPUT"
    fi
    
    # Add startup result if captured
    if [ -n "$STARTUP_OUTPUT" ]; then
        JSON_RESPONSE="$JSON_RESPONSE, \"startup_result\": $STARTUP_OUTPUT"
    fi
    
    JSON_RESPONSE="$JSON_RESPONSE}"
    echo "$JSON_RESPONSE"
else
    echo-return; echo-return
    echo-green "Setup completed for project: $PROJECT_NAME"
    echo-white "Database: $DATABASE_ENGINE"
    echo-white "PHP Version: $PHP_VERSION"
    echo-return
    echo-cyan "To start the project, run: podium up $PROJECT_NAME"
    echo-return
fi

# Return to original directory
cd "$ORIG_DIR"
