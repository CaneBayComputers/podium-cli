#!/bin/bash

set -e

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

source scripts/pre_check.sh

# Function to display usage
usage() {
    echo-white "Usage: $0 [project_name] [options]"
    echo-white "Shows status of running Docker projects"
    echo-white ""
    echo-white "Arguments:"
    echo-white "  project_name     Name of specific project to check (optional)"
    echo-white ""
    echo-white "Options:"
    echo-white "  --json-output    Output JSON responses (for programmatic use)"
    echo-white "  --debug          Enable debug logging to /tmp/podium-cli-debug.log"
    echo-white "  --no-colors      Disable colored output"
    echo-white "  --help           Show this help message"
    echo-white ""
    echo-white "Examples:"
    echo-white "  $0                    # Show all projects"
    echo-white "  $0 my-project         # Show specific project"
    echo-white "  $0 --json-output      # JSON output for all projects"
    
    error "usage" 1
}

# Initialize variables
PROJECT_NAME=""
JSON_OUTPUT="${JSON_OUTPUT:-}"
NO_COLOR="${NO_COLOR:-}"

# Capture original arguments for debug logging
ORIGINAL_ARGS="$*"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --json-output)
            JSON_OUTPUT=1
            shift
            ;;
        --debug)
            DEBUG=1
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
            error "Unknown option: $1"
            ;;
        *)
            if [ -z "$PROJECT_NAME" ]; then
                PROJECT_NAME="$1"
            else
                error "Too many arguments"
            fi
            shift
            ;;
    esac
done

# Initialize debug logging
debug "Script started: status.sh with args: $ORIGINAL_ARGS"

RUNNING_SITES=""

RUNNING_INTERNAL=""

RUNNING_EXTERNAL=""

# Get LAN IP (cross-platform)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS - use route to find default interface IP
    LAN_IP=$(route get default | grep interface | awk '{print $2}' | xargs ifconfig | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | head -1)
else
    # Linux - use hostname -I
    LAN_IP=$(hostname -I | awk '{print $1}')
fi

# Docker handles port mapping automatically

HOSTS=$(cat /etc/hosts)


# Functions
# Parse docker-compose.yaml to get all services dynamically
parse_docker_compose_services() {
    local compose_file="$1"
    local vpc_subnet="$2"
    local services_json="{}"
    
    # Get list of running containers once for performance
    local running_containers=$(docker ps --format "{{.Names}}")
    
    if [ ! -f "$compose_file" ]; then
        echo "$services_json"
        return
    fi
    
    # Extract all service definitions using simple grep/awk
    # Look for lines that define services (2+ spaces, name, colon) but only in the services section
    local service_names=$(awk '
        /^services:/ { in_services=1; next }
        /^[a-zA-Z]/ && !/^services:/ { in_services=0 }
        in_services && /^  [a-zA-Z0-9_-]+:/ { 
            gsub(/^  /, ""); 
            gsub(/:.*/, ""); 
            print 
        }
    ' "$compose_file")
    
    # Process each service
    while IFS= read -r service_name; do
        [ -z "$service_name" ] && continue
        
        # Extract details for this service using simple grep with line numbers
        local service_start=$(grep -n "^  $service_name:" "$compose_file" | cut -d: -f1)
        local next_service=$(grep -n "^  [a-zA-Z0-9_-]*:" "$compose_file" | awk -F: -v start="$service_start" '$1 > start {print $1; exit}')
        
        # If no next service found, use end of file
        if [ -z "$next_service" ]; then
            next_service=$(wc -l < "$compose_file")
        fi
        
        # Extract the service section
        local service_section=$(sed -n "${service_start},${next_service}p" "$compose_file")
        
        local container_name=$(echo "$service_section" | grep -E "^\s+container_name:" | head -1 | sed 's/.*container_name: *\(.*\)/\1/')
        local image_name=$(echo "$service_section" | grep -E "^\s+image:" | head -1 | sed 's/.*image: *\(.*\)/\1/')
        local ip_suffix=$(echo "$service_section" | grep -E "^\s+ipv4_address:" | head -1 | sed 's/.*\${VPC_SUBNET}\.\([0-9]*\).*/\1/')
        local port=$(echo "$service_section" | grep -A 5 "expose:" | grep -E "^\s+- " | head -1 | grep -o '[0-9]\+' | head -1)
        
        # Use container_name if available, otherwise use service name
        local final_container_name="${container_name:-$service_name}"
        local display_name="${container_name:-$service_name}"
        local ip_address=""
        
        # Build IP address if we have both VPC_SUBNET and suffix
        if [ -n "$vpc_subnet" ] && [ -n "$ip_suffix" ]; then
            ip_address="${vpc_subnet}.${ip_suffix}"
        fi
        
        # Check if container is running
        local status="stopped"
        if echo "$running_containers" | grep -q "^${final_container_name}$"; then
            status="running"
        fi
        
        # Add to JSON
        services_json=$(echo "$services_json" | jq --arg key "$final_container_name" \
            --arg name "$display_name" \
            --arg status "$status" \
            --arg ip "$ip_address" \
            --arg port "$port" \
            '.[$key] = {name: $name, status: $status, ip_address: $ip, port: $port}')
            
    done <<< "$service_names"
    
    echo "$services_json"
}

get_project_status() {
    local proj_name="$1"
    local project_data="{}"
    
    # Project folder check
    if [ -d "$proj_name" ]; then
        project_data=$(echo "$project_data" | jq --arg name "$proj_name" '. + {name: $name, folder_exists: true}')
        
        # Parse metadata from docker-compose.yaml if it exists
        local compose_file="$proj_name/docker-compose.yaml"
        if [ -f "$compose_file" ]; then
            # Extract metadata using grep and sed
            local emoji=$(grep -A 4 "x-metadata:" "$compose_file" | grep "emoji:" | sed 's/.*emoji: *"\(.*\)".*/\1/' 2>/dev/null || echo "🚀")
            local display_name=$(grep -A 4 "x-metadata:" "$compose_file" | grep "name:" | sed 's/.*name: *"\(.*\)".*/\1/' 2>/dev/null || echo "$proj_name")
            local description=$(grep -A 4 "x-metadata:" "$compose_file" | grep "description:" | sed 's/.*description: *"\(.*\)".*/\1/' 2>/dev/null || echo "")
            
            # Add metadata to project data
            project_data=$(echo "$project_data" | jq --arg emoji "$emoji" --arg display_name "$display_name" --arg description "$description" '. + {emoji: $emoji, display_name: $display_name, description: $description}')
        else
            # No compose file, use project name as display name
            project_data=$(echo "$project_data" | jq --arg emoji "🚀" --arg display_name "$proj_name" '. + {emoji: $emoji, display_name: $display_name, description: ""}')
        fi
    else
        project_data=$(echo "$project_data" | jq --arg name "$proj_name" --arg emoji "🚀" '. + {name: $name, folder_exists: false, emoji: $emoji, display_name: $name, description: ""}')
    fi
    
    # Host entry check
    if HOST_ENTRY=$(printf "%s\n" "$HOSTS" | grep " $proj_name$"); then
        EXT_PORT=$(echo $HOST_ENTRY | cut -d'.' -f 4 | cut -d' ' -f 1)
        project_data=$(echo "$project_data" | jq --arg port "$EXT_PORT" '. + {host_entry: true, external_port: $port}')
    else
        project_data=$(echo "$project_data" | jq '. + {host_entry: false, external_port: null}')
    fi
    
    # Docker status check
    if [ "$(docker ps -q -f name=$proj_name)" ]; then
        project_data=$(echo "$project_data" | jq '. + {docker_running: true}')
        
        # Port mapping check (only if running)
        if docker port "$proj_name" 80/tcp > /dev/null 2>&1; then
            project_data=$(echo "$project_data" | jq '. + {port_mapped: true}')
        else
            project_data=$(echo "$project_data" | jq '. + {port_mapped: false}')
        fi
    else
        project_data=$(echo "$project_data" | jq '. + {docker_running: false, port_mapped: false}')
    fi
    
    # URLs
    if [ -n "$HOST_ENTRY" ]; then
        project_data=$(echo "$project_data" | jq --arg local "http://$proj_name" --arg lan "http://$LAN_IP:$EXT_PORT" '. + {local_url: $local, lan_url: $lan}')
    else
        project_data=$(echo "$project_data" | jq '. + {local_url: null, lan_url: null}')
    fi
    
    echo "$project_data"
}

project_status() {
  PROJ_NAME=$1

  if [[ "$JSON_OUTPUT" == "1" ]]; then
    # JSON output is handled in main section
    return 0
  fi

  echo -n PROJECT:
  echo-yellow " $PROJ_NAME"

  echo-white -n PROJECT FOLDER:
  if ! [ -d "$PROJ_NAME" ]; then
    echo-red " NOT FOUND"
    echo-white -n SUGGESTION:; echo-yellow " Check spelling or clone repo"
    return 1
  else
    echo-green " FOUND"
  fi

  echo-white -n HOST ENTRY: 
  if ! HOST_ENTRY=$(printf "%s\n" "$HOSTS" | grep " $PROJ_NAME$"); then
    echo-red " NOT FOUND"
    echo-white -n SUGGESTION:; echo-yellow " cd \$(podium projects-dir)/$PROJ_NAME && podium setup $PROJ_NAME"
    return 1
  else
    echo-green " FOUND"
  fi

  echo-white -n DOCKER STATUS:
  if ! [ "$(docker ps -q -f name=$PROJ_NAME)" ]; then
    echo-red " NOT RUNNING"
    echo-white -n SUGGESTION:; echo-yellow " cd \$(podium projects-dir)/$PROJ_NAME && podium up"
    return 1
  else
    echo-green " RUNNING"
  fi

  echo-white -n DOCKER PORT MAPPING:
  EXT_PORT=$(echo $HOST_ENTRY | cut -d'.' -f 4 | cut -d' ' -f 1)
  # Check if Docker container has port mapping
  if ! docker port "$PROJ_NAME" 80/tcp > /dev/null 2>&1; then
    echo-red " NOT MAPPED"
    echo-white -n SUGGESTION:; echo-yellow " cd \$(podium projects-dir)/$PROJ_NAME && podium down && podium up"
    return 1
  else
    echo-green " MAPPED"
  fi

  # Platform-specific URL display
  echo-white -n LOCAL ACCESS:
  if [[ -n "$WSL_DISTRO_NAME" ]] || [[ "$OS" == "Windows_NT" ]] || [[ -f /proc/version ]] && grep -qi microsoft /proc/version; then
    # Windows/WSL: Show IP address
    PROJ_IP=$(echo $HOST_ENTRY | cut -d' ' -f 1)
    echo-yellow " http://$PROJ_IP"
  else
    # Linux/Mac: Show project name
    echo-yellow " http://$PROJ_NAME"
  fi
  echo-white -n LAN ACCESS:; echo-yellow " http://$LAN_IP:$EXT_PORT"
}


# Main

# Do not run as root
if [[ "$(whoami)" == "root" ]]; then

  error "Do NOT run with sudo!"

fi


# Check if this environment is installed
if ! [ -f /etc/podium-cli/.env ]; then
    error "Development environment has not been configured! Run: podium configure"
fi

if ! [ -f /etc/podium-cli/docker-compose.yaml ]; then
    error "Development environment has not been configured! Run: podium configure"
fi

# Check if services are running
if ! check-mariadb; then
    error "Development environment is not started! Run: podium start-services"
fi


# Handle JSON output - ALWAYS return JSON when requested, regardless of service state
if [[ "$JSON_OUTPUT" == "1" ]]; then
    # Get VPC subnet from .env file
    VPC_SUBNET=""
    if [ -f "/etc/podium-cli/.env" ]; then
        VPC_SUBNET=$(grep "^VPC_SUBNET=" /etc/podium-cli/.env | cut -d'=' -f2)
    fi
    
    # Initialize JSON structure
    JSON_DATA='{"shared_services": {}, "projects": []}'
    
    # Parse docker-compose.yaml to get all services dynamically
    COMPOSE_FILE="/etc/podium-cli/docker-compose.yaml"
    if [ ! -f "$COMPOSE_FILE" ]; then
        # Try fallback location
        COMPOSE_FILE="$DEV_DIR/docker-stack/docker-compose.services.yaml"
    fi
    
    if [ -f "$COMPOSE_FILE" ]; then
        SERVICES_JSON=$(parse_docker_compose_services "$COMPOSE_FILE" "$VPC_SUBNET")
        JSON_DATA=$(echo "$JSON_DATA" | jq --argjson services "$SERVICES_JSON" '.shared_services = $services')
    fi
    
    # Use projects directory from pre_check
    if [ -d "$PROJECTS_DIR_PATH" ]; then
        cd "$PROJECTS_DIR_PATH"
        
        if ! [ -z "$PROJECT_NAME" ]; then
            # Single project requested
            if [ -d "$PROJECT_NAME" ]; then
                PROJECT_JSON=$(get_project_status "$PROJECT_NAME")
                JSON_DATA=$(echo "$JSON_DATA" | jq --argjson project "$PROJECT_JSON" '.projects += [$project]')
            fi
        else
            # All projects
            for item in *; do
                if [ -d "$item" ] && [ "$item" != "." ] && [ "$item" != ".." ]; then
                    PROJECT_JSON=$(get_project_status "$item")
                    JSON_DATA=$(echo "$JSON_DATA" | jq --argjson project "$PROJECT_JSON" '.projects += [$project]')
                fi
            done
        fi
    fi
    
    echo "$JSON_DATA"
    
    # Use return if sourced, exit if called directly
    if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
        return 0
    else
        exit 0
    fi
fi

# Traditional text output
echo-cyan "SHARED SERVICES STATUS:"
echo-return

# Check MariaDB
echo-white -n "MariaDB: "
if docker ps --format "table {{.Names}}" | grep -q "mariadb"; then
    echo-green "RUNNING"
else
    echo-red "STOPPED"
fi

# Check phpMyAdmin
echo-white -n "phpMyAdmin: "
if docker ps --format "table {{.Names}}" | grep -q "phpmyadmin"; then
    echo-green "RUNNING"
else
    echo-red "STOPPED"
fi

# Check Redis
echo-white -n "Redis: "
if docker ps --format "table {{.Names}}" | grep -q "redis"; then
    echo-green "RUNNING"
else
    echo-red "STOPPED"
fi

# Check Memcached
echo-white -n "Memcached: "
if docker ps --format "table {{.Names}}" | grep -q "memcached"; then
    echo-green "RUNNING"
else
    echo-red "STOPPED"
fi

# Check PostgreSQL
echo-white -n "PostgreSQL: "
if docker ps --format "table {{.Names}}" | grep -q "postgres"; then
    echo-green "RUNNING"
else
    echo-red "STOPPED"
fi

# Check MongoDB
echo-white -n "MongoDB: "
if docker ps --format "table {{.Names}}" | grep -q "mongo"; then
    echo-green "RUNNING"
else
    echo-red "STOPPED"
fi

# Check MailHog
echo-white -n "MailHog: "
if docker ps --format "table {{.Names}}" | grep -q "mailhog"; then
    echo-green "RUNNING"
else
    echo-red "STOPPED"
fi

# Check Ollama
echo-white -n "Ollama: "
if docker ps --format "table {{.Names}}" | grep -q "ollama"; then
    echo-green "RUNNING"
else
    echo-red "STOPPED"
fi

divider

# Iterate through projects folder (from pre_check)
cd "$PROJECTS_DIR_PATH"

if ! [ -z "$PROJECT_NAME" ]; then
    if project_status $PROJECT_NAME; then true; fi
    divider
else
    # Check if there are any actual project directories (not just files)
    PROJECT_COUNT=0
    for item in *; do
        if [ -d "$item" ] && [ "$item" != "." ] && [ "$item" != ".." ]; then
            PROJECT_COUNT=$((PROJECT_COUNT + 1))
        fi
    done
    
    if [ $PROJECT_COUNT -eq 0 ]; then
        echo-cyan "PROJECTS STATUS:"
        echo-return
        echo-yellow "No projects found in $(pwd)"
        echo-white "Create your first project with: podium new"
        divider
    else
        echo-cyan "PROJECTS STATUS:"
        echo-return
        for PROJECT_NAME in *; do
            if [ -d "$PROJECT_NAME" ] && [ "$PROJECT_NAME" != "." ] && [ "$PROJECT_NAME" != ".." ]; then
                if project_status $PROJECT_NAME; then true; fi
                divider
            fi
        done
    fi
fi