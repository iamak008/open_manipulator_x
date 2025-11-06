#!/bin/bash

###############################################################################
# OpenMANIPULATOR-X noVNC Container Management Script
# Browser-based ROS 2 Jazzy development environment
###############################################################################

set -e

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONTAINER_NAME="omx_vnc"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"
VNC_PORT="6080"
VNC_URL="http://localhost:${VNC_PORT}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display colored output
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to display help
show_help() {
    cat << EOF
${GREEN}OpenMANIPULATOR-X noVNC Container Manager${NC}

${BLUE}Usage:${NC} $0 [command]

${BLUE}Commands:${NC}
  ${GREEN}help${NC}                    Show this help message
  ${GREEN}start${NC}                   Start the container (builds if needed)
  ${GREEN}stop${NC}                    Stop the container
  ${GREEN}restart${NC}                 Restart the container
  ${GREEN}enter${NC}                   Enter the running container (shell)
  ${GREEN}logs${NC}                    Show container logs
  ${GREEN}status${NC}                  Show container status
  ${GREEN}build${NC}                   Build/rebuild the Docker image
  ${GREEN}clean${NC}                   Stop and remove container (keeps image)
  ${GREEN}purge${NC}                   Remove container, image, and volumes
  ${GREEN}open${NC}                    Open noVNC in browser
  ${GREEN}devices${NC}                 List USB devices (U2D2, cameras)

${BLUE}Examples:${NC}
  $0 start                Start the container and open in browser
  $0 enter                Open a terminal in the running container
  $0 logs                 View container logs
  $0 stop                 Stop the container
  $0 clean                Clean up container (for rebuilding)

${BLUE}Access:${NC}
  noVNC URL: ${GREEN}${VNC_URL}${NC}
  Default credentials: ubuntu / ubuntu

${BLUE}Notes:${NC}
  - The container runs in ${YELLOW}host network mode${NC} for ROS 2 DDS
  - USB devices require ${YELLOW}privileged mode${NC} (for U2D2/cameras)
  - Workspace persists in: ${YELLOW}./workspace${NC}
  - Logs persist in: ${YELLOW}./logs${NC}

EOF
}

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        log_error "Docker is not running or not accessible"
        exit 1
    fi
}

# Function to check if container exists
container_exists() {
    docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
}

# Function to check if container is running
container_running() {
    docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
}

# Function to set up host directories
setup_directories() {
    log_info "Setting up host directories..."
    mkdir -p "${SCRIPT_DIR}/workspace"
    mkdir -p "${SCRIPT_DIR}/logs"
    log_success "Directories created"
}

# Function to set up U2D2 udev rules (Linux only)
setup_udev_rules() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        log_info "Setting up U2D2 (FTDI) udev rules..."
        
        UDEV_RULE='KERNEL=="ttyUSB*", DRIVERS=="ftdi_sio", MODE="0666", ATTR{device/latency_timer}="1"'
        UDEV_FILE="/etc/udev/rules.d/99-u2d2.rules"
        
        # Check if rule already exists
        if [ -f "$UDEV_FILE" ]; then
            log_info "U2D2 udev rule already exists"
        else
            echo "$UDEV_RULE" | sudo tee "$UDEV_FILE" > /dev/null
            sudo udevadm control --reload-rules
            sudo udevadm trigger
            log_success "U2D2 udev rules installed"
        fi
    else
        log_info "Skipping udev setup (not on Linux)"
    fi
}

# Function to open browser
open_browser() {
    local url="$1"
    log_info "Opening browser at ${url}..."
    
    # Wait for noVNC to be ready
    local retries=0
    local max_retries=15
    
    while [ $retries -lt $max_retries ]; do
        if curl -s "${url}" > /dev/null 2>&1; then
            break
        fi
        retries=$((retries + 1))
        sleep 2
    done
    
    if [ $retries -eq $max_retries ]; then
        log_warning "noVNC may not be ready yet. Try opening manually: ${url}"
        return
    fi
    
    # Try to open browser based on OS
    if command -v xdg-open > /dev/null; then
        xdg-open "${url}" 2>/dev/null &
    elif command -v open > /dev/null; then
        open "${url}" 2>/dev/null &
    elif command -v wslview > /dev/null; then
        wslview "${url}" 2>/dev/null &
    else
        log_warning "Could not auto-open browser. Please navigate to: ${url}"
    fi
}

