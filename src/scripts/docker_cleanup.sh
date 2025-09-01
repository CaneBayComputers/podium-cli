#!/bin/bash
set -e

# Docker cleanup script - removes all containers, images, volumes, and networks

echo "🧹 Docker Cleanup - Removing all containers, images, volumes, and networks..."
echo

# Stop all running containers
echo "⏹️  Stopping all running containers..."
if docker ps -q | wc -l | grep -q "^0$"; then
    echo "   No running containers to stop"
else
    docker stop $(docker ps -aq) 2>/dev/null && echo "   ✅ All containers stopped"
fi
echo

# Remove all containers
echo "🗑️  Removing all containers..."
if docker ps -aq | wc -l | grep -q "^0$"; then
    echo "   No containers to remove"
else
    docker rm $(docker ps -aq) 2>/dev/null && echo "   ✅ All containers removed"
fi
echo

# Remove all images
echo "🖼️  Removing all Docker images..."
if docker images -aq | wc -l | grep -q "^0$"; then
    echo "   No images to remove"
else
    docker rmi $(docker images -aq) 2>/dev/null && echo "   ✅ All images removed"
fi
echo

# Remove all volumes
echo "💾 Removing all Docker volumes..."
if docker volume ls -q | wc -l | grep -q "^0$"; then
    echo "   No volumes to remove"
else
    docker volume rm $(docker volume ls -q) 2>/dev/null && echo "   ✅ All volumes removed"
fi
echo

# Remove docker-stack networks
echo "🌐 Removing docker-stack networks..."
DOCKER_STACK_NETWORKS=$(docker network ls --format "{{.Name}}" | grep "docker-stack" || true)
if [ -z "$DOCKER_STACK_NETWORKS" ]; then
    echo "   No docker-stack networks to remove"
else
    echo "$DOCKER_STACK_NETWORKS" | xargs docker network rm 2>/dev/null && echo "   ✅ Docker-stack networks removed"
fi
echo

# Final system prune
echo "🔧 Running final system cleanup..."
RECLAIMED=$(docker system prune -a -f --volumes 2>&1 | grep "Total reclaimed space:" | cut -d: -f2 | xargs)
echo "   ✅ System cleanup complete - $RECLAIMED reclaimed"
echo

# Show final status
echo "📊 Final Docker status:"
echo "   Containers: $(docker ps -a --format "table {{.Names}}" | wc -l | awk '{print $1-1}')"
echo "   Images: $(docker images --format "table {{.Repository}}" | wc -l | awk '{print $1-1}')"
echo "   Volumes: $(docker volume ls --format "table {{.Name}}" | wc -l | awk '{print $1-1}')"
echo "   Networks: $(docker network ls --format "table {{.Name}}" | grep -v "bridge\|host\|none" | wc -l)"
echo

echo "✅ Docker cleanup complete! System is ready for fresh testing."
