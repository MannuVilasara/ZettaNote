#!/bin/bash

# ZettaNote Deployment Script
# This script handles the deployment of frontend, admin-portal, and backend

set -e  # Exit on any error

# Configuration
DEPLOY_BASE="/opt/zettanote"
RELEASE_DIR="${DEPLOY_BASE}/releases/$1"
CURRENT_DIR="${DEPLOY_BASE}/current"
SHARED_DIR="${DEPLOY_BASE}/shared"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    log_error "Please run as root or with sudo"
    exit 1
fi

log_info "Starting deployment process..."
log_info "Release: $1"
log_info "Commit SHA: $2"

# Create necessary directories
log_info "Creating directory structure..."
mkdir -p "${RELEASE_DIR}"
mkdir -p "${SHARED_DIR}"
mkdir -p "${CURRENT_DIR}"

# Verify artifacts exist
log_info "Checking for artifacts..."

if [ ! -d "${RELEASE_DIR}/frontend" ]; then
    log_error "Frontend artifacts not found in ${RELEASE_DIR}/frontend"
    exit 1
fi

if [ ! -d "${RELEASE_DIR}/admin-portal" ]; then
    log_error "Admin portal artifacts not found in ${RELEASE_DIR}/admin-portal"
    exit 1
fi

if [ ! -d "${RELEASE_DIR}/backend" ]; then
    log_error "Backend artifacts not found in ${RELEASE_DIR}/backend"
    exit 1
fi

log_info "All artifacts found successfully"

# Create symbolic links to new release
log_info "Updating symbolic links..."

# Backup current symlink
if [ -L "${CURRENT_DIR}" ]; then
    PREVIOUS_RELEASE=$(readlink "${CURRENT_DIR}")
    log_info "Previous release: ${PREVIOUS_RELEASE}"
fi

# Update frontend symlink
ln -snf "${RELEASE_DIR}/frontend" "${CURRENT_DIR}/frontend"
log_info "Frontend symlink updated"

# Update admin-portal symlink
ln -snf "${RELEASE_DIR}/admin-portal" "${CURRENT_DIR}/admin-portal"
log_info "Admin portal symlink updated"

# Update backend symlink
ln -snf "${RELEASE_DIR}/backend" "${CURRENT_DIR}/backend"
log_info "Backend symlink updated"

# Copy environment file to backend if it doesn't exist in release
if [ ! -f "${RELEASE_DIR}/backend/.env" ] && [ -f "${SHARED_DIR}/.env" ]; then
    log_info "Copying environment file to backend..."
    cp "${SHARED_DIR}/.env" "${RELEASE_DIR}/backend/.env"
fi

# Set proper ownership for all artifacts
log_info "Setting proper ownership..."
chown -R www-data:www-data "${RELEASE_DIR}"
chown -R www-data:www-data "${CURRENT_DIR}"

cd "${CURRENT_DIR}"/backend && npm install --production
# Restart services
log_info "Restarting services..."

# Restart backend service
if systemctl is-active --quiet zettanote-backend; then
    systemctl restart zettanote-backend
    log_info "Backend service restarted"
else
    systemctl start zettanote-backend
    log_info "Backend service started"
fi

# Restart frontend service
if systemctl is-active --quiet zettanote-frontend; then
    systemctl restart zettanote-frontend
    log_info "Frontend service restarted"
else
    systemctl start zettanote-frontend
    log_info "Frontend service started"
fi

# Restart admin portal service
if systemctl is-active --quiet zettanote-admin; then
    systemctl restart zettanote-admin
    log_info "Admin portal service restarted"
else
    systemctl start zettanote-admin
    log_info "Admin portal service started"
fi

# Verify services are running
log_info "Verifying services..."
sleep 3

if systemctl is-active --quiet zettanote-backend; then
    log_info "✓ Backend is running"
else
    log_error "✗ Backend failed to start"
fi

if systemctl is-active --quiet zettanote-frontend; then
    log_info "✓ Frontend is running"
else
    log_error "✗ Frontend failed to start"
fi

if systemctl is-active --quiet zettanote-admin; then
    log_info "✓ Admin portal is running"
else
    log_error "✗ Admin portal failed to start"
fi

# Cleanup old releases (keep last 5)
log_info "Cleaning up old releases..."
cd "${DEPLOY_BASE}/releases"
ls -t | tail -n +6 | xargs -r rm -rf
log_info "Cleanup completed"

# Save deployment info
echo "Release: $1" > "${RELEASE_DIR}/deployment-info.txt"
echo "Commit: $2" >> "${RELEASE_DIR}/deployment-info.txt"
echo "Date: $(date)" >> "${RELEASE_DIR}/deployment-info.txt"

log_info "Deployment completed successfully! 🚀"
log_info "Release information saved to ${RELEASE_DIR}/deployment-info.txt"
