#!/bin/bash
# Docker Destroy Script
# Stops and removes all Docker containers, images, volumes, and docker-stack networks.
# WARNING: This will permanently delete all database data stored in Docker volumes!

# Source functions for colored output
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/functions.sh"

echo-red "⚠️  DANGER: Docker Destroy - This will remove ALL containers, images, volumes, and networks!"
echo-red "⚠️  WARNING: All database data in Docker volumes will be PERMANENTLY DELETED!"
echo-return

# Interactive confirmation
echo-yellow "This action will:"
echo-white "  • Stop and remove ALL Docker containers"
echo-white "  • Remove ALL Docker images"
echo-white "  • Remove ALL Docker volumes (including database data)"
echo-white "  • Remove ALL docker-stack networks"
echo-return

echo-yellow "Are you sure you want to continue? This cannot be undone!"
read -p "Type 'yes' to confirm: " confirm
echo-return

if [ "$confirm" != "yes" ]; then
    echo-white "Operation cancelled."
    exit 0
fi

echo-cyan "🧹 Proceeding with Docker destroy..."
echo-return

# Stop all running containers
echo-yellow "⏹️  Stopping all running containers..."
RUNNING_CONTAINERS=$(docker ps -aq)
if [ -n "$RUNNING_CONTAINERS" ]; then
    docker stop $RUNNING_CONTAINERS
    echo-green "   ✅ All containers stopped"
else
    echo-white "   No running containers to stop"
fi
echo-return

# Remove all containers
echo-yellow "🗑️  Removing all containers..."
ALL_CONTAINERS=$(docker ps -aq)
if [ -n "$ALL_CONTAINERS" ]; then
    docker rm $ALL_CONTAINERS
    echo-green "   ✅ All containers removed"
else
    echo-white "   No containers to remove"
fi
echo-return

# Remove all Docker images
echo-yellow "🖼️  Removing all Docker images..."
ALL_IMAGES=$(docker images -aq)
if [ -n "$ALL_IMAGES" ]; then
    docker rmi -f $ALL_IMAGES
    echo-green "   ✅ All images removed"
else
    echo-white "   No images to remove"
fi
echo-return

# Remove all Docker volumes
echo-yellow "💾 Removing all Docker volumes..."
ALL_VOLUMES=$(docker volume ls -q)
if [ -n "$ALL_VOLUMES" ]; then
    docker volume rm $ALL_VOLUMES
    echo-green "   ✅ All volumes removed"
else
    echo-white "   No volumes to remove"
fi
echo-return

# Remove docker-stack networks
echo-yellow "🌐 Removing docker-stack networks..."
DOCKER_STACK_NETWORKS=$(docker network ls --filter name=docker-stack_ --format "{{.Name}}")
if [ -n "$DOCKER_STACK_NETWORKS" ]; then
    for network in $DOCKER_STACK_NETWORKS; do
        docker network rm "$network"
    done
    echo-green "   ✅ Docker-stack networks removed"
else
    echo-white "   No docker-stack networks found"
fi
echo-return

# Run a final system prune to clean up any remaining build cache
echo-yellow "🔧 Running final system cleanup..."
docker system prune -f --volumes
echo-green "   ✅ System cleanup complete"
echo-return

echo-white "📊 Final Docker status:"
echo-white "   Containers: $(docker ps -aq | wc -l)"
echo-white "   Images: $(docker images -aq | wc -l)"
echo-white "   Volumes: $(docker volume ls -q | wc -l)"
echo-white "   Networks: $(docker network ls -q | wc -l)"
echo-return

echo-green "✅ Docker destroy complete! System is ready for fresh testing."
echo-return