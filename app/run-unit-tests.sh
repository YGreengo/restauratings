#!/bin/bash

# Simple Restaurant API Test Runner
# Usage: ./run_simple_tests.sh

echo "Restaurant API Simple Test Runner"
echo "===================================="
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
echo ""


# Run the tests
echo "Running tests..."
echo ""
chmod +x ./tests/unittests.sh
./tests/unittests.sh

# Capture exit code
TEST_EXIT_CODE=$?

echo ""
if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo "All tests completed successfully!"
else
    echo "Tests failed with exit code: $TEST_EXIT_CODE"
fi

exit $TEST_EXIT_CODE