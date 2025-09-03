#!/bin/bash

# Podium Uninstall Script
# Selectively removes Podium-related Docker resources

# Source functions for colored output
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/functions.sh"

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo-red "Docker is not running or not accessible"
    echo "Please start Docker and try again"
    exit 1
fi

echo-cyan "🧹 Podium Uninstall - Selective Docker Cleanup"
echo

# Load configuration to get STACK_ID
CONFIG_FILE=""
if [ -f "/etc/podium-cli/.env" ]; then
    CONFIG_FILE="/etc/podium-cli/.env"
elif [ -f "$SCRIPT_DIR/../docker-stack/.env" ]; then
    CONFIG_FILE="$SCRIPT_DIR/../docker-stack/.env"
fi

if [ -n "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    echo-white "Using STACK_ID: $STACK_ID"
else
    echo-yellow "Warning: No configuration found, will clean up any docker-stack_* resources"
fi

echo

# 1. Stop and remove containers first
echo-white "🛑 Stopping Podium containers..."

# Get all containers with podium labels or docker-stack names
CONTAINERS=$(docker ps -a --filter "name=mariadb" --filter "name=phpmyadmin" --filter "name=redis" --filter "name=memcached" --filter "name=mongo" --filter "name=postgres" --filter "name=mailhog" --filter "name=ollama" --format "{{.Names}}" 2>/dev/null || true)

if [ -n "$CONTAINERS" ]; then
    echo "Found containers: $CONTAINERS"
    echo "$CONTAINERS" | xargs -r docker stop 2>/dev/null || true
    echo "$CONTAINERS" | xargs -r docker rm 2>/dev/null || true
    echo-green "✅ Containers removed"
else
    echo "No Podium containers found"
fi

echo

# 2. Remove specific images by name
echo-white "🗑️ Removing Podium images..."

# List of images from docker-compose (strip :latest if present)
IMAGES=(
    "mariadb"
    "phpmyadmin" 
    "redis"
    "memcached"
    "mongo"
    "postgres"
    "mailhog/mailhog"
    "ollama/ollama"
)

REMOVED_IMAGES=0
for image in "${IMAGES[@]}"; do
    # Check if image exists (with or without :latest tag)
    if docker image inspect "$image" >/dev/null 2>&1 || docker image inspect "$image:latest" >/dev/null 2>&1; then
        echo "Removing image: $image"
        docker rmi "$image" 2>/dev/null || docker rmi "$image:latest" 2>/dev/null || true
        ((REMOVED_IMAGES++))
    fi
done

if [ $REMOVED_IMAGES -gt 0 ]; then
    echo-green "✅ Removed $REMOVED_IMAGES images"
else
    echo "No Podium images found to remove"
fi

echo

# 3. Remove volumes with docker-stack prefix
echo-white "📦 Removing Podium volumes..."

if [ -n "$STACK_ID" ]; then
    # Remove volumes with specific STACK_ID
    VOLUMES=$(docker volume ls --filter "name=${STACK_ID}_" --format "{{.Name}}" 2>/dev/null || true)
else
    # Remove any volumes starting with docker-stack_
    VOLUMES=$(docker volume ls --filter "name=docker-stack_" --format "{{.Name}}" 2>/dev/null || true)
fi

if [ -n "$VOLUMES" ]; then
    echo "Found volumes: $VOLUMES"
    echo "$VOLUMES" | xargs -r docker volume rm 2>/dev/null || true
    echo-green "✅ Volumes removed"
else
    echo "No Podium volumes found"
fi

echo

# 4. Remove networks with docker-stack prefix  
echo-white "🌐 Removing Podium networks..."

if [ -n "$STACK_ID" ]; then
    # Remove networks with specific STACK_ID
    NETWORKS=$(docker network ls --filter "name=${STACK_ID}_" --format "{{.Name}}" 2>/dev/null || true)
else
    # Remove any networks starting with docker-stack_
    NETWORKS=$(docker network ls --filter "name=docker-stack_" --format "{{.Name}}" 2>/dev/null || true)
fi

if [ -n "$NETWORKS" ]; then
    echo "Found networks: $NETWORKS"
    echo "$NETWORKS" | xargs -r docker network rm 2>/dev/null || true
    echo-green "✅ Networks removed"
else
    echo "No Podium networks found"
fi

echo

# 5. Clean up any orphaned resources
echo-white "🧽 Cleaning up orphaned resources..."
docker system prune -f >/dev/null 2>&1 || true
echo-green "✅ Orphaned resources cleaned"

echo
echo-green "🎉 Podium Docker resources have been selectively removed!"
echo
echo-white "What was removed:"
echo "  • Podium service containers (mariadb, phpmyadmin, redis, etc.)"
echo "  • Podium Docker images (mariadb, redis, postgres, etc.)"
if [ -n "$STACK_ID" ]; then
    echo "  • Volumes with prefix: ${STACK_ID}_*"
    echo "  • Networks with prefix: ${STACK_ID}_*"
else
    echo "  • Volumes with prefix: docker-stack_*"
    echo "  • Networks with prefix: docker-stack_*"
fi
echo
echo-white "What was preserved:"
echo "  • Your project files and code"
echo "  • Other Docker images and containers"
echo "  • Docker itself"
echo
echo-cyan "To reinstall Podium:"
echo "  podium config"
echo
