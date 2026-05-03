#!/bin/bash

set -e


ORIG_DIR=$(pwd)

# Get the directory of this script, handling both direct execution and sourcing
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Script is being sourced
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)"
else
    # Script is being executed directly
    SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd -P)"
fi

cd "$SCRIPT_DIR/.."

DEV_DIR=$(pwd)

# Pre check to make sure development is installed (also sources functions.sh and .env)
source "$DEV_DIR/scripts/pre_check.sh"


# Function to display usage
usage() {
    echo-white "Usage: $0 <project_name> [database_engine] [options]"
    echo-white "Sets up a project in the projects directory"
    echo-white ""
    echo-white "Arguments:"
    echo-white "  project_name     Name of the project to setup"
    echo-white "  database_engine  Database type: mysql, postgres, mongo (default: mysql)"
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
OVERWRITE_DOCKER_COMPOSE=""
SKIP_STORAGE_SYMLINK=false
NO_STARTUP=0
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
        --no-startup)
            NO_STARTUP=1
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

# Initialize debug logging
debug "Script started: setup_project.sh with args: $ORIGINAL_ARGS"


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
        sudo-podium-sed "/ $PROJECT_NAME$/d" /etc/hosts 2>/dev/null || true
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

# Capture original compose and detect complexity before conflict handling deletes it
ORIGINAL_COMPOSE_TMPFILE="/tmp/podium_original_compose_$$.yaml"
ORIGINAL_COMPOSE_IS_COMPLEX=0
if [ -n "$EXISTING_COMPOSE_FILE" ]; then
    cp "$EXISTING_COMPOSE_FILE" "$ORIGINAL_COMPOSE_TMPFILE"
    ORIGINAL_COMPOSE_IS_COMPLEX=$(python3 - "$ORIGINAL_COMPOSE_TMPFILE" 2>/dev/null << 'PYEOF'
import sys, yaml, re
try:
    doc = yaml.safe_load(open(sys.argv[1]).read()) or {}
    services = doc.get('services') or {}
    if len(services) > 1:
        print(1); sys.exit(0)
    for svc in services.values():
        img = str((svc or {}).get('image', ''))
        if img and not re.search(r'canebaycomputers/cbc', img, re.I):
            print(1); sys.exit(0)
    print(0)
except Exception:
    print(0)
PYEOF
)
fi

if [ -n "$EXISTING_COMPOSE_FILE" ]; then
    # Complex projects are always adapted automatically — no confirmation needed.
    # For simple non-Podium composes, handle_docker_compose_conflict prompts the user
    # or can be bypassed with --overwrite-docker-compose.
    if [ "$ORIGINAL_COMPOSE_IS_COMPLEX" = "1" ]; then
        OVERWRITE_DOCKER_COMPOSE=1
    fi
    handle_docker_compose_conflict "$EXISTING_COMPOSE_FILE" "setup"
    # At this point, either the operation was cancelled (error/exit)
    # or overwrite has been confirmed/forced. Remove any existing
    # docker-compose files so the Podium-managed one is the only source.
    rm -f docker-compose.yml docker-compose.yaml
fi


# Use absolute path to docker-stack directory
PODIUM_DIR="$DEV_DIR"
if [ "$ORIGINAL_COMPOSE_IS_COMPLEX" = "1" ] && [ -f "$ORIGINAL_COMPOSE_TMPFILE" ]; then
    # Complex project: adapt the original docker-compose for Podium instead of using a cbc template.
    # Removes bundled DB/cache services, wires remaining services to podium-cli_vpc, assigns static IP.
    echo-cyan "Complex docker-compose detected — adapting for Podium environment..."
    ADAPT_SUMMARY=$(python3 - "$IP_ADDRESS" "$PROJECT_NAME" "$D_CLASS" "$ORIGINAL_COMPOSE_TMPFILE" docker-compose.yaml 2>/dev/null << 'PYEOF'
import sys, yaml, re, json

ip, project, d_class, src, dst = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5]

