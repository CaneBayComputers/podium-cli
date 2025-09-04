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
TEST_PROJECT="test-interactive-project"

# Colors for test output
TEST_CYAN='\033[96m'
TEST_GREEN='\033[92m'
TEST_YELLOW='\033[93m'
TEST_RED='\033[91m'
TEST_RESET='\033[0m'

# Function to wait for user input
wait_for_user() {
echo-return
    echo -e "${TEST_YELLOW}Press ENTER to continue...${TEST_RESET}"
    read -r
}

# Function to run a test step
run_test_step() {
    local test_name="$1"
    local command="$2"
    local description="$3"
    
echo-return
    echo -e "${TEST_CYAN}========================================${TEST_RESET}"
    echo -e "${TEST_CYAN}TEST: $test_name${TEST_RESET}"
    echo -e "${TEST_CYAN}========================================${TEST_RESET}"
echo-return
    echo -e "${TEST_GREEN}Description:${TEST_RESET} $description"
echo-return
    echo -e "${TEST_GREEN}Command to run:${TEST_RESET} $command"
echo-return
    
    wait_for_user
    
    echo -e "${TEST_YELLOW}Running: $command${TEST_RESET}"
echo-return
    
    # Execute the command
    eval "$command"
    local exit_code=$?
    
echo-return
    if [ $exit_code -eq 0 ]; then
        echo -e "${TEST_GREEN}✓ Test '$test_name' completed successfully${TEST_RESET}"
    else
        echo -e "${TEST_RED}✗ Test '$test_name' failed with exit code $exit_code${TEST_RESET}"
    fi
    
    wait_for_user
}

# Function to cleanup test project
cleanup_test_project() {
echo-return
    echo -e "${TEST_CYAN}========================================${TEST_RESET}"
    echo -e "${TEST_CYAN}CLEANUP${TEST_RESET}"
    echo -e "${TEST_CYAN}========================================${TEST_RESET}"
echo-return
    echo -e "${TEST_YELLOW}Cleaning up test project: $TEST_PROJECT${TEST_RESET}"
echo-return
    
    if [ -d "$(get_projects_dir)/$TEST_PROJECT" ]; then
        echo "Removing test project..."
        podium remove "$TEST_PROJECT" --force
    else
        echo "Test project directory not found, skipping removal."
    fi
    
    echo -e "${TEST_GREEN}✓ Cleanup completed${TEST_RESET}"
}

# Main test execution
echo -e "${TEST_CYAN}========================================${TEST_RESET}"
echo -e "${TEST_CYAN}PODIUM INTERACTIVE TEST SUITE${TEST_RESET}"
echo -e "${TEST_CYAN}========================================${TEST_RESET}"
echo-return
echo -e "${TEST_GREEN}This test suite will run through all major Podium commands${TEST_RESET}"
echo -e "${TEST_GREEN}in interactive mode (no --json-output).${TEST_RESET}"
echo-return
echo -e "${TEST_YELLOW}Test Project: $TEST_PROJECT${TEST_RESET}"
echo -e "${TEST_YELLOW}Test Repository: $TEST_REPO${TEST_RESET}"
echo-return
echo -e "${TEST_RED}Note: This will create and remove a test project.${TEST_RESET}"

wait_for_user

# Pre-check
echo-return
echo -e "${TEST_CYAN}Running pre-check to ensure Podium is configured...${TEST_RESET}"
echo-return
podium pre-check

# Test 1: Start Services
run_test_step "Start Services" \
    "podium start-services" \
    "Start shared services (MariaDB, Redis, phpMyAdmin, MailHog, Ollama)"

# Test 2: Status Check (services)
run_test_step "Status Check (Services)" \
    "podium status" \
    "Check status of services and projects"

# Test 3: Clone Project
run_test_step "Clone Project" \
    "podium clone '$TEST_REPO' '$TEST_PROJECT'" \
    "Clone Laravel repository and set up as Podium project"

# Test 4: Status Check (with project)
run_test_step "Status Check (With Project)" \
    "podium status" \
    "Check status of services and the new project"

# Test 5: Start Project
run_test_step "Start Project" \
    "podium start '$TEST_PROJECT'" \
    "Start the test project container"

# Test 6: Status Check (project running)
run_test_step "Status Check (Project Running)" \
    "podium status" \
    "Verify project is running"

# Test 7: Stop Project  
run_test_step "Stop Project" \
    "podium stop '$TEST_PROJECT'" \
    "Stop the test project container"

# Test 8: Status Check (project stopped)
run_test_step "Status Check (Project Stopped)" \
    "podium status" \
    "Verify project is stopped"

# Test 9: New Project (alternative method)
run_test_step "New Project Creation" \
    "podium new test-new-project laravel 'Test New Project' 'A test project created with new command' '🧪'" \
    "Create a new Laravel project using the new command"

# Test 10: Setup Project (on existing)
run_test_step "Setup Project" \
    "podium setup test-new-project" \
    "Run setup on the newly created project"

# Test 11: Remove First Project
run_test_step "Remove First Project" \
    "podium remove '$TEST_PROJECT' --force" \
    "Remove the cloned test project"

# Test 12: Remove Second Project  
run_test_step "Remove Second Project" \
    "podium remove test-new-project --force" \
    "Remove the new test project"

# Test 13: Stop Services
run_test_step "Stop Services" \
    "podium stop-services" \
    "Stop all shared services"

# Test 14: Final Status Check
run_test_step "Final Status Check" \
    "podium status" \
    "Final status check to verify everything is stopped"

# Test completion
echo-return
echo -e "${TEST_CYAN}========================================${TEST_RESET}"
echo -e "${TEST_CYAN}INTERACTIVE TEST SUITE COMPLETED${TEST_RESET}"
echo -e "${TEST_CYAN}========================================${TEST_RESET}"
echo-return
echo -e "${TEST_GREEN}All tests have been executed!${TEST_RESET}"
echo-return
echo -e "${TEST_YELLOW}Review the output above to verify all tests passed.${TEST_RESET}"
echo -e "${TEST_YELLOW}If any tests failed, investigate the specific commands.${TEST_RESET}"
echo-return
