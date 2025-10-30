#!/usr/bin/env bash
set -euo pipefail

# Simple E2E Test Runner
# Usage: ./run_simple_e2e.sh

echo "Restaurant E2E Test Runner"
echo "============================="

TEST_URL="http://172.17.0.1:80/health"

# Check if the app is running
echo "Checking if application is running..."
if ! curl --fail --silent --show-error "$TEST_URL" > /dev/null; then
    echo "Application is not running! on $TEST_URL"
    echo "Please start the application first:"
    echo "   docker-compose up -d"
    exit 1
fi

echo "Application is running!"
echo

# Ensure tests are executable
chmod +x ./tests/e2e.sh

# Run the E2E tests
echo "Running E2E tests..."
echo
./tests/e2e.sh

E2E_EXIT_CODE=$?
echo
if [ "$E2E_EXIT_CODE" -eq 0 ]; then
    echo "All E2E tests completed successfully!"
else
    echo "E2E tests failed with exit code: $E2E_EXIT_CODE"
fi

exit "$E2E_EXIT_CODE"
