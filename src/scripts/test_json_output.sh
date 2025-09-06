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
    
    echo "🧪 Running test: $test_name"
    echo "   Command: $command"
    
    # Clear any previous debug session for clean test isolation
    unset DEBUG_STARTED
    
    # Execute command and capture output with timeout protection
    local output
    local exit_code
    
    # Use timeout to prevent hanging (5 minutes max per test)
    if output=$(timeout 300 bash -c "$command" 2>&1); then
        exit_code=0
    else
        exit_code=$?
        # Check if it was a timeout
        if [ $exit_code -eq 124 ]; then
            output="TEST TIMEOUT: Command exceeded 5 minute limit"
            echo "   ⏰ TIMEOUT after 5 minutes"
        fi
    fi
    
    # CRITICAL: Capture debug log IMMEDIATELY after test completes, before anything else
    local debug_log_content=""
    if [[ -f "/tmp/podium-cli-debug.log" ]]; then
        debug_log_content=$(tail -20 /tmp/podium-cli-debug.log 2>/dev/null || echo "Debug log not readable")
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

# Function to cleanup test projects
cleanup_test_projects() {
    local projects=(
        "$CLONE_PROJECT"
        "laravel-latest-test"
        "laravel-11-test"
        "laravel-10-test"
        "wordpress-test"
        "php8-test"
        "php7-test"
        "funky-name-test"
        "blank-folder-test"
        "non-podium-test"
    )
    
    for project in "${projects[@]}"; do
        if [ -d "$(get_projects_dir)/$project" ]; then
            echo "🧹 Cleaning up $project..."
            cd "$(get_projects_dir)" && podium remove "$project" --force --json-output --debug >/dev/null 2>&1 || true
        fi
    done
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

# Pre-cleanup
echo "🧹 Pre-test cleanup..."
cleanup_test_projects

# Create test scenarios
create_test_scenarios

echo "🚀 Starting Podium CLI JSON Output Test Suite"
echo "============================================="
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
    
    # Generate final report
    cat << EOF
{
  "test_suite": "podium_comprehensive_json_test",
  "timestamp": "$timestamp",
  "summary": {
    "total_tests": $total_tests,
    "passed": $passed_tests,
    "failed": $failed_tests,
    "success_rate": $(echo "scale=2; $passed_tests * 100 / $total_tests" | bc -l 2>/dev/null || echo "0")
  },
  "test_configuration": {
    "test_repository": "$TEST_REPO",
    "clone_project": "$CLONE_PROJECT",
    "json_output": true,
    "debug_enabled": true
  },
  "results": $results_json,
  "status": "$([ $failed_tests -eq 0 ] && echo "all_passed" || echo "some_failed")"
}
EOF
}

echo "============================================="
echo "🏁 Test Suite Complete!"
echo

# Post-cleanup
echo "🧹 Post-test cleanup..."
cleanup_test_projects

# Output final test report
generate_test_report