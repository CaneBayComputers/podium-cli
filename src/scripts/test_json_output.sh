#!/bin/bash

set -e

# Store current working directory (should be projects directory)
PROJECTS_DIR=$(pwd)

# Get script directory and set up paths
cd "$(dirname "$(realpath "$0")")"
cd ..
DEV_DIR=$(pwd)
source scripts/functions.sh

# Return to projects directory
cd "$PROJECTS_DIR"

# Test configuration
TEST_REPO="https://github.com/CaneBayComputers/cbc-laravel-website.git"
CLONE_PROJECT="cbc-website-test"

# Array to store test results
declare -a TEST_RESULTS=()

# Function to run a test and capture JSON output
run_json_test() {
    local test_name="$1"
    local command="$2"
    local description="$3"
    local should_fail="${4:-false}"
    
    # Prepend podium_test_ to test name for easy cleanup identification
    test_name="podium_test_${test_name}"
    
    # Prepend podium_test_ to any project names in the command for easy cleanup
    # Handle different command patterns:
    # - podium new project-name --options
    # - podium clone url project-name --options  
    # - podium setup project-name --options
    # - podium remove project-name --options
    command=$(echo "$command" | sed -E 's/(podium (new|setup|remove) )([a-zA-Z0-9_-]+)( --)/\1podium_test_\3\4/g')
    command=$(echo "$command" | sed -E 's/(podium clone [^ ]+ )([a-zA-Z0-9_-]+)( --)/\1podium_test_\2\3/g')
    
    echo "🧪 Running test: $test_name"
    echo "   Command: $command"
    
    # Set up custom debug log path for this test
    local test_log_path="$(dirname "$DEV_DIR")/logs/${test_name}.log"
    
    # Clear any previous debug session for clean test isolation
    unset DEBUG_STARTED
    
    # Execute command and capture output
    local output
    local exit_code
    
    if output=$(bash -c "export DEBUG_LOG_PATH='$test_log_path'; cd '$TEST_PROJECTS_DIR' && $command" 2>&1); then
        exit_code=0
    else
        exit_code=$?
    fi
    
    # CRITICAL: Capture debug log IMMEDIATELY after test completes, before anything else
    local debug_log_content=""
    if [[ -f "$test_log_path" ]]; then
        debug_log_content=$(tail -20 "$test_log_path" 2>/dev/null || echo "Debug log not readable")
        
        # Append JSON output to the test's debug log file
        if [[ -n "$output" ]]; then
            echo "" >> "$test_log_path"
            echo "=== JSON RESULT [$(date '+%Y-%m-%d %H:%M:%S')] ===" >> "$test_log_path"
            echo "$output" >> "$test_log_path"
            echo "=== END JSON RESULT ===" >> "$test_log_path"
        fi
    fi
    
    # Determine test result based on expectation
    local test_status
    if [[ "$should_fail" == "true" ]]; then
        # Test was expected to fail
        test_status=$([ $exit_code -ne 0 ] && echo "success" || echo "failed")
    else
        # Test was expected to succeed
        test_status=$([ $exit_code -eq 0 ] && echo "success" || echo "failed")
    fi
    
    # Add test evaluation to debug log
    if [[ -f "$test_log_path" ]]; then
        echo "" >> "$test_log_path"
        echo "=== TEST EVALUATION ===" >> "$test_log_path"
        echo "Expected: $([ "$should_fail" == "true" ] && echo "FAILURE (exit code != 0)" || echo "SUCCESS (exit code = 0)")" >> "$test_log_path"
        echo "Actual: $([ $exit_code -eq 0 ] && echo "SUCCESS (exit code = $exit_code)" || echo "FAILURE (exit code = $exit_code)")" >> "$test_log_path"
        echo "Test Result: $(echo "$test_status" | tr '[:lower:]' '[:upper:]')" >> "$test_log_path"
        echo "=== END TEST EVALUATION ===" >> "$test_log_path"
    fi
    
    # Store result with captured debug log
    local result_json="{\"test_name\": \"$test_name\", \"command\": \"$command\", \"description\": \"$description\", \"exit_code\": $exit_code, \"expected_failure\": $should_fail, \"output\": $(echo "$output" | jq -R -s .), \"debug_log\": $(echo "$debug_log_content" | jq -R -s .), \"status\": \"$test_status\"}"
    
    TEST_RESULTS+=("$result_json")
    
    # Show result
    if [[ "$test_status" == "success" ]]; then
        echo "   ✅ PASSED"
    else
        echo "   ❌ FAILED (exit code: $exit_code)"
        echo "   Output: $output"
        # Show the captured debug log (not re-read it)
        if [[ -n "$debug_log_content" ]]; then
            echo "   Debug log (last 20 lines from this test):"
            echo "$debug_log_content" | sed 's/^/      /'
        fi
    fi
    echo
}

# Function to setup test environment
setup_test_environment() {
    echo "🔧 Setting up test environment..."
    
    # Use the regular projects directory from .env
    export TEST_PROJECTS_DIR="$HOME/podium-projects"
    echo "   📁 Using projects directory: $TEST_PROJECTS_DIR"
    echo "   🏷️  Test isolation via 'podium_test_' prefix"
    
    echo "   ✅ Test environment ready"
}

