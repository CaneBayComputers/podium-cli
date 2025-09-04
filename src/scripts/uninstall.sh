#!/bin/bash

# Podium Uninstall Script
# Selectively removes Podium-related Docker resources

# Source functions for colored output
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/functions.sh"

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    error "Docker is not running or not accessible. Please start Docker and try again"
fi

echo-cyan "🧹 Podium Uninstall - Selective Docker Cleanup"
echo-return

# Load configuration to find compose file
COMPOSE_FILE=""
if [ -f "/etc/podium-cli/docker-compose.yaml" ]; then
    COMPOSE_FILE="/etc/podium-cli/docker-compose.yaml"
    echo-white "Using compose file: $COMPOSE_FILE"
elif [ -f "$SCRIPT_DIR/../docker-stack/docker-compose.services.yaml" ]; then
    COMPOSE_FILE="$SCRIPT_DIR/../docker-stack/docker-compose.services.yaml"
    echo-white "Using compose file: $COMPOSE_FILE"
else
    echo-yellow "Warning: No docker-compose.yaml found, will clean up any podium-cli* resources"
fi

echo-return

# 1. Stop and remove containers first
echo-white "🛑 Stopping Podium containers..."

# Get container names from docker-compose file
CONTAINERS=""
if [ -f "$COMPOSE_FILE" ]; then
    CONTAINERS=$(grep -E "^\s*container_name:" "$COMPOSE_FILE" | sed 's/.*container_name:\s*\([^[:space:]]*\).*/\1/' | tr '\n' ' ')
fi

if [ -n "$CONTAINERS" ]; then
    echo "Found containers from compose: $CONTAINERS"
    for container in $CONTAINERS; do
        if docker ps -a --format "{{.Names}}" | grep -q "^${container}$"; then
            echo "  Stopping and removing: $container"
            docker stop "$container" 2>/dev/null || true
            docker rm "$container" 2>/dev/null || true
        else
            echo "  Container not found in Docker: $container"
        fi
    done
    echo-green "✅ Containers processed"
else
    echo "No containers found in compose file"
    echo "Searching for Podium containers by name pattern..."
    
    # Fallback: find containers by common Podium names
    FALLBACK_CONTAINERS=$(docker ps -a --format "{{.Names}}" | grep -E "(mariadb|redis|postgres|mongo|memcached|phpmyadmin|mailhog|ollama)" 2>/dev/null || true)
    
    if [ -n "$FALLBACK_CONTAINERS" ]; then
        echo "Found containers by pattern: $FALLBACK_CONTAINERS"
        for container in $FALLBACK_CONTAINERS; do
            echo "  Stopping and removing: $container"
            docker stop "$container" 2>/dev/null || true
            docker rm "$container" 2>/dev/null || true
        done
        echo-green "✅ Fallback containers processed"
    else
        echo "  No Podium containers found"
    fi
fi

echo-return

# 2. Remove specific images by name
echo-white "🗑️ Removing Podium images..."

# Get image names from docker-compose file
IMAGES=""
if [ -f "$COMPOSE_FILE" ]; then
    IMAGES=$(grep -E "^\s*image:" "$COMPOSE_FILE" | sed 's/.*image:\s*\([^[:space:]]*\).*/\1/' | sort | uniq)
fi

REMOVED_IMAGES=0
if [ -n "$IMAGES" ]; then
    for image in $IMAGES; do
        # Check if image exists (with or without :latest tag)
        if docker image inspect "$image" >/dev/null 2>&1 || docker image inspect "$image:latest" >/dev/null 2>&1; then
            echo "Removing image: $image"
            docker rmi "$image" 2>/dev/null || docker rmi "$image:latest" 2>/dev/null || true
            ((REMOVED_IMAGES++))
        fi
    done
fi

if [ $REMOVED_IMAGES -gt 0 ]; then
    echo-green "✅ Removed $REMOVED_IMAGES images"
else
    echo "No Podium images found to remove"
fi

echo-return

# 3. Remove volumes and networks with docker-stack prefix
echo-white "📦 Removing Podium volumes..."

# Always use podium-cli prefix to catch all Podium resources
VOLUME_PATTERN="podium-cli"
NETWORK_PATTERN="podium-cli"

# Remove volumes
VOLUMES=$(docker volume ls --filter "name=${VOLUME_PATTERN}" --format "{{.Name}}" 2>/dev/null || true)
if [ -n "$VOLUMES" ]; then
    echo "Found volumes: $VOLUMES"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # Mac: xargs doesn't have -r flag, use different approach
        echo "$VOLUMES" | tr ' ' '\n' | while read -r volume; do
            [ -n "$volume" ] && docker volume rm "$volume" 2>/dev/null || true
        done
    else
        # Linux: use xargs -r
        echo "$VOLUMES" | xargs -r docker volume rm 2>/dev/null || true
    fi
    echo-green "✅ Volumes removed"
else
    echo "No Podium volumes found"
fi

echo-return

# 4. Remove networks
echo-white "🌐 Removing Podium networks..."

NETWORKS=$(docker network ls --filter "name=${NETWORK_PATTERN}" --format "{{.Name}}" 2>/dev/null || true)
if [ -n "$NETWORKS" ]; then
    echo "Found networks: $NETWORKS"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # Mac: xargs doesn't have -r flag, use different approach
        echo "$NETWORKS" | tr ' ' '\n' | while read -r network; do
            [ -n "$network" ] && docker network rm "$network" 2>/dev/null || true
        done
    else
        # Linux: use xargs -r
        echo "$NETWORKS" | xargs -r docker network rm 2>/dev/null || true
    fi
    echo-green "✅ Networks removed"
else
    echo "No Podium networks found"
fi

echo-return

# 5. Remove hosts file entries
echo-white "📝 Removing hosts file entries..."

HOSTS_FILE="/etc/hosts"
REMOVED_HOSTS=0

if [ -f "$COMPOSE_FILE" ] && [ -f "$HOSTS_FILE" ]; then
    # Get container names from docker-compose file
    CONTAINER_NAMES=$(grep -E "^\s*container_name:" "$COMPOSE_FILE" | sed 's/.*container_name:[[:space:]]*\([^[:space:]]*\).*/\1/' | tr '\n' ' ')
    
    if [ -n "$CONTAINER_NAMES" ]; then
        for container_name in $CONTAINER_NAMES; do
            # Check if container name exists in hosts file (more flexible matching)
            if grep -q "${container_name}" "$HOSTS_FILE"; then
                echo "Removing hosts entry: $container_name"
                # Remove the line containing the container name
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    # macOS: BSD sed requires backup extension
                    sudo sed -i '' "/${container_name}/d" "$HOSTS_FILE"
                else
                    # Linux: GNU sed
                    sudo sed -i "/${container_name}/d" "$HOSTS_FILE"
                fi
                ((REMOVED_HOSTS++))
            fi
        done
    fi
fi

if [ $REMOVED_HOSTS -gt 0 ]; then
    echo-green "✅ Removed $REMOVED_HOSTS hosts file entries"
else
    echo "No Podium hosts entries found"
fi

echo-return

# 6. Clean up any orphaned resources
echo-white "🧽 Cleaning up orphaned resources..."
docker system prune -f >/dev/null 2>&1 || true
echo-green "✅ Orphaned resources cleaned"

echo-return
echo-green "🎉 Podium Docker resources have been selectively removed!"
echo-return
echo-white "What was removed:"
echo "  • Podium service containers (mariadb, phpmyadmin, redis, etc.)"
echo "  • Podium Docker images (mariadb, redis, postgres, etc.)"
echo "  • Hosts file entries for Podium services"
echo "  • Volumes with prefix: podium-cli_*"
echo "  • Networks with prefix: podium-cli_*"
echo-return
echo-white "What was preserved:"
echo "  • Your project files and code"
echo "  • Other Docker images and containers"
echo "  • Docker itself"
echo-return
echo-cyan "To reinstall Podium:"
echo "  podium config"
echo-return
