#!/bin/bash

# ZettaNote Server Setup Script
# Run this script on your server to set up the deployment environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "\n${BLUE}==>${NC} $1\n"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    log_error "Please run as root or with sudo"
    exit 1
fi

log_step "ZettaNote Server Setup"
log_info "This script will set up your server for ZettaNote deployment"

# Update system
log_step "Step 1: Updating system packages"
apt update && apt upgrade -y
log_info "System updated successfully"

# Install Node.js
log_step "Step 2: Installing Node.js 20.x"
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt install -y nodejs
    log_info "Node.js installed: $(node --version)"
else
    log_info "Node.js already installed: $(node --version)"
fi

# Install pnpm
log_step "Step 3: Installing pnpm"
if ! command -v pnpm &> /dev/null; then
    npm install -g pnpm
    log_info "pnpm installed: $(pnpm --version)"
else
    log_info "pnpm already installed: $(pnpm --version)"
fi

# Install serve
log_step "Step 4: Installing serve"
if ! command -v serve &> /dev/null; then
    npm install -g serve
    log_info "serve installed"
else
    log_info "serve already installed"
fi

# Install Nginx
log_step "Step 5: Installing Nginx"
if ! command -v nginx &> /dev/null; then
    apt install -y nginx
    systemctl enable nginx
    systemctl start nginx
    log_info "Nginx installed and started"
else
    log_info "Nginx already installed"
fi

# Install MongoDB
log_step "Step 6: Installing MongoDB"
if ! command -v mongod &> /dev/null; then
    log_warn "MongoDB installation method varies by Ubuntu version"
    log_info "Please install MongoDB manually following the official guide:"
    log_info "https://www.mongodb.com/docs/manual/installation/"
else
    log_info "MongoDB already installed"
fi

# Install Git
log_step "Step 7: Installing Git"
if ! command -v git &> /dev/null; then
    apt install -y git
    log_info "Git installed"
else
    log_info "Git already installed"
fi

# Create directory structure
log_step "Step 8: Creating directory structure"
mkdir -p /opt/zettanote/{releases,current,shared}
mkdir -p /var/log/zettanote
log_info "Directories created"

# Set permissions
log_step "Step 9: Setting permissions"
chown -R www-data:www-data /opt/zettanote
chown -R www-data:www-data /var/log/zettanote
log_info "Permissions set"

# Create environment file template
log_step "Step 10: Creating environment file template"
cat > /opt/zettanote/shared/.env.example << 'EOF'
# ZettaNote Environment Configuration
PORT=5000
DB=mongodb://localhost:27017/zettanote
JWT_SECRET=CHANGE_THIS_TO_A_RANDOM_SECRET
NODE_ENV=production
EOF

log_info "Environment template created at /opt/zettanote/shared/.env.example"
log_warn "Please copy .env.example to .env and update the values:"
echo "    sudo cp /opt/zettanote/shared/.env.example /opt/zettanote/shared/.env"
echo "    sudo nano /opt/zettanote/shared/.env"

# Generate JWT secret suggestion
JWT_SECRET=$(openssl rand -base64 32)
log_info "Suggested JWT_SECRET: $JWT_SECRET"

# Setup SSH for GitHub Actions
log_step "Step 11: Setting up SSH for GitHub Actions"
log_info "To allow GitHub Actions to deploy, you need to:"
echo "  1. Generate an SSH key:"
echo "     ssh-keygen -t ed25519 -C 'github-actions@zettanote' -f ~/.ssh/github-actions"
echo "  2. Add the public key to authorized_keys:"
echo "     cat ~/.ssh/github-actions.pub >> ~/.ssh/authorized_keys"
echo "  3. Copy the private key content for GitHub secrets:"
echo "     cat ~/.ssh/github-actions"

# Install systemd services
log_step "Step 12: Installing systemd services"
if [ -f "systemd/zettanote-backend.service" ]; then
    cp systemd/*.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable zettanote-backend zettanote-frontend zettanote-admin
    log_info "Systemd services installed and enabled"
else
    log_warn "Systemd service files not found in current directory"
    log_info "Please copy service files manually after cloning the repository"
fi

# Setup Nginx
log_step "Step 13: Setting up Nginx"
if [ -f "nginx/zettanote.conf" ]; then
    cp nginx/zettanote.conf /etc/nginx/sites-available/zettanote
    log_warn "Please edit /etc/nginx/sites-available/zettanote and update your domain names"
    log_info "Then run:"
    echo "    sudo ln -s /etc/nginx/sites-available/zettanote /etc/nginx/sites-enabled/"
    echo "    sudo nginx -t"
    echo "    sudo systemctl restart nginx"
else
    log_warn "Nginx config file not found in current directory"
    log_info "Please copy nginx config manually after cloning the repository"
fi

# Copy deployment script
log_step "Step 14: Setting up deployment script"
if [ -f "deploy.sh" ]; then
    cp deploy.sh /opt/zettanote/deploy.sh
    chmod +x /opt/zettanote/deploy.sh
    log_info "Deployment script installed"
else
    log_warn "deploy.sh not found in current directory"
    log_info "Please copy deploy.sh manually after cloning the repository"
fi

# Stop and disable nginx (we'll run frontend on port 80 directly)
log_step "Step 15: Configuring port 80 for frontend"
log_info "Stopping Nginx to free up port 80..."
systemctl stop nginx 2>/dev/null || true
systemctl disable nginx 2>/dev/null || true
log_info "Port 80 will be used by frontend service"
log_warn "If you need Nginx as reverse proxy, edit frontend service to use port 3000"

# Setup firewall (optional)
log_step "Step 16: Firewall configuration (optional)"
if command -v ufw &> /dev/null; then
    log_info "UFW detected. To configure firewall, run:"
    echo "    sudo ufw allow 22/tcp  # SSH"
    echo "    sudo ufw allow 80/tcp  # HTTP"
    echo "    sudo ufw allow 443/tcp # HTTPS"
    echo "    sudo ufw allow 3001/tcp # Admin Portal"
    echo "    sudo ufw allow 5000/tcp # Backend API"
    echo "    sudo ufw enable"
else
    log_info "UFW not installed. Install with: sudo apt install ufw"
fi

# Summary
log_step "Setup Complete!"
echo -e "${GREEN}✓${NC} System packages updated"
echo -e "${GREEN}✓${NC} Node.js, pnpm, and serve installed"
echo -e "${GREEN}✓${NC} Nginx installed"
echo -e "${GREEN}✓${NC} Directory structure created"
echo -e "${GREEN}✓${NC} Permissions set"

echo -e "\n${YELLOW}Next Steps:${NC}"
echo "1. Configure environment variables:"
echo "   sudo cp /opt/zettanote/shared/.env.example /opt/zettanote/shared/.env"
echo "   sudo nano /opt/zettanote/shared/.env"
echo ""
echo "2. Set up SSH key for GitHub Actions (see step 11 above)"
echo ""
echo "3. Configure Nginx with your domain name"
echo ""
echo "4. Add GitHub repository secrets:"
echo "   - SERVER_HOST"
echo "   - SERVER_USERNAME"
echo "   - SERVER_SSH_KEY"
echo "   - DEPLOY_PATH=/opt/zettanote"
echo ""
echo "5. Install MongoDB if not already installed"
echo ""
echo "6. Push to your repository to trigger the first deployment!"
echo ""
log_info "For detailed instructions, see DEPLOYMENT.md"
