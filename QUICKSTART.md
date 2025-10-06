# Quick Start - CI/CD Setup

This guide will get your CI/CD pipeline up and running in minutes.

## 🚀 Quick Setup (5 minutes)

### 1. On Your Server

Run the automated setup script:

```bash
# Clone your repository
git clone https://github.com/MannuVilasara/ZettaNote.git
cd ZettaNote

# Run setup script
sudo ./setup-server.sh
```

Follow the on-screen instructions.

### 2. Configure Environment

```bash
# Copy and edit environment file
sudo cp /opt/zettanote/shared/.env.example /opt/zettanote/shared/.env
sudo nano /opt/zettanote/shared/.env
```

Update these values:

- `JWT_SECRET`: Use the suggested secret from setup script
- `DB`: Your MongoDB connection string
- `PORT`: Backend port (default: 5000)

### 3. Set Up SSH for GitHub Actions

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "github-actions@zettanote" -f ~/.ssh/github-actions

# Add to authorized keys
cat ~/.ssh/github-actions.pub >> ~/.ssh/authorized_keys

# Display private key (copy this for GitHub)
cat ~/.ssh/github-actions
```

### 4. Configure GitHub Secrets

Go to: Repository → Settings → Secrets and variables → Actions

Add these secrets:

| Name              | Value                                   |
| ----------------- | --------------------------------------- |
| `SERVER_HOST`     | Your server IP (e.g., `123.45.67.89`)   |
| `SERVER_USERNAME` | SSH username (e.g., `root` or `ubuntu`) |
| `SERVER_SSH_KEY`  | Content from `~/.ssh/github-actions`    |
| `DEPLOY_PATH`     | `/opt/zettanote`                        |

### 5. Configure Nginx

```bash
# Edit nginx config
sudo nano /etc/nginx/sites-available/zettanote

# Replace 'your-domain.com' with your actual domain
# Then enable the site
sudo ln -s /etc/nginx/sites-available/zettanote /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### 6. Deploy!

```bash
# Push to main branch to trigger deployment
git push origin main
```

Watch the deployment in GitHub Actions tab! 🎉

## 📋 What Gets Deployed

- **Frontend**: React app on port 3000
- **Admin Portal**: React app on port 3001
- **Backend**: Node.js API on port 5000
- **Nginx**: Reverse proxy routing traffic

## 🔧 Common Commands

```bash
# Check service status
sudo systemctl status zettanote-backend
sudo systemctl status zettanote-frontend
sudo systemctl status zettanote-admin

# View logs
sudo tail -f /var/log/zettanote/backend.log

# Restart services
sudo systemctl restart zettanote-backend
sudo systemctl restart zettanote-frontend
sudo systemctl restart zettanote-admin

# Manual deployment
cd /opt/zettanote
sudo ./deploy.sh 1 manual
```

## 🐛 Troubleshooting

**Services not starting?**

```bash
# Check logs
journalctl -u zettanote-backend -n 50
journalctl -u zettanote-frontend -n 50
```

**Port conflicts?**

```bash
# Check what's using ports
sudo netstat -tulpn | grep -E ':(3000|3001|5000)'
```

**Nginx issues?**

```bash
# Test config
sudo nginx -t

# Check logs
sudo tail -f /var/log/nginx/error.log
```

## 📚 Full Documentation

For detailed information, see:

- [DEPLOYMENT.md](./DEPLOYMENT.md) - Complete deployment guide
- [.github/workflows/README.md](./.github/workflows/README.md) - Workflow details

## 🔒 Security Checklist

- [ ] Strong JWT secret configured
- [ ] MongoDB secured with authentication
- [ ] Firewall configured (ports 22, 80, 443 only)
- [ ] SSH key-based authentication only
- [ ] SSL/HTTPS configured (use `certbot`)
- [ ] Environment variables not committed to Git
- [ ] Regular system updates scheduled

## 🎯 Architecture Overview

```
GitHub Push
    ↓
GitHub Actions
    ├── Build Frontend → Artifact
    ├── Build Admin Portal → Artifact
    └── Deploy Job
        ├── Upload artifacts via SCP
        └── Trigger deploy.sh via SSH
            ↓
Server (deploy.sh)
    ├── Update symlinks
    ├── Pull backend code
    ├── Install dependencies
    └── Restart services
        ↓
Systemd Services
    ├── zettanote-backend (port 5000)
    ├── zettanote-frontend (port 3000)
    └── zettanote-admin (port 3001)
        ↓
Nginx (Reverse Proxy)
    ├── domain.com → Frontend
    ├── domain.com/api → Backend
    └── admin.domain.com → Admin Portal
```

## 🆘 Need Help?

1. Check logs first (`/var/log/zettanote/`)
2. Verify GitHub Actions workflow runs
3. Review systemd service status
4. Check nginx configuration
5. Verify environment variables
