#!/bin/bash

# Visual App Builder - Production Build Script
# Builds the backend server executable and Flutter web app

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$PROJECT_DIR/dist"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}   Visual App Builder - Prod Build    ${NC}"
echo -e "${BLUE}=======================================${NC}"
echo ""

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

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Install dependencies
echo -e "${YELLOW}Step 1/4: Installing dependencies...${NC}"

cd "$PROJECT_DIR/packages/shared"
dart pub get --no-precompile > /dev/null 2>&1

cd "$PROJECT_DIR/packages/backend"
dart pub get --no-precompile > /dev/null 2>&1

cd "$PROJECT_DIR"
flutter pub get > /dev/null 2>&1

echo -e "${GREEN}Dependencies installed!${NC}"
echo ""

# Build backend executable
echo -e "${YELLOW}Step 2/4: Building backend server...${NC}"

cd "$PROJECT_DIR/packages/backend"
dart compile exe bin/server.dart -o "$OUTPUT_DIR/vab-server"

echo -e "${GREEN}Backend compiled: $OUTPUT_DIR/vab-server${NC}"
echo ""

# Build Flutter web app
echo -e "${YELLOW}Step 3/4: Building Flutter web app...${NC}"

cd "$PROJECT_DIR"
flutter build web --release

# Copy web build to output
cp -r "$PROJECT_DIR/build/web" "$OUTPUT_DIR/web"

echo -e "${GREEN}Web app built: $OUTPUT_DIR/web${NC}"
echo ""

# Create run script
echo -e "${YELLOW}Step 4/4: Creating run script...${NC}"

cat > "$OUTPUT_DIR/run.sh" << 'EOF'
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
EOF

chmod +x "$OUTPUT_DIR/run.sh"
chmod +x "$OUTPUT_DIR/vab-server"

echo -e "${GREEN}Run script created: $OUTPUT_DIR/run.sh${NC}"
echo ""

# Summary
echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}   Build Complete!                    ${NC}"
echo -e "${GREEN}=======================================${NC}"
echo ""
echo "Output directory: $OUTPUT_DIR"
echo ""
echo "Contents:"
ls -la "$OUTPUT_DIR"
echo ""
echo -e "To run in production:"
echo -e "  ${BLUE}cd $OUTPUT_DIR && ./run.sh${NC}"
echo ""
echo -e "Or with a custom port:"
echo -e "  ${BLUE}cd $OUTPUT_DIR && ./run.sh 9000${NC}"
echo ""
