#!/bin/bash
# Container Restore Script
# Loads a backed-up image and extracts volume data

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Container Restore Script${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Check if backup file is provided
if [ $# -eq 0 ]; then
    echo -e "${RED}Error: No backup file specified!${NC}"
    echo ""
    echo "Usage: $0 <backup-file.tar.gz>"
    echo ""
    echo "Available backups:"
    ls -lh ./backups/*.tar.gz 2>/dev/null || echo "  No backups found in ./backups/"
    exit 1
fi

BACKUP_FILE="$1"

# Check if file exists
if [ ! -f "${BACKUP_FILE}" ]; then
    echo -e "${RED}Error: Backup file '${BACKUP_FILE}' not found!${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 1: Decompressing backup file...${NC}"
if [[ "${BACKUP_FILE}" == *.gz ]]; then
    gunzip -k "${BACKUP_FILE}"
    TAR_FILE="${BACKUP_FILE%.gz}"
    echo -e "${GREEN}✓ Decompressed${NC}"
else
    TAR_FILE="${BACKUP_FILE}"
    echo -e "${GREEN}✓ File already decompressed${NC}"
fi
echo ""

echo -e "${YELLOW}Step 2: Loading Docker image...${NC}"
docker load -i "${TAR_FILE}"
echo -e "${GREEN}✓ Image loaded${NC}"
echo ""

# Get the image name from the tar
IMAGE_NAME=$(docker load -i "${TAR_FILE}" 2>&1 | grep "Loaded image:" | awk '{print $3}')
echo -e "Loaded image: ${IMAGE_NAME}"
echo ""

echo -e "${YELLOW}Step 3: Extracting volume data...${NC}"
RESTORE_DIR="./restored_volumes"
mkdir -p "${RESTORE_DIR}"

echo "  Creating temporary container to extract volumes..."
TEMP_CONTAINER=$(docker create ${IMAGE_NAME})

echo "  Copying volume data to ${RESTORE_DIR}..."
docker cp ${TEMP_CONTAINER}:/tmp/volume_backup/. "${RESTORE_DIR}/" 2>/dev/null || echo "  (No volume backup found in image)"

echo "  Removing temporary container..."
docker rm ${TEMP_CONTAINER}

echo -e "${GREEN}✓ Volume data extracted to ${RESTORE_DIR}${NC}"
echo ""

echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}  Restore Complete!${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo -e "📦 Image loaded:   ${IMAGE_NAME}"
echo -e "📂 Volumes extracted to: ${RESTORE_DIR}/"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "  1. Copy restored volumes to their target locations:"
echo -e "     cp -r ${RESTORE_DIR}/workspace ./workspace"
echo -e "     cp -r ${RESTORE_DIR}/omx_ws ~/robotics/omx_vnc_ws"
echo -e "     cp -r ${RESTORE_DIR}/logs ~/robotics/omx_logs"
echo ""
echo -e "  2. Update docker-compose.yml if needed"
echo ""
echo -e "  3. Start container:"
echo -e "     docker-compose up -d"
echo ""

# Clean up decompressed tar if we created it
if [[ "${BACKUP_FILE}" == *.gz ]] && [ -f "${TAR_FILE}" ]; then
    rm "${TAR_FILE}"
fi
