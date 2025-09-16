#!/bin/bash

set -e  # Exit on any error

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Starting Spotify App Tests ==="
echo "Current directory: $(pwd)"
echo "Test type: ${TEST_TYPE:-unit}"
echo "Contents: $(ls -la)"

# Install test dependencies
echo "Installing test dependencies..."
pip install -r requirements.txt

# For integration tests, just wait a bit for MongoDB (simple approach)
if [[ $TEST_TYPE == "integration" || $TEST_TYPE == "all" ]]; then
    echo "Waiting for MongoDB to start (using simple delay)..."
    sleep 15
    echo "Proceeding with integration tests..."
fi

# Function to run tests with proper exit codes
run_tests() {
    local test_file=$1
    local test_name=$2
    
    echo "Running $test_name..."
    if pytest "$test_file" -v --tb=short; then
        echo "✅ $test_name passed"
        return 0
    else
        echo "❌ $test_name failed"
        return 1
    fi
}

# Main test execution
case "${TEST_TYPE:-unit}" in
    "unit")
        echo "=== Running Unit Tests ==="
        run_tests "test_main.py" "Unit Tests"
        ;;
    
    "integration")
        echo "=== Running Integration Tests ==="
        run_tests "test_integration.py" "Integration Tests"
        ;;
        
    "all")
        echo "=== Running All Tests ==="
        UNIT_RESULT=0
        INTEGRATION_RESULT=0
        
        # Run unit tests
        run_tests "test_main.py" "Unit Tests" || UNIT_RESULT=1
        
        # Run integration tests
        run_tests "test_integration.py" "Integration Tests" || INTEGRATION_RESULT=1
        
        # Check overall results
        if [[ $UNIT_RESULT -eq 0 && $INTEGRATION_RESULT -eq 0 ]]; then
            echo "✅ All tests passed!"
            exit 0
        else
            echo "❌ Some tests failed!"
            echo "Unit tests: $([ $UNIT_RESULT -eq 0 ] && echo 'PASSED' || echo 'FAILED')"
            echo "Integration tests: $([ $INTEGRATION_RESULT -eq 0 ] && echo 'PASSED' || echo 'FAILED')"
            exit 1
        fi
        ;;
    
    *)
        echo "❌ Invalid TEST_TYPE: ${TEST_TYPE}"
        echo "Valid options: 'unit', 'integration', 'all'"
        exit 1
        ;;
esac

echo "=== Tests completed successfully ==="