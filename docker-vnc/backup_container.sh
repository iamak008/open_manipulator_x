#!/bin/bash
# Complete Container Backup Script
# Copies volume-mounted data into container, then commits and saves the image

set -e  # Exit on error

# Configuration
CONTAINER_NAME="omx_vnc"
BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
IMAGE_NAME="omx_vnc:backup-${TIMESTAMP}"
TAR_FILE="${BACKUP_DIR}/omx_vnc_complete_${TIMESTAMP}.tar"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Complete Container Backup Script${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${RED}Error: Container '${CONTAINER_NAME}' is not running!${NC}"
    exit 1
fi

# Create backup directory
mkdir -p "${BACKUP_DIR}"

echo -e "${YELLOW}Step 1: Creating temporary backup directory inside container...${NC}"
docker exec ${CONTAINER_NAME} mkdir -p /tmp/volume_backup
echo -e "${GREEN}✓ Temp directory created${NC}"
echo ""

echo -e "${YELLOW}Step 2: Copying volume-mounted data into container...${NC}"
echo "  - Copying workspace..."
docker exec ${CONTAINER_NAME} bash -c "cp -r /home/ubuntu/workspace /tmp/volume_backup/ 2>/dev/null || echo 'workspace not found or empty'"

echo "  - Copying omx_ws..."
docker exec ${CONTAINER_NAME} bash -c "cp -r /home/ubuntu/omx_ws /tmp/volume_backup/ 2>/dev/null || echo 'omx_ws not found or empty'"

echo "  - Copying logs..."
docker exec ${CONTAINER_NAME} bash -c "cp -r /home/ubuntu/logs /tmp/volume_backup/ 2>/dev/null || echo 'logs not found or empty'"

echo -e "${GREEN}✓ Volume data copied into container${NC}"
echo ""

echo -e "${YELLOW}Step 3: Getting backup size estimate...${NC}"
BACKUP_SIZE=$(docker exec ${CONTAINER_NAME} du -sh /tmp/volume_backup 2>/dev/null | awk '{print $1}' || echo "unknown")
echo -e "  Volume data size: ${BACKUP_SIZE}"
echo ""

echo -e "${YELLOW}Step 4: Committing container to image...${NC}"
echo "  Image name: ${IMAGE_NAME}"
docker commit ${CONTAINER_NAME} ${IMAGE_NAME}
echo -e "${GREEN}✓ Container committed${NC}"
echo ""

echo -e "${YELLOW}Step 5: Saving image to tar file...${NC}"
echo "  Output: ${TAR_FILE}"
docker save -o "${TAR_FILE}" ${IMAGE_NAME}
echo -e "${GREEN}✓ Image saved${NC}"
echo ""

echo -e "${YELLOW}Step 6: Compressing tar file...${NC}"
gzip "${TAR_FILE}"
TAR_FILE="${TAR_FILE}.gz"
echo -e "${GREEN}✓ Compressed${NC}"
echo ""

echo -e "${YELLOW}Step 7: Cleaning up temporary data in container...${NC}"
docker exec ${CONTAINER_NAME} rm -rf /tmp/volume_backup
echo -e "${GREEN}✓ Cleanup complete${NC}"
echo ""

# Get final file size
FINAL_SIZE=$(du -sh "${TAR_FILE}" | awk '{print $1}')

echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}  Backup Complete!${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo -e "📦 Image name:     ${IMAGE_NAME}"
echo -e "💾 Backup file:    ${TAR_FILE}"
echo -e "📊 File size:      ${FINAL_SIZE}"
echo ""
echo -e "${BLUE}To restore on another machine:${NC}"
echo -e "  1. Copy ${TAR_FILE} to target machine"
echo -e "  2. Run: gunzip $(basename ${TAR_FILE})"
echo -e "  3. Run: docker load -i $(basename ${TAR_FILE%.gz})"
echo -e "  4. Extract volumes: docker run --rm ${IMAGE_NAME} bash -c 'cp -r /tmp/volume_backup/* /restore/'"
echo ""
echo -e "${YELLOW}Note: The backed-up volumes are stored in /tmp/volume_backup inside the image${NC}"
echo ""
