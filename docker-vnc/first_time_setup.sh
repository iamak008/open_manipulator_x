#!/bin/bash

###############################################################################
# First-Time Setup Script for OpenMANIPULATOR-X noVNC Docker
# This script guides you through the initial setup
###############################################################################

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║     OpenMANIPULATOR-X noVNC Docker - First Time Setup        ║
║                                                               ║
║     Browser-based ROS 2 Jazzy Development Environment        ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo ""
echo -e "${GREEN}This script will:${NC}"
echo "  1. Check if Docker is installed and running"
echo "  2. Create necessary directories"
echo "  3. Build the Docker image (~15-20 minutes)"
echo "  4. Start the container"
echo "  5. Open your browser to the noVNC desktop"
echo ""
echo -e "${YELLOW}Requirements:${NC}"
echo "  - Docker installed and running"
echo "  - ~10 GB free disk space"
echo "  - Internet connection"
echo ""

read -p "Press Enter to continue or Ctrl+C to cancel..."

###############################################################################
# Step 1: Check Docker
###############################################################################

echo ""
echo -e "${BLUE}[1/5] Checking Docker...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Docker is not installed!${NC}"
    echo ""
    echo "Please install Docker from: https://docs.docker.com/get-docker/"
    echo ""
    echo "Installation guides:"
    echo "  - macOS:   https://docs.docker.com/desktop/install/mac-install/"
    echo "  - Windows: https://docs.docker.com/desktop/install/windows-install/"
    echo "  - Linux:   https://docs.docker.com/engine/install/"
    exit 1
fi

if ! docker info > /dev/null 2>&1; then
    echo -e "${YELLOW}Docker is installed but not running!${NC}"
    echo ""
    echo "Please start Docker Desktop (macOS/Windows) or the Docker daemon (Linux)."
    exit 1
fi

echo -e "${GREEN}✓ Docker is installed and running${NC}"
docker --version

###############################################################################
# Step 2: Create Directories
###############################################################################

echo ""
echo -e "${BLUE}[2/5] Creating directories...${NC}"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

mkdir -p workspace
mkdir -p logs

echo -e "${GREEN}✓ Created workspace/ and logs/ directories${NC}"

###############################################################################
# Step 3: Build Image
###############################################################################

echo ""
echo -e "${BLUE}[3/5] Building Docker image...${NC}"
echo -e "${YELLOW}This will take approximately 15-20 minutes.${NC}"
echo ""
echo "The build process will:"
echo "  - Download ROS 2 Jazzy desktop image with noVNC (~2 GB)"
echo "  - Install RealSense drivers and ROS packages"
echo "  - Clone OpenMANIPULATOR and Dynamixel repos"
echo "  - Build the workspace"
echo ""
echo "Progress will be shown below..."
echo ""

read -p "Press Enter to start building or Ctrl+C to cancel..."

if ! ./container.sh build; then
    echo ""
    echo -e "${YELLOW}Build failed!${NC}"
    echo ""
    echo "Common causes:"
    echo "  - Network issues (check internet connection)"
    echo "  - Low disk space (need ~10 GB free)"
    echo "  - Docker out of memory (increase Docker Desktop RAM limit)"
    echo ""
    echo "Try running: ./container.sh build"
    exit 1
fi

echo -e "${GREEN}✓ Image built successfully${NC}"

###############################################################################
# Step 4: Start Container
###############################################################################

echo ""
echo -e "${BLUE}[4/5] Starting container...${NC}"

if ! ./container.sh start; then
    echo ""
    echo -e "${YELLOW}Failed to start container!${NC}"
    echo ""
    echo "Try running: ./container.sh logs"
    echo "For troubleshooting: ./container.sh status"
    exit 1
fi

echo -e "${GREEN}✓ Container started${NC}"

###############################################################################
# Step 5: Wait for noVNC to be ready
###############################################################################

echo ""
echo -e "${BLUE}[5/5] Waiting for noVNC to be ready...${NC}"

NOVNC_URL="http://localhost:6080"
RETRIES=0
MAX_RETRIES=30

while [ $RETRIES -lt $MAX_RETRIES ]; do
    if curl -s "$NOVNC_URL" > /dev/null 2>&1; then
        break
    fi
    echo -n "."
    sleep 2
    RETRIES=$((RETRIES + 1))
done

echo ""

if [ $RETRIES -eq $MAX_RETRIES ]; then
    echo -e "${YELLOW}noVNC is taking longer than expected to start.${NC}"
    echo ""
    echo "Please try opening manually in a few moments:"
    echo "  $NOVNC_URL"
    echo ""
    echo "Check logs with: ./container.sh logs"
else
    echo -e "${GREEN}✓ noVNC is ready!${NC}"
fi

###############################################################################
# Success!
###############################################################################

echo ""
echo -e "${GREEN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║                    Setup Complete! 🎉                        ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo ""
echo -e "${BLUE}Access your development environment:${NC}"
echo -e "  ${GREEN}$NOVNC_URL${NC}"
echo ""
echo -e "${BLUE}Default credentials:${NC}"
echo "  Username: ubuntu"
echo "  Password: ubuntu"
echo ""
echo -e "${BLUE}Quick Start:${NC}"
echo "  1. Open the URL above in your browser"
echo "  2. Click 'Connect' (or enter password if prompted)"
echo "  3. Open a terminal from the desktop menu"
echo "  4. Try: ${GREEN}ros2 launch open_manipulator_bringup open_manipulator_x_gazebo.launch.py${NC}"
echo ""
echo -e "${BLUE}Container Management:${NC}"
echo "  Start:   ${GREEN}./container.sh start${NC}"
echo "  Stop:    ${GREEN}./container.sh stop${NC}"
echo "  Shell:   ${GREEN}./container.sh enter${NC}"
echo "  Status:  ${GREEN}./container.sh status${NC}"
echo "  Help:    ${GREEN}./container.sh help${NC}"
echo ""
echo -e "${BLUE}Documentation:${NC}"
echo "  README.md            - Full documentation"
echo "  QUICK_REFERENCE.md   - Command cheat sheet"
echo "  COMPARISON.md        - Compare with original Docker"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Follow the tutorial in README.md"
echo "  2. Launch Gazebo simulation"
echo "  3. Try MoveIt + RViz"
echo "  4. Write Python control scripts"
echo ""

# Try to open browser
read -p "Open noVNC in browser now? [Y/n] " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
    if command -v xdg-open > /dev/null; then
        xdg-open "$NOVNC_URL" 2>/dev/null &
    elif command -v open > /dev/null; then
        open "$NOVNC_URL" 2>/dev/null &
    elif command -v wslview > /dev/null; then
        wslview "$NOVNC_URL" 2>/dev/null &
    else
        echo "Please open manually: $NOVNC_URL"
    fi
    
    echo ""
    echo -e "${GREEN}Browser should open shortly...${NC}"
    echo "If not, copy and paste this URL: $NOVNC_URL"
fi

echo ""
echo -e "${BLUE}Happy coding! 🤖🦾${NC}"
echo ""
