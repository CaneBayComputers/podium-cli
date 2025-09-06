#!/bin/bash
# Podium Test Environment Cleanup Script
# This script cleans up all test resources created by the test suite

echo "🧹 Podium Test Environment Cleanup"
echo "=================================="

# Clean up test containers by pattern
echo "🐳 Cleaning up test containers..."
test_containers=$(docker ps -a --filter "name=podium_test_" --format "{{.Names}}")
if [ -n "$test_containers" ]; then
    echo "$test_containers" | while read container; do
        if [ -n "$container" ]; then
            echo "   🗑️  Removing container: $container"
            docker stop "$container" >/dev/null 2>&1 || true
            docker rm "$container" >/dev/null 2>&1 || true
        fi
    done
else
    echo "   ✅ No test containers found"
fi

# Clean up any test-related Docker images
echo "🖼️  Cleaning up test images..."
test_images=$(docker images --filter "reference=*podium_test_*" --format "{{.Repository}}:{{.Tag}}")
if [ -n "$test_images" ]; then
    echo "$test_images" | while read image; do
        if [ -n "$image" ]; then
            echo "   🗑️  Removing image: $image"
            docker rmi "$image" >/dev/null 2>&1 || true
        fi
    done
else
    echo "   ✅ No test images found"
fi

# Clean up any test-related Docker networks
echo "🌐 Cleaning up test networks..."
test_networks=$(docker network ls --filter "name=podium_test_" --format "{{.Name}}")
if [ -n "$test_networks" ]; then
    echo "$test_networks" | while read network; do
        if [ -n "$network" ]; then
            echo "   🗑️  Removing network: $network"
            docker network rm "$network" >/dev/null 2>&1 || true
        fi
    done
else
    echo "   ✅ No test networks found"
fi

# Clean up test project directories
echo "📁 Cleaning up test project directories..."
projects_cleaned=0
if [ -d "$HOME/podium-projects" ]; then
    for project_dir in "$HOME/podium-projects"/podium_test_*; do
        if [ -d "$project_dir" ]; then
            project_name=$(basename "$project_dir")
            echo "   🗑️  Removing project: $project_name"
            rm -rf "$project_dir"
            ((projects_cleaned++))
        fi
    done
fi

if [ $projects_cleaned -eq 0 ]; then
    echo "   ✅ No test project directories found"
else
    echo "   🗑️  Removed $projects_cleaned test project directories"
fi

# Clean up hosts entries
echo "🏠 Cleaning up hosts file..."
if grep -q "podium_test_" /etc/hosts 2>/dev/null; then
    echo "   🗑️  Removing all podium_test_ hosts entries"
    sudo sed -i "/podium_test_/d" /etc/hosts
    echo "   ✅ Hosts file cleaned"
else
    echo "   ✅ No test hosts entries found"
fi

# Clean up test logs
echo "📋 Cleaning up test logs..."
logs_cleaned=0
if [ -d "/home/shawn/repos/cbc/cbc-development/logs" ]; then
    for log_file in "/home/shawn/repos/cbc/cbc-development/logs"/podium_test_*.log; do
        if [ -f "$log_file" ]; then
            log_name=$(basename "$log_file")
            echo "   🗑️  Removing log: $log_name"
            rm -f "$log_file"
            ((logs_cleaned++))
        fi
    done
fi

if [ $logs_cleaned -eq 0 ]; then
    echo "   ✅ No test logs found"
else
    echo "   🗑️  Removed $logs_cleaned test log files"
fi

echo
echo "✅ Test environment cleanup complete!"
echo
echo "📊 Summary:"
echo "   🐳 Docker containers: cleaned"
echo "   🖼️  Docker images: cleaned"
echo "   🌐 Docker networks: cleaned"
echo "   📁 Project directories: $projects_cleaned removed"
echo "   🏠 Hosts file entries: cleaned"
echo "   📋 Log files: $logs_cleaned removed"
echo
echo "💡 Tip: You can run this script manually anytime with:"
echo "   ./src/scripts/cleanup_test_environment.sh"