SHARED_BY_NAME = [
    (re.compile(r'^(postgres|postgresql|db|database|pg)$', re.I), 'podium-postgres'),
    (re.compile(r'^(mysql|mariadb)$', re.I),                      'podium-mariadb'),
    (re.compile(r'^(redis|cache|redis[-_]cache|valkey)$', re.I), 'podium-redis'),
    (re.compile(r'^(mongo|mongodb)$', re.I),                      'podium-mongo'),
    (re.compile(r'^(memcached|memcache)$', re.I),                 'podium-memcached'),
]
SHARED_BY_IMAGE = [
    (re.compile(r'^postgres(ql)?[:/]', re.I), 'podium-postgres'),
    (re.compile(r'^mysql[:/]', re.I),          'podium-mariadb'),
    (re.compile(r'^mariadb[:/]', re.I),        'podium-mariadb'),
    (re.compile(r'^redis[:/]', re.I),          'podium-redis'),
    (re.compile(r'^valkey[:/]', re.I),         'podium-redis'),
    (re.compile(r'^mongo(db)?[:/]', re.I),     'podium-mongo'),
]

doc = yaml.safe_load(open(src).read()) or {}
services = doc.get('services') or {}

replaced = {}
for name in list(services.keys()):
    svc = services[name] or {}
    image = str(svc.get('image', ''))
    matched = None
    for pat, host in SHARED_BY_NAME:
        if pat.match(name):
            matched = host; break
    if not matched:
        for pat, host in SHARED_BY_IMAGE:
            if pat.match(image):
                matched = host; break
    if matched:
        replaced[name] = matched
        del services[name]

WEB_NAMES = re.compile(r'^(nginx|web|app|api|server|frontend|backend|http)', re.I)
web_name = None
for name, svc in services.items():
    if (svc or {}).get('ports'):
        web_name = name; break
if not web_name:
    for name in services:
        if WEB_NAMES.match(name):
            web_name = name; break
if not web_name and services:
    web_name = next(iter(services))

for name, svc in services.items():
    svc = svc or {}
    env = svc.get('environment')
    if isinstance(env, dict):
        for k, v in list(env.items()):
            if isinstance(v, str) and v in replaced:
                env[k] = replaced[v]
    elif isinstance(env, list):
        new_env = []
        for item in env:
            if isinstance(item, str) and '=' in item:
                k, _, v = item.partition('=')
                if v in replaced:
                    v = replaced[v]
                item = f'{k}={v}'
            new_env.append(item)
        svc['environment'] = new_env
    dep = svc.get('depends_on')
    if isinstance(dep, list):
        new_dep = [d for d in dep if d not in replaced]
        if new_dep:
            svc['depends_on'] = new_dep
        else:
            svc.pop('depends_on', None)
    elif isinstance(dep, dict):
        for dead in list(replaced.keys()):
            dep.pop(dead, None)
        if not dep:
            svc.pop('depends_on', None)

for name, svc in services.items():
    svc = svc or {}
    if name == web_name:
        svc['container_name'] = project
        svc['networks'] = {'default': {'ipv4_address': ip}}
    else:
        svc['networks'] = ['default']

top_vols = doc.get('volumes') or {}
if top_vols:
    used = set()
    for svc in services.values():
        for v in (svc or {}).get('volumes', []):
            if isinstance(v, str) and ':' in v:
                src_v = v.split(':')[0]
                if not src_v.startswith('/') and not src_v.startswith('.'):
                    used.add(src_v)
    pruned = {k: v for k, v in top_vols.items() if k in used}
    if pruned:
        doc['volumes'] = pruned
    else:
        doc.pop('volumes', None)

doc['networks'] = {'default': {'external': True, 'name': 'podium-cli_vpc'}}

with open(dst, 'w') as f:
    yaml.dump(doc, f, default_flow_style=False, allow_unicode=True, sort_keys=False)
print(json.dumps({'web_service': web_name, 'removed': list(replaced.keys()), 'podium_hosts': replaced}))
PYEOF
)
    if [ -f "docker-compose.yaml" ]; then
        _compose_file_created=1
        if [ -n "$ADAPT_SUMMARY" ]; then
            WEB_SVC=$(echo "$ADAPT_SUMMARY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('web_service','unknown'))" 2>/dev/null || echo "unknown")
            REMOVED=$(echo "$ADAPT_SUMMARY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(', '.join(d.get('removed',[])))" 2>/dev/null || echo "")
            echo-green "  Web-facing service: $WEB_SVC (IP: $IP_ADDRESS)"
            [ -n "$REMOVED" ] && echo-cyan "  Replaced with Podium shared services: $REMOVED"
        fi
        rm -f "$ORIGINAL_COMPOSE_TMPFILE"
        # Complex adapted projects skip auto-startup so the agent can verify/fix before starting
        NO_STARTUP=1
    else
        echo-yellow "Warning: docker-compose adaptation failed — falling back to Podium template"
        rm -f "$ORIGINAL_COMPOSE_TMPFILE"
        ORIGINAL_COMPOSE_IS_COMPLEX=0
    fi
fi

if [ "$ORIGINAL_COMPOSE_IS_COMPLEX" != "1" ]; then
    rm -f "$ORIGINAL_COMPOSE_TMPFILE" 2>/dev/null || true
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

    if [ -d "public" ] || [ "$FRAMEWORK_IS_PYTHON" = "1" ] || [ "$FRAMEWORK_IS_NODE" = "1" ]; then
        podium-sed "s/PUBLIC//g" docker-compose.yaml
    else
        podium-sed "s/PUBLIC/\/public/g" docker-compose.yaml
    fi

    if [ "$FRAMEWORK_IS_PYTHON" = "1" ]; then
        podium-sed "s|PYTHON_START_COMMAND|$(framework_python_start_command)|g" docker-compose.yaml
    elif [ "$FRAMEWORK_IS_NODE" = "1" ]; then
        podium-sed "s|NODE_START_COMMAND|$(framework_node_start_command)|g" docker-compose.yaml
    fi
fi

# Start the project container before composer installation
cd "$PROJECT_DIR"

echo-cyan "Current directory: $(pwd)"

if [ "$NO_STARTUP" = "1" ]; then
    echo-yellow "Container startup deferred — run 'podium up $PROJECT_NAME' after verifying docker-compose.yaml"
else
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
fi

if [ "$NO_STARTUP" != "1" ]; then
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

    case "$DATABASE_ENGINE" in
        postgres|postgresql|pgsql)
            # PostgreSQL has no IF NOT EXISTS on CREATE DATABASE; suppress "already exists" error
            json-postgres -d postgres -c "CREATE DATABASE \"$PROJECT_NAME_SNAKE\";" 2>/dev/null || true
            ;;
        mongo|mongodb)
            : # MongoDB creates databases on first write — nothing to do here
            ;;
        *)
            json-mysql -u"root" -e "CREATE DATABASE IF NOT EXISTS $PROJECT_NAME_SNAKE;"
            ;;
    esac

    echo-green 'Database created!'; echo-white

    framework_run_migrations

    echo-return; echo-return

    # Setup gitignore
    framework_setup_gitignore
fi

# Setup completed
if [[ "$JSON_OUTPUT" == "1" ]]; then
    # Build JSON response with optional fields
    JSON_RESPONSE="{\"action\": \"setup_project\", \"project_name\": \"$PROJECT_NAME\", \"database\": \"$DATABASE_ENGINE\", \"status\": \"success\", \"startup_deferred\": $([ "$NO_STARTUP" = "1" ] && echo "true" || echo "false")"

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
    if [ "$NO_STARTUP" = "1" ]; then
        echo-green "Docker-compose adapted for project: $PROJECT_NAME"
        echo-white "IP address: $IP_ADDRESS"
        echo-yellow "Container not started. Review docker-compose.yaml then run: podium up $PROJECT_NAME"
    else
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
fi

# Return to original directory
cd "$ORIG_DIR"
