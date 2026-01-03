#!/bin/bash

# Visual App Builder - Backend Server Start Script
# Starts only the backend server

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
PORT=${1:-8080}

echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}   Visual App Builder - Backend       ${NC}"
echo -e "${BLUE}=======================================${NC}"
echo ""

# Check if dart is available
if ! command -v dart &> /dev/null; then
    echo -e "${RED}Error: Dart SDK not found. Please install Dart or Flutter.${NC}"
    exit 1
fi

# Install dependencies
echo -e "${YELLOW}Installing dependencies...${NC}"

cd "$PROJECT_DIR/packages/shared"
dart pub get --no-precompile > /dev/null 2>&1

cd "$PROJECT_DIR/packages/backend"
dart pub get --no-precompile > /dev/null 2>&1

echo -e "${GREEN}Dependencies installed!${NC}"
echo ""

# Start server
echo -e "${YELLOW}Starting backend server on port $PORT...${NC}"
echo ""
echo -e "  API:       ${BLUE}http://localhost:$PORT/api${NC}"
echo -e "  WebSocket: ${BLUE}ws://localhost:$PORT/ws/terminal${NC}"
echo -e "  Health:    ${BLUE}http://localhost:$PORT/health${NC}"
echo ""

cd "$PROJECT_DIR/packages/backend"
dart run bin/server.dart --port $PORT