# Function to start the container
start_container() {
    check_docker
    setup_directories
    setup_udev_rules
    
    if container_running; then
        log_warning "Container is already running"
        log_info "Access noVNC at: ${VNC_URL}"
        return
    fi
    
    log_info "Starting OpenMANIPULATOR-X noVNC container..."
    
    # Start with docker-compose
    docker compose -f "${COMPOSE_FILE}" up -d
    
    if [ $? -eq 0 ]; then
        log_success "Container started successfully"
        log_info "noVNC URL: ${VNC_URL}"
        log_info "Default credentials: ubuntu / ubuntu"
        
        # Offer to open browser
        read -p "Open noVNC in browser? [Y/n] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            open_browser "${VNC_URL}"
        fi
    else
        log_error "Failed to start container"
        exit 1
    fi
}

# Function to stop the container
stop_container() {
    check_docker
    
    if ! container_running; then
        log_warning "Container is not running"
        return
    fi
    
    log_info "Stopping container..."
    docker compose -f "${COMPOSE_FILE}" stop
    log_success "Container stopped"
}

# Function to restart the container
restart_container() {
    check_docker
    log_info "Restarting container..."
    stop_container
    sleep 2
    start_container
}

# Function to enter the container
enter_container() {
    check_docker
    
    if ! container_running; then
        log_error "Container is not running. Start it first with: $0 start"
        exit 1
    fi
    
    log_info "Entering container shell..."
    docker exec -it "${CONTAINER_NAME}" bash
}

# Function to show logs
show_logs() {
    check_docker
    
    if ! container_exists; then
        log_error "Container does not exist"
        exit 1
    fi
    
    log_info "Showing container logs (Ctrl+C to exit)..."
    docker compose -f "${COMPOSE_FILE}" logs -f
}

# Function to show status
show_status() {
    check_docker
    
    log_info "Container status:"
    
    if container_running; then
        docker ps --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        echo ""
        log_success "Container is running"
        log_info "Access noVNC at: ${VNC_URL}"
    elif container_exists; then
        log_warning "Container exists but is not running"
        echo "Start it with: $0 start"
    else
        log_info "Container does not exist"
        echo "Create and start it with: $0 start"
    fi
}

# Function to build the image
build_image() {
    check_docker
    setup_directories
    
    log_info "Building Docker image (this may take 10-20 minutes)..."
    docker compose -f "${COMPOSE_FILE}" build
    
    if [ $? -eq 0 ]; then
        log_success "Image built successfully"
    else
        log_error "Build failed"
        exit 1
    fi
}

# Function to clean up (remove container but keep image)
clean_container() {
    check_docker
    
    log_warning "This will stop and remove the container."
    log_info "Your workspace and logs will be preserved in ./workspace and ./logs"
    read -p "Continue? [y/N] " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Cleaning up container..."
        docker compose -f "${COMPOSE_FILE}" down
        log_success "Container removed"
    else
        log_info "Operation cancelled"
    fi
}

# Function to purge everything
purge_all() {
    check_docker
    
    log_error "WARNING: This will remove:"
    echo "  - The container"
    echo "  - The Docker image"
    echo "  - Docker volumes (if any)"
    log_warning "Your ./workspace and ./logs folders will NOT be deleted"
    echo ""
    read -p "Are you absolutely sure? [y/N] " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Purging container, image, and volumes..."
        docker compose -f "${COMPOSE_FILE}" down --rmi all --volumes
        log_success "Purge complete"
    else
        log_info "Operation cancelled"
    fi
}

# Function to list USB devices
list_devices() {
    log_info "Listing USB devices..."
    
    if command -v lsusb > /dev/null; then
        echo ""
        lsusb
        echo ""
        log_info "Looking for FTDI devices (U2D2)..."
        lsusb | grep -i "ftdi\|future technology" || log_warning "No FTDI devices found"
    else
        log_warning "lsusb not available (are you on Linux?)"
    fi
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo ""
        log_info "Serial devices:"
        ls -l /dev/ttyUSB* 2>/dev/null || log_info "No /dev/ttyUSB* devices found"
        ls -l /dev/ttyACM* 2>/dev/null || log_info "No /dev/ttyACM* devices found"
    fi
}

# Function to open noVNC
open_vnc() {
    if ! container_running; then
        log_error "Container is not running. Start it first with: $0 start"
        exit 1
    fi
    
    open_browser "${VNC_URL}"
}

# Main command handling
case "$1" in
    "help"|"--help"|"-h"|"")
        show_help
        ;;
    "start")
        start_container
        ;;
    "stop")
        stop_container
        ;;
    "restart")
        restart_container
        ;;
    "enter")
        enter_container
        ;;
    "logs")
        show_logs
        ;;
    "status")
        show_status
        ;;
    "build")
        build_image
        ;;
    "clean")
        clean_container
        ;;
    "purge")
        purge_all
        ;;
    "open")
        open_vnc
        ;;
    "devices")
        list_devices
        ;;
    *)
        log_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
