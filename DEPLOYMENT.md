# ZettaNote Deployment Guide

This guide explains how to set up the CI/CD pipeline for automatic deployment of ZettaNote.

## Architecture

The deployment system consists of:

1. **GitHub Actions** - Builds frontend and admin-portal, creates artifacts
2. **SSH Deployment** - Uploads artifacts to server and triggers deployment
3. **Systemd Services** - Runs backend, frontend, and admin-portal as services
4. **Nginx** - Reverse proxy for routing traffic

## Prerequisites

### On Your Server

1. **Install Required Software**

   ```bash
   # Update system
   sudo apt update && sudo apt upgrade -y

   # Install Node.js and pnpm
   curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
   sudo apt install -y nodejs
   sudo npm install -g pnpm serve

   # Install Nginx
   sudo apt install -y nginx

   # Install MongoDB (if not already installed)
   sudo apt install -y mongodb

   # Install Git
   sudo apt install -y git
   ```

2. **Create Directory Structure**

   ```bash
   sudo mkdir -p /opt/zettanote/{releases,current,backend,shared}
   sudo mkdir -p /var/log/zettanote
   sudo chown -R www-data:www-data /opt/zettanote
   sudo chown -R www-data:www-data /var/log/zettanote
   ```

3. **Create Environment File**

   ```bash
   sudo nano /opt/zettanote/shared/.env
   ```

   Add your environment variables:

   ```env
   PORT=5000
   DB=mongodb://localhost:27017/zettanote
   JWT_SECRET=your-super-secret-jwt-key-here
   NODE_ENV=production
   ```

4. **Copy Deployment Script**

   ```bash
   # Copy deploy.sh to server
   sudo cp deploy.sh /opt/zettanote/deploy.sh
   sudo chmod +x /opt/zettanote/deploy.sh
   ```

5. **Install Systemd Services**

   ```bash
   # Copy service files
   sudo cp systemd/*.service /etc/systemd/system/

   # Reload systemd
   sudo systemctl daemon-reload

   # Enable services to start on boot
   sudo systemctl enable zettanote-backend
   sudo systemctl enable zettanote-frontend
   sudo systemctl enable zettanote-admin
   ```

6. **Configure Nginx**

   ```bash
   # Copy nginx configuration
   sudo cp nginx/zettanote.conf /etc/nginx/sites-available/zettanote

   # Edit the file and replace 'your-domain.com' with your actual domain
   sudo nano /etc/nginx/sites-available/zettanote

   # Enable the site
   sudo ln -s /etc/nginx/sites-available/zettanote /etc/nginx/sites-enabled/

   # Test nginx configuration
   sudo nginx -t

   # Restart nginx
   sudo systemctl restart nginx
   ```

7. **Set Up SSH Access for GitHub Actions**

   ```bash
   # Generate SSH key for GitHub Actions (or use existing key)
   ssh-keygen -t ed25519 -C "github-actions@zettanote" -f ~/.ssh/github-actions

   # Add public key to authorized_keys
   cat ~/.ssh/github-actions.pub >> ~/.ssh/authorized_keys

   # Save the private key for GitHub secrets
   cat ~/.ssh/github-actions
   ```

## GitHub Setup

### Configure Repository Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions → New repository secret

Add the following secrets:

| Secret Name       | Description              | Example                              |
| ----------------- | ------------------------ | ------------------------------------ |
| `SERVER_HOST`     | Your server IP or domain | `123.456.789.0`                      |
| `SERVER_USERNAME` | SSH username             | `root` or your username              |
| `SERVER_SSH_KEY`  | Private SSH key          | Content from `~/.ssh/github-actions` |
| `SERVER_PORT`     | SSH port (optional)      | `22`                                 |
| `DEPLOY_PATH`     | Deployment directory     | `/opt/zettanote`                     |

### Update Deploy Script

Edit `deploy.sh` and replace `<YOUR_REPO_URL>` with your actual repository URL:

```bash
git clone --branch ${BRANCH:-main} https://github.com/MannuVilasara/ZettaNote.git .
```

## Usage

### Automatic Deployment

1. **Push to main or dev branch** - Automatically triggers build and deployment

   ```bash
   git push origin main
   ```

2. **Manual Trigger** - Use GitHub Actions UI to manually trigger deployment
   - Go to Actions tab
   - Select "Build and Deploy" workflow
   - Click "Run workflow"

### Manual Deployment

If you need to deploy manually:

```bash
# SSH into your server
ssh user@your-server

# Navigate to deployment directory
cd /opt/zettanote

# Run deployment script
sudo ./deploy.sh RELEASE_NUMBER COMMIT_SHA
```

## Service Management

### Check Service Status

```bash
sudo systemctl status zettanote-backend
sudo systemctl status zettanote-frontend
sudo systemctl status zettanote-admin
```

### View Logs

```bash
# Backend logs
sudo tail -f /var/log/zettanote/backend.log

# Frontend logs
sudo tail -f /var/log/zettanote/frontend.log

# Admin portal logs
sudo tail -f /var/log/zettanote/admin.log
```

### Restart Services

```bash
sudo systemctl restart zettanote-backend
sudo systemctl restart zettanote-frontend
sudo systemctl restart zettanote-admin
```

### Stop Services

```bash
sudo systemctl stop zettanote-backend
sudo systemctl stop zettanote-frontend
sudo systemctl stop zettanote-admin
```

## SSL/HTTPS Setup (Recommended)

1. **Install Certbot**

   ```bash
   sudo apt install -y certbot python3-certbot-nginx
   ```

2. **Obtain SSL Certificate**

   ```bash
   sudo certbot --nginx -d your-domain.com -d www.your-domain.com
   sudo certbot --nginx -d admin.your-domain.com
   ```

3. **Enable HTTPS in Nginx Config**
   - Edit `/etc/nginx/sites-available/zettanote`
   - Uncomment the HTTPS server blocks
   - Update domain names
   - Restart nginx: `sudo systemctl restart nginx`

## Rollback

If a deployment fails, you can rollback to a previous release:

```bash
# List available releases
ls -la /opt/zettanote/releases/

# Rollback to a specific release
sudo ln -snf /opt/zettanote/releases/PREVIOUS_RELEASE_NUMBER/frontend /opt/zettanote/current/frontend
sudo ln -snf /opt/zettanote/releases/PREVIOUS_RELEASE_NUMBER/admin-portal /opt/zettanote/current/admin-portal

# Restart services
sudo systemctl restart zettanote-frontend
sudo systemctl restart zettanote-admin
```

## Troubleshooting

### Build Fails

- Check GitHub Actions logs for errors
- Verify Node.js version compatibility
- Check for missing dependencies

### Deployment Fails

- Verify SSH connection: `ssh -i ~/.ssh/github-actions user@server`
- Check deployment script permissions: `ls -la /opt/zettanote/deploy.sh`
- Review deployment script logs

### Services Not Starting

- Check service logs: `journalctl -u zettanote-backend -n 50`
- Verify environment variables: `cat /opt/zettanote/shared/.env`
- Check port conflicts: `sudo netstat -tulpn | grep -E ':(3000|3001|5000)'`

### Nginx Issues

- Test config: `sudo nginx -t`
- Check error logs: `sudo tail -f /var/log/nginx/error.log`
- Verify upstream services are running

## Monitoring

### Check Deployment History

```bash
ls -lt /opt/zettanote/releases/
cat /opt/zettanote/releases/RELEASE_NUMBER/deployment-info.txt
```

### Monitor Resource Usage

```bash
# Check memory usage
free -h

# Check disk usage
df -h

# Check running processes
htop
```

## Security Considerations

1. **Keep secrets secure** - Never commit `.env` files or secrets to Git
2. **Use strong JWT secrets** - Generate with `openssl rand -base64 32`
3. **Enable firewall** - Only allow necessary ports (22, 80, 443)
4. **Regular updates** - Keep system and dependencies updated
5. **Use HTTPS** - Always use SSL/TLS in production
6. **Restrict SSH** - Use key-based authentication only

## Support

For issues or questions:

- Check logs first
- Review GitHub Actions workflow runs
- Verify server configuration
- Check service status and logs