# Function to cleanup test environment
cleanup_test_environment() {
    echo "🧹 Cleaning up test environment..."
    
    # Clean up test containers by pattern
    echo "   🧹 Cleaning up test containers..."
    docker ps -a --filter "name=podium_test_" --format "{{.Names}}" | while read container; do
        if [ -n "$container" ]; then
            echo "      🗑️  Removing container: $container"
            docker stop "$container" >/dev/null 2>&1 || true
            docker rm "$container" >/dev/null 2>&1 || true
        fi
    done
    
    # Clean up any test-related Docker images
    docker images --filter "reference=*podium_test_*" --format "{{.Repository}}:{{.Tag}}" | while read image; do
        if [ -n "$image" ]; then
            echo "      🗑️  Removing image: $image"
            docker rmi "$image" >/dev/null 2>&1 || true
        fi
    done
    
    # Clean up any test-related Docker networks
    docker network ls --filter "name=podium_test_" --format "{{.Name}}" | while read network; do
        if [ -n "$network" ]; then
            echo "      🌐 Removing network: $network"
            docker network rm "$network" >/dev/null 2>&1 || true
        fi
    done
    
    # Clean up test project directories
    echo "   📁 Cleaning up test project directories..."
    if [ -d "$TEST_PROJECTS_DIR" ]; then
        for project_dir in "$TEST_PROJECTS_DIR"/podium_test_*; do
            if [ -d "$project_dir" ]; then
                project_name=$(basename "$project_dir")
                echo "      🗑️  Removing project: $project_name"
                rm -rf "$project_dir"
            fi
        done
    fi
    
    echo "   ✅ Test environment cleanup complete"
}

# Function to create test scenarios
create_test_scenarios() {
    local projects_dir=$(get_projects_dir)
    
    # Create blank folder
    echo "📁 Creating blank folder scenario..."
    mkdir -p "$projects_dir/blank-folder-test"
    
    # Create non-Podium docker-compose project
    echo "🐳 Creating non-Podium docker-compose scenario..."
    mkdir -p "$projects_dir/non-podium-test"
    cat > "$projects_dir/non-podium-test/docker-compose.yaml" << 'EOF'
version: '3.8'
services:
  web:
    image: nginx:latest
    ports:
      - "8080:80"
# This is NOT a podium project - missing x-metadata
EOF
}

# Setup test environment and ensure cleanup on exit
setup_test_environment

# Trap to ensure cleanup on script exit/interruption
trap 'echo ""; echo "🛑 Test interrupted - cleaning up..."; cleanup_test_environment; exit 1' INT TERM

# Create test scenarios
create_test_scenarios

echo "🚀 Starting Podium CLI JSON Output Test Suite"
echo "============================================="

# Clean up old test logs
echo "🧹 Cleaning up old test logs..."
rm -f "$(dirname "$DEV_DIR")/logs/podium_test_"*.log 2>/dev/null || true
echo "   ✅ Old logs cleaned"
echo

# Test 1: Start Services
run_json_test "start_services" \
    "podium up --json-output --debug" \
    "Start all services and projects with JSON output"

# Test 2: Status Check (services)
run_json_test "status_services" \
    "podium status --json-output --debug" \
    "Check status of services with JSON output"

# Test 3: Clone Project
run_json_test "clone_project" \
    "podium clone '$TEST_REPO' '$CLONE_PROJECT' --json-output --debug" \
    "Clone CBC Laravel website repository with JSON output"

# Test 4: New Project - Laravel Latest
run_json_test "new_laravel_latest" \
    "podium new laravel-latest-test --framework laravel --version latest --json-output --debug" \
    "Create new Laravel project with latest version"

# Test 5: New Project - Laravel 11.x
run_json_test "new_laravel_11" \
    "podium new laravel-11-test --framework laravel --version 11.6.1 --json-output --debug" \
    "Create new Laravel project with specific version 11.6.1"

# Test 6: New Project - Laravel 10.x
run_json_test "new_laravel_10" \
    "podium new laravel-10-test --framework laravel --version 10.3.3 --json-output --debug" \
    "Create new Laravel project with older version 10.3.3"

# Test 7: New Project - WordPress
run_json_test "new_wordpress" \
    "podium new wordpress-test --framework wordpress --json-output --debug" \
    "Create new WordPress project"

# Test 8: New Project - PHP 8
run_json_test "new_php8" \
    "podium new php8-test --framework php --version 8 --json-output --debug" \
    "Create new PHP 8 project"

# Test 9: New Project - PHP 7
run_json_test "new_php7" \
    "podium new php7-test --framework php --version 7 --json-output --debug" \
    "Create new PHP 7 project"

# Test 10: New Project - Funky Name and Description
run_json_test "new_funky_name" \
    "podium new 'funky-name-test' --framework laravel --display-name 'My Super Awesome Project' --description 'This has special characters' --emoji '🦄' --json-output --debug" \
    "Create project with special characters in name and description"

# Test 11: Setup Blank Folder (should work)
run_json_test "setup_blank_folder" \
    "podium setup blank-folder-test --framework laravel --json-output --debug" \
    "Setup a blank folder as Laravel project"

# Test 12: Setup Non-Podium Docker Compose (should handle gracefully)
run_json_test "setup_non_podium" \
    "podium setup non-podium-test --framework laravel --overwrite-docker-compose --json-output --debug" \
    "Setup folder with non-Podium docker-compose.yaml"

# Test 13: Invalid Laravel Version (should fail)
run_json_test "invalid_laravel_version" \
    "podium new invalid-version-test --framework laravel --version 99.99.99 --json-output --debug" \
    "Try to create Laravel project with invalid version" \
    "true"

# Test 14: Invalid Framework (should fail)
run_json_test "invalid_framework" \
    "podium new invalid-framework-test --framework react --json-output --debug" \
    "Try to create project with invalid framework" \
    "true"

# Test 15: Duplicate Project Name (should fail)
run_json_test "duplicate_project_name" \
    "podium new laravel-latest-test --framework laravel --json-output --debug" \
    "Try to create project with duplicate name" \
    "true"

# Test 16: Status Check (all projects)
run_json_test "status_all_projects" \
    "podium status --json-output --debug" \
    "Check status of all projects"

# Test 17: Status Check (specific project)
run_json_test "status_specific_project" \
    "podium status laravel-latest-test --json-output --debug" \
    "Check status of specific project"

# Test 18: Configure (should work even if already configured)
run_json_test "configure" \
    "podium configure --json-output --debug" \
    "Run configure command with JSON output"

# Test 19: Stop Services
run_json_test "stop_services" \
    "podium down --json-output --debug" \
    "Stop all services and projects with JSON output"

# Test 20: Final Status Check (should show everything stopped)
run_json_test "final_status" \
    "podium status --json-output --debug" \
    "Final status check - everything should be stopped" \
    "true"

# Generate final test report
generate_test_report() {
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local total_tests=${#TEST_RESULTS[@]}
    local passed_tests=$(printf '%s\n' "${TEST_RESULTS[@]}" | grep -c '"status": "success"' || echo "0")
    local failed_tests=$((total_tests - passed_tests))
    
    # Build results array
    local results_json="["
    for i in "${!TEST_RESULTS[@]}"; do
        results_json+="${TEST_RESULTS[i]}"
        if [ $i -lt $((${#TEST_RESULTS[@]} - 1)) ]; then
            results_json+=","
        fi
    done
    results_json+="]"
    
    # Generate visual test report
    local success_rate=$(echo "scale=1; $passed_tests * 100 / $total_tests" | bc -l 2>/dev/null || echo "0.0")
    local status_emoji="$([ $failed_tests -eq 0 ] && echo "✅" || echo "❌")"
    local status_text="$([ $failed_tests -eq 0 ] && echo "ALL PASSED" || echo "SOME FAILED")"
    
    echo
    echo "📊 TEST SUITE RESULTS"
    echo "===================="
    echo "🏆 Status: $status_emoji $status_text"
    echo "📈 Success Rate: ${success_rate}% ($passed_tests/$total_tests)"
    echo "⏰ Completed: $timestamp"
    echo
    
    if [ $failed_tests -gt 0 ]; then
        echo "❌ FAILED TESTS:"
        echo "==============="
        for ((i=0; i<${#TEST_RESULTS[@]}; i++)); do
            local result="${TEST_RESULTS[i]}"
            local test_name=$(echo "$result" | jq -r '.test_name')
            local test_status=$(echo "$result" | jq -r '.status')
            local command=$(echo "$result" | jq -r '.command')
            local exit_code=$(echo "$result" | jq -r '.exit_code')
            
            if [ "$test_status" == "failed" ]; then
                echo "   🔴 $test_name"
                echo "      Command: $command"
                echo "      Exit Code: $exit_code"
                echo
            fi
        done
    fi
    
    echo "✅ PASSED TESTS:"
    echo "==============="
    for ((i=0; i<${#TEST_RESULTS[@]}; i++)); do
        local result="${TEST_RESULTS[i]}"
        local test_name=$(echo "$result" | jq -r '.test_name')
        local test_status=$(echo "$result" | jq -r '.status')
        local expected_failure=$(echo "$result" | jq -r '.expected_failure')
        local exit_code=$(echo "$result" | jq -r '.exit_code')
        
        if [ "$test_status" == "success" ]; then
            if [ "$expected_failure" == "true" ]; then
                echo "   🟢 $test_name (Expected failure: exit code $exit_code)"
            else
                echo "   🟢 $test_name"
            fi
        fi
    done
    echo
    
    echo "📋 DEBUG LOGS:"
    echo "============="
    echo "   Location: $(dirname "$DEV_DIR")/logs/"
    echo "   Pattern: podium_test_*.log"
    echo "   Use 'tail -f logs/podium_test_[test_name].log' to examine specific test logs"
}

echo "============================================="
echo "🏁 Test Suite Complete!"
echo

# Post-cleanup
cleanup_test_environment

# Output final test report
generate_test_report