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
    echo-white "  --debug                 Enable debug logging to /tmp/podium-cli-debug.log"
    echo-white "  --overwrite-docker-compose  Overwrite existing docker-compose.yaml without prompting"
    echo-white "  --framework FRAMEWORK   Force specific framework (laravel, wordpress, php, fastapi, django, python, express, nestjs, fastify, node)"
    echo-white "  --no-storage-symlink    Skip creating public/storage symlink (Laravel only)"
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
SKIP_STORAGE_SYMLINK=false
JSON_OUTPUT="${JSON_OUTPUT:-}"
NO_COLOR="${NO_COLOR:-}"

# Capture original arguments for debug logging
ORIGINAL_ARGS="$*"

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
        --framework)
            if [ -n "$2" ] && [[ ! "$2" =~ ^-- ]]; then
                FORCED_FRAMEWORK="$2"
                shift 2
            else
                error "Error: --framework requires a framework type (laravel, wordpress, php)"
            fi
            ;;
        --no-storage-symlink)
            SKIP_STORAGE_SYMLINK=true
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

# Initialize debug logging
debug "Script started: setup_project.sh with args: $ORIGINAL_ARGS"

# Interactive prompts for metadata (only when stdout is a real terminal)
if [[ "$JSON_OUTPUT" != "1" ]] && [ -t 0 ]; then
    # Prompt for display name if not provided
    if [ -z "$DISPLAY_NAME" ]; then
        echo-yellow -n "Enter project name [$PROJECT_NAME]: "
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
    # Non-interactive: apply defaults silently
    [ -z "$DISPLAY_NAME" ] && DISPLAY_NAME="$PROJECT_NAME"
    [ -z "$PROJECT_EMOJI" ]  && PROJECT_EMOJI="🚀"
fi

# Use the configured projects directory
PROJECTS_DIR="$PROJECTS_DIR_PATH"
PROJECT_DIR="$PROJECTS_DIR/$PROJECT_NAME"

# Cleanup state flags — set as operations complete so trap can undo them
_hosts_entry_added=0
_compose_file_created=0
_container_started=0

_setup_cleanup() {
    local code=$?
    [ $code -eq 0 ] && return
    echo-red "Setup failed — cleaning up partial state..."
    if [ "$_container_started" = "1" ] && [ -f "$PROJECT_DIR/docker-compose.yaml" ]; then
        (cd "$PROJECTS_DIR_PATH" && docker compose -f "$PROJECT_DIR/docker-compose.yaml" down --remove-orphans 2>/dev/null) || true
    fi
    if [ "$_hosts_entry_added" = "1" ]; then
        sudo sed -i "/ $PROJECT_NAME$/d" /etc/hosts 2>/dev/null || true
    fi
    if [ "$_compose_file_created" = "1" ]; then
        rm -f "$PROJECT_DIR/docker-compose.yaml"
    fi
}
trap _setup_cleanup ERR

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


# Only shutdown project if a docker-compose file already exists (existing project reconfiguration)
# For new projects, there's no need to shut down containers that don't exist yet
if [ -f "$PROJECT_DIR/docker-compose.yaml" ] || [ -f "$PROJECT_DIR/docker-compose.yml" ]; then
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

# Resolve FRAMEWORK if not already set (e.g. when setup_project.sh is called directly)
if [ -z "$FRAMEWORK" ]; then
    if [ -n "$FORCED_FRAMEWORK" ]; then
        FRAMEWORK="$FORCED_FRAMEWORK"
    elif [ -f "main.py" ]; then
        FRAMEWORK="fastapi"
    elif [ -f "manage.py" ]; then
        FRAMEWORK="django"
    elif [ -f "wp-config-sample.php" ] || [ -f "wp-config.php" ]; then
        FRAMEWORK="wordpress"
    elif [ -f "artisan" ]; then
        FRAMEWORK="laravel"
    elif [ -f "package.json" ] && [ ! -f "composer.json" ] && [ ! -f "artisan" ]; then
        if grep -q '"@nestjs/core"' package.json 2>/dev/null; then
            FRAMEWORK="nestjs"
        elif grep -q '"fastify"' package.json 2>/dev/null; then
            FRAMEWORK="fastify"
        elif grep -q '"express"' package.json 2>/dev/null; then
            FRAMEWORK="express"
        else
            FRAMEWORK="node"
        fi
    else
        FRAMEWORK="php"
    fi
fi

# Load framework registry
source "$DEV_DIR/frameworks/${FRAMEWORK}.sh"

echo-return "$(pwd)"; echo-return

# Determine PHP version


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
_hosts_entry_added=1

echo-return


# Check if a docker-compose file already exists and handle overwrite using reusable function
EXISTING_COMPOSE_FILE=""
if [ -f "docker-compose.yaml" ]; then
    EXISTING_COMPOSE_FILE="docker-compose.yaml"
elif [ -f "docker-compose.yml" ]; then
    EXISTING_COMPOSE_FILE="docker-compose.yml"
fi

if [ -n "$EXISTING_COMPOSE_FILE" ]; then
    handle_docker_compose_conflict "$EXISTING_COMPOSE_FILE" "setup"
    # At this point, either the operation was cancelled (error/exit)
    # or overwrite has been confirmed/forced. Remove any existing
    # docker-compose files so the Podium-managed one is the only source.
    rm -f docker-compose.yml docker-compose.yaml
fi


# Use absolute path to docker-stack directory
PODIUM_DIR="$DEV_DIR"
if [ "$FRAMEWORK_IS_PYTHON" = "1" ]; then
    cp -f "$PODIUM_DIR/docker-stack/docker-compose.python3-project.yaml" docker-compose.yaml
elif [ "$FRAMEWORK_IS_NODE" = "1" ]; then
    cp -f "$PODIUM_DIR/docker-stack/docker-compose.node-project.yaml" docker-compose.yaml
else
    cp -f "$PODIUM_DIR/docker-stack/docker-compose.php8.yaml" docker-compose.yaml
fi
_compose_file_created=1

podium-sed "s/IPV4_ADDRESS/$IP_ADDRESS/g" docker-compose.yaml

podium-sed "s/CONTAINER_NAME/$PROJECT_NAME/g" docker-compose.yaml

podium-sed "s/PROJECT_PORT/$D_CLASS/g" docker-compose.yaml

# Replace metadata fields - use sed with proper UTF-8 handling
# Ensure variables have default values to avoid issues with empty strings
PROJECT_EMOJI_SAFE="${PROJECT_EMOJI:-🚀}"
DISPLAY_NAME_SAFE="${DISPLAY_NAME:-$PROJECT_NAME}"
PROJECT_DESCRIPTION_SAFE="${PROJECT_DESCRIPTION:-}"

# Escape any embedded double quotes to keep YAML valid inside the surrounding quotes
PROJECT_EMOJI_SAFE="${PROJECT_EMOJI_SAFE//\"/\\\"}"
DISPLAY_NAME_SAFE="${DISPLAY_NAME_SAFE//\"/\\\"}"
PROJECT_DESCRIPTION_SAFE="${PROJECT_DESCRIPTION_SAFE//\"/\\\"}"

# Use a delimiter that's very unlikely to appear in the replacement text
podium-sed "s#PROJECT_EMOJI#$PROJECT_EMOJI_SAFE#g" docker-compose.yaml
podium-sed "s#PROJECT_NAME#$DISPLAY_NAME_SAFE#g" docker-compose.yaml
podium-sed "s#PROJECT_DESCRIPTION#$PROJECT_DESCRIPTION_SAFE#g" docker-compose.yaml

if [ -d "public" ] || [ "$FRAMEWORK_IS_PYTHON" = "1" ] || [ "$FRAMEWORK_IS_NODE" = "1" ]; then
    podium-sed "s/PUBLIC//g" docker-compose.yaml
else
    podium-sed "s/PUBLIC/\/public/g" docker-compose.yaml
fi

# Set start command for Python or Node projects
if [ "$FRAMEWORK_IS_PYTHON" = "1" ]; then
    podium-sed "s|PYTHON_START_COMMAND|$(framework_python_start_command)|g" docker-compose.yaml
elif [ "$FRAMEWORK_IS_NODE" = "1" ]; then
    podium-sed "s|NODE_START_COMMAND|$(framework_node_start_command)|g" docker-compose.yaml
fi

# Start the project container before composer installation
cd "$PROJECT_DIR"

echo-cyan "Current directory: $(pwd)"

echo-cyan "Starting project container for composer installation..."

# Start the project and capture output if in JSON mode
debug "About to start project container via startup.sh"
debug "Current directory before startup: $(pwd)"
# startup.sh expects to be run from the projects directory
cd "$PROJECTS_DIR_PATH"
debug "Changed to projects directory: $(pwd)"

if [[ "$JSON_OUTPUT" == "1" ]]; then
    debug "Calling startup.sh in JSON mode"
    STARTUP_OUTPUT=$(source "$DEV_DIR/scripts/startup.sh" "$PROJECT_NAME" 2>&1)
    STARTUP_EXIT_CODE=$?
    debug "startup.sh completed with exit code: $STARTUP_EXIT_CODE"
else
    debug "Calling startup.sh in interactive mode"
    source "$DEV_DIR/scripts/startup.sh" "$PROJECT_NAME"
    STARTUP_EXIT_CODE=$?
    debug "startup.sh completed with exit code: $STARTUP_EXIT_CODE"
fi

if [ $STARTUP_EXIT_CODE -ne 0 ]; then
    debug "startup.sh failed, calling error function"
    error "Failed to start project container"
fi
debug "Project container started successfully"
_container_started=1

# Return to project directory after startup (startup.sh may have changed working directory)
debug "Returning to project directory: $PROJECT_DIR"
cd "$PROJECT_DIR"
debug "Current directory after returning: $(pwd)"

# Patch Django settings.py for cloned projects that haven't been patched yet (idempotent)
SETTINGS_FILE="${PROJECT_NAME_SNAKE}/settings.py"
if [ -f "manage.py" ] && [ -f "$SETTINGS_FILE" ] && ! grep -q "load_dotenv" "$SETTINGS_FILE"; then
    echo-cyan "Patching Django settings.py ..."; echo-white

    printf 'from dotenv import load_dotenv\nfrom pathlib import Path\nimport os\nimport pymysql\npymysql.install_as_MySQLdb()\nload_dotenv(Path(__file__).resolve().parent.parent / ".env")\n\n' | cat - "$SETTINGS_FILE" > /tmp/podium_settings_tmp.py && mv /tmp/podium_settings_tmp.py "$SETTINGS_FILE"

    podium-sed "s|^ALLOWED_HOSTS = \[.*\]|ALLOWED_HOSTS = [os.getenv('APP_URL', '').replace('http://', '').replace('https://', ''), '']|" "$SETTINGS_FILE"

    python3 - "$SETTINGS_FILE" << 'PYEOF'
import re, sys
path = sys.argv[1]
content = open(path).read()
new_db = """DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.' + os.getenv('DB_CONNECTION', 'mysql'),
        'NAME': os.getenv('DB_DATABASE', ''),
        'USER': os.getenv('DB_USERNAME', 'root'),
        'PASSWORD': os.getenv('DB_PASSWORD', ''),
        'HOST': os.getenv('DB_HOST', ''),
        'PORT': os.getenv('DB_PORT', '3306'),
    }
}"""
content = re.sub(r'DATABASES\s*=\s*\{[^}]*\{[^}]*\}[^}]*\}', new_db, content, flags=re.DOTALL)
open(path, 'w').write(content)
PYEOF
    echo-green "Django settings.py patched!"; echo-white
fi

# Install Composer libraries
debug "Checking for composer.json file"
if [ -f "composer.json" ]; then
    debug "Found composer.json, installing dependencies"
    echo-cyan "Installing vendor libs with composer ..."; echo-white

    debug "About to call json-composer install"
    json-composer install
    COMPOSER_EXIT_CODE=$?
    debug "json-composer install completed with exit code: $COMPOSER_EXIT_CODE"

    debug "Composer installation completed"
    echo-green "Vendor libs installed!"; echo-white
else
    debug "No composer.json found"
fi

# Install npm dependencies for Node projects
if [ "$FRAMEWORK_IS_NODE" = "1" ] && [ -f "package.json" ]; then
    echo-cyan "Installing Node dependencies with npm ..."; echo-white
    if [[ "$JSON_OUTPUT" == "1" ]]; then
        docker exec "$PROJECT_NAME" bash -c "cd /usr/share/nginx/html && npm install" > /dev/null 2>&1
    else
        docker exec "$PROJECT_NAME" bash -c "cd /usr/share/nginx/html && npm install"
    fi
    echo-green "Node dependencies installed!"; echo-white
    # Fix ownership so the host user can run podium npm install afterwards without EACCES
    docker exec "$PROJECT_NAME" bash -c "chown -R $(id -u):$(id -g) /usr/share/nginx/html/node_modules /usr/share/nginx/html/package-lock.json 2>/dev/null || true"
    # Restart the node-app supervisor program so it picks up the freshly installed packages
    if [[ "$JSON_OUTPUT" == "1" ]]; then
        docker exec "$PROJECT_NAME" supervisorctl restart node-app > /dev/null 2>&1
    else
        docker exec "$PROJECT_NAME" supervisorctl restart node-app
    fi
fi

# Install Python dependencies for Python projects
if [ "$FRAMEWORK_IS_PYTHON" = "1" ] && [ -f "requirements.txt" ]; then
    echo-cyan "Installing Python dependencies ..."; echo-white
    if [[ "$JSON_OUTPUT" == "1" ]]; then
        docker exec "$PROJECT_NAME" bash -c "cd /usr/share/nginx/html && pip3 install --break-system-packages -r requirements.txt" > /dev/null 2>&1
    else
        docker exec "$PROJECT_NAME" bash -c "cd /usr/share/nginx/html && pip3 install --break-system-packages -r requirements.txt"
    fi
    echo-green "Python dependencies installed!"; echo-white
fi

# Install and build front-end assets when Vite/Laravel is detected (host-side Node)
if [ -f "package.json" ]; then
    if grep -qi '"vite"' package.json; then
        debug "Detected Vite configuration in package.json; installing Node dependencies and building assets on host"
        if [[ "$JSON_OUTPUT" != "1" ]]; then
            echo-cyan "Installing Node dependencies on host (npm install) ..."; echo-white
        fi
        if [[ "$JSON_OUTPUT" == "1" ]]; then
            if ! npm install >/dev/null 2>&1; then
                echo-yellow "Warning: npm install failed on host. Vite assets may not be built."; echo-white
            else
                if ! npm run build >/dev/null 2>&1; then
                    echo-yellow "Warning: npm run build failed on host. Vite manifest may be missing."; echo-white
                fi
            fi
        else
            if ! npm install; then
                echo-yellow "Warning: npm install failed on host. Vite assets may not be built."; echo-white
            else
                echo-green "Node dependencies installed."; echo-white
                echo-cyan "Building front-end assets on host (npm run build) ..."; echo-white
                if ! npm run build; then
                    echo-yellow "Warning: npm run build failed on host. Vite manifest may be missing."; echo-white
                else
                    echo-green "Front-end assets built successfully."; echo-white
                fi
            fi
        fi
    else
        debug "package.json found but no Vite references detected; skipping npm install/build"
    fi
fi


# Install and setup .env / config file
unalias cp 2>/dev/null || true
framework_setup_env

echo-return; echo-return


# Make storage writable for all
if [ -d "storage" ]; then

    echo-cyan 'Setting folder permissions ...'; echo-white

    find storage -type d -exec chmod 777 {} +

    find storage -type d -exec setfacl -m "default:group::rw" {} +

    echo-green 'Storage folder permissions set!'; echo-white

    # Create storage symlink for Laravel unless disabled
    if [ "$SKIP_STORAGE_SYMLINK" != "true" ] && [ -f "artisan" ]; then
        if [ -d "public" ] && [ -d "storage/app/public" ]; then
            if [ -L "public/storage" ]; then
                :
            elif [ -e "public/storage" ]; then
                echo-yellow "public/storage exists and is not a symlink. Skipping storage symlink creation."
            else
                ln -s ../storage/app/public public/storage
                if [[ "$JSON_OUTPUT" != "1" ]]; then
                    echo-green "Symlink created: public/storage -> ../storage/app/public"
                fi
            fi
        fi
    fi

fi

# Create new database, run migration and seed
echo-cyan "Creating database $PROJECT_NAME_SNAKE ..."; echo-white

json-mysql -u"root" -e "CREATE DATABASE IF NOT EXISTS $PROJECT_NAME_SNAKE;"

echo-green 'Database created!'; echo-white

framework_run_migrations

echo-return; echo-return


# Setup gitignore
framework_setup_gitignore

# Setup completed
if [[ "$JSON_OUTPUT" == "1" ]]; then
    # Build JSON response with optional fields
    JSON_RESPONSE="{\"action\": \"setup_project\", \"project_name\": \"$PROJECT_NAME\", \"database\": \"$DATABASE_ENGINE\", \"status\": \"success\""
    
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
    echo-return

    # Build status options
    STATUS_OPTIONS=""
    if [[ "$NO_COLOR" == "1" ]]; then
        STATUS_OPTIONS="$STATUS_OPTIONS --no-colors"
    fi

    # Show status to confirm successful startup
    source "$DEV_DIR/scripts/status.sh" $PROJECT_NAME $STATUS_OPTIONS
fi

# Return to original directory
cd "$ORIG_DIR"
