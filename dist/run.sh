#!/bin/bash

# Visual App Builder - Production Run Script
# Starts the server and opens the app in a browser

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT=${1:-8080}

echo "Starting Visual App Builder on port $PORT..."
echo ""
echo "  App:    http://localhost:$PORT"
echo "  API:    http://localhost:$PORT/api"
echo ""
echo "Press Ctrl+C to stop"
echo ""

# Start server with static files
"$SCRIPT_DIR/vab-server" --port $PORT --static-files "$SCRIPT_DIR/web"
