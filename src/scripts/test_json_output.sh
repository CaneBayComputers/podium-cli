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
TEST_REPO="https://github.com/laravel/laravel.git"
TEST_PROJECT="test-json-project"

# Array to store test results
declare -a TEST_RESULTS=()

# Function to run a test and capture JSON output
run_json_test() {
    local test_name="$1"
    local command="$2"
    local description="$3"
    
    # Execute command and capture output
    local output
    local exit_code
    
    if output=$(eval "$command" 2>&1); then
        exit_code=0
    else
        exit_code=$?
    fi
    
    # Store result
    local result_json="{\"test_name\": \"$test_name\", \"command\": \"$command\", \"description\": \"$description\", \"exit_code\": $exit_code, \"output\": $(echo "$output" | jq -R -s .), \"status\": \"$([ $exit_code -eq 0 ] && echo "success" || echo "failed")\"}"
    
    TEST_RESULTS+=("$result_json")
}

# Function to cleanup test project
cleanup_test_project() {
    if [ -d "$(get_projects_dir)/$TEST_PROJECT" ]; then
        podium remove "$TEST_PROJECT" --force --json-output >/dev/null 2>&1 || true
    fi
    if [ -d "$(get_projects_dir)/test-new-json-project" ]; then
        podium remove test-new-json-project --force --json-output >/dev/null 2>&1 || true
    fi
}

# Pre-cleanup
cleanup_test_project

# Run pre-check (not JSON, just verify setup)
podium pre-check >/dev/null 2>&1

# Test 1: Start Services
run_json_test "start_services" \
    "podium start-services --json-output --no-colors" \
    "Start shared services with JSON output"

# Test 2: Status Check (services)
run_json_test "status_services" \
    "podium status --json-output --no-colors" \
    "Check status of services with JSON output"

# Test 3: Clone Project
run_json_test "clone_project" \
    "podium clone '$TEST_REPO' '$TEST_PROJECT' --json-output --no-colors" \
    "Clone repository with JSON output"

# Test 4: Status Check (with project)
run_json_test "status_with_project" \
    "podium status --json-output --no-colors" \
    "Check status with project present"

# Test 5: Start Project
run_json_test "start_project" \
    "podium start '$TEST_PROJECT' --json-output --no-colors" \
    "Start project container with JSON output"

# Test 6: Status Check (project running)
run_json_test "status_project_running" \
    "podium status --json-output --no-colors" \
    "Verify project running status"

# Test 7: Stop Project
run_json_test "stop_project" \
    "podium stop '$TEST_PROJECT' --json-output --no-colors" \
    "Stop project container with JSON output"

# Test 8: Status Check (project stopped)
run_json_test "status_project_stopped" \
    "podium status --json-output --no-colors" \
    "Verify project stopped status"

# Test 9: New Project Creation
run_json_test "new_project" \
    "podium new test-new-json-project laravel 'Test JSON Project' 'A test project for JSON output' '🧪' --json-output --no-colors" \
    "Create new project with JSON output"

# Test 10: Setup Project
run_json_test "setup_project" \
    "podium setup test-new-json-project --json-output --no-colors" \
    "Setup project with JSON output"

# Test 11: Remove First Project
run_json_test "remove_first_project" \
    "podium remove '$TEST_PROJECT' --force --json-output --no-colors" \
    "Remove cloned project with JSON output"

# Test 12: Remove Second Project
run_json_test "remove_second_project" \
    "podium remove test-new-json-project --force --json-output --no-colors" \
    "Remove new project with JSON output"

# Test 13: Stop Services
run_json_test "stop_services" \
    "podium stop-services --json-output --no-colors" \
    "Stop services with JSON output"

# Test 14: Final Status Check
run_json_test "final_status" \
    "podium status --json-output --no-colors" \
    "Final status check with JSON output"

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
  "test_suite": "podium_json_output",
  "timestamp": "$timestamp",
  "summary": {
    "total_tests": $total_tests,
    "passed": $passed_tests,
    "failed": $failed_tests,
    "success_rate": $(echo "scale=2; $passed_tests * 100 / $total_tests" | bc -l)
  },
  "test_configuration": {
    "test_repository": "$TEST_REPO",
    "test_project": "$TEST_PROJECT",
    "json_output": true,
    "no_colors": true
  },
  "results": $results_json,
  "status": "$([ $failed_tests -eq 0 ] && echo "all_passed" || echo "some_failed")"
}
EOF
}

# Output final test report
generate_test_report
