#!/bin/bash

# Visual App Builder - Development Start Script
# Starts both the backend server and Flutter web frontend

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}   Visual App Builder - Dev Mode      ${NC}"
echo -e "${BLUE}=======================================${NC}"
echo ""

# Parse arguments
BACKEND_PORT=${BACKEND_PORT:-8080}
FRONTEND_PORT=${FRONTEND_PORT:-3000}

# Check if dart is available
if ! command -v dart &> /dev/null; then
    echo -e "${RED}Error: Dart SDK not found. Please install Dart or Flutter.${NC}"
    exit 1
fi

# Check if flutter is available
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Error: Flutter SDK not found. Please install Flutter.${NC}"
    exit 1
fi

# Function to cleanup on exit
cleanup() {
    echo ""
    echo -e "${YELLOW}Shutting down...${NC}"
    if [ ! -z "$BACKEND_PID" ]; then
        kill $BACKEND_PID 2>/dev/null || true
    fi
    if [ ! -z "$FRONTEND_PID" ]; then
        kill $FRONTEND_PID 2>/dev/null || true
    fi
    echo -e "${GREEN}Goodbye!${NC}"
}

trap cleanup EXIT INT TERM

# Install dependencies
echo -e "${YELLOW}Installing dependencies...${NC}"

echo "  -> Shared package..."
cd "$PROJECT_DIR/packages/shared"
dart pub get --no-precompile > /dev/null 2>&1

echo "  -> Backend package..."
cd "$PROJECT_DIR/packages/backend"
dart pub get --no-precompile > /dev/null 2>&1

echo "  -> Frontend..."
cd "$PROJECT_DIR"
flutter pub get > /dev/null 2>&1

echo -e "${GREEN}Dependencies installed!${NC}"
echo ""

# Start backend server
echo -e "${YELLOW}Starting backend server on port $BACKEND_PORT...${NC}"
cd "$PROJECT_DIR/packages/backend"
dart run bin/server.dart --port $BACKEND_PORT &
BACKEND_PID=$!

# Wait for backend to start
sleep 2

# Check if backend is running
if ! kill -0 $BACKEND_PID 2>/dev/null; then
    echo -e "${RED}Failed to start backend server${NC}"
    exit 1
fi

echo -e "${GREEN}Backend server started (PID: $BACKEND_PID)${NC}"
echo ""

# Start Flutter web frontend
echo -e "${YELLOW}Starting Flutter web frontend on port $FRONTEND_PORT...${NC}"
cd "$PROJECT_DIR"
flutter run -d chrome --web-port $FRONTEND_PORT &
FRONTEND_PID=$!

echo ""
echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}   Development servers started!       ${NC}"
echo -e "${GREEN}=======================================${NC}"
echo ""
echo -e "  Backend:  ${BLUE}http://localhost:$BACKEND_PORT${NC}"
echo -e "  Frontend: ${BLUE}http://localhost:$FRONTEND_PORT${NC}"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop all servers${NC}"
echo ""

# Wait for processes
wait
