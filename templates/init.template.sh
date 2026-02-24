#!/bin/bash

# =============================================================================
# init.sh - Project Initialization Script
# =============================================================================
# Run this script at the start of every session to ensure the environment
# is properly set up and the development server is running.
# =============================================================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Project configuration - MODIFY THESE
PROJECT_DIR="[项目目录]"  # 修改为你的项目代码目录，如 "app", "src", "frontend"
DEV_PORT=3000              # 开发服务器端口

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  Initializing [项目名称]...${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if project directory exists
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}Error: Project directory '$PROJECT_DIR' not found!${NC}"
    echo "Please check the PROJECT_DIR in init.sh and make sure it matches your project structure."
    exit 1
fi

# Install dependencies
echo -e "${YELLOW}📦 Installing dependencies...${NC}"
cd "$PROJECT_DIR"
if [ -f "package.json" ]; then
    npm install
    echo -e "${GREEN}✓ Dependencies installed${NC}"
else
    echo -e "${RED}Error: package.json not found in $PROJECT_DIR${NC}"
    exit 1
fi
cd ..

# Check if port is already in use
if command -v lsof >/dev/null 2>&1; then
    if lsof -Pi :$DEV_PORT -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        echo -e "${YELLOW}⚠️  Port $DEV_PORT is already in use${NC}"
        echo "Killing existing process..."
        lsof -ti:$DEV_PORT | xargs kill -9 2>/dev/null || true
        sleep 1
    fi
fi

# Start development server in background
echo -e "${YELLOW}🚀 Starting development server...${NC}"
cd "$PROJECT_DIR"
npm run dev &
SERVER_PID=$!
cd ..

# Wait for server to be ready
echo -e "${YELLOW}⏳ Waiting for server to start...${NC}"
sleep 3

# Verify server is running
if kill -0 $SERVER_PID 2>/dev/null; then
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  ✓ Initialization complete!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GREEN}  Dev server running at: http://localhost:$DEV_PORT${NC}"
    echo -e "${GREEN}  Server PID: $SERVER_PID${NC}"
    echo ""
    echo -e "${YELLOW}  To stop the server, run: kill $SERVER_PID${NC}"
    echo ""
else
    echo -e "${RED}Error: Failed to start development server${NC}"
    echo "Please check:"
    echo "  1. Is $PROJECT_DIR/package.json correct?"
    echo "  2. Does the dev script exist?"
    echo "  3. Run 'cd $PROJECT_DIR && npm run dev' to see errors"
    exit 1
fi
