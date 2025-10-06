# 🚀 CI/CD Deployment Setup

Automated deployment pipeline for ZettaNote using GitHub Actions.

## 📁 Files Created

```
.github/workflows/
  └── deploy.yml              # GitHub Actions workflow
  └── README.md              # Workflow documentation

systemd/
  ├── zettanote-backend.service   # Backend systemd service
  ├── zettanote-frontend.service  # Frontend systemd service
  └── zettanote-admin.service     # Admin portal systemd service

nginx/
  └── zettanote.conf         # Nginx reverse proxy config

deploy.sh                    # Main deployment script
setup-server.sh             # Server setup automation
DEPLOYMENT.md               # Complete deployment guide
QUICKSTART.md              # Quick start guide
```

## ⚡ Quick Start

1. **Set up your server:**

   ```bash
   sudo ./setup-server.sh
   ```

2. **Configure GitHub Secrets:**

   - `SERVER_HOST`
   - `SERVER_USERNAME`
   - `SERVER_SSH_KEY`
   - `DEPLOY_PATH`

3. **Push to trigger deployment:**
   ```bash
   git push origin main
   ```

See [QUICKSTART.md](./QUICKSTART.md) for detailed steps.

## 🏗️ Architecture

**GitHub Actions** → Build frontends → Create artifacts → Upload to server → Trigger deployment

**Server** → Download artifacts → Update symlinks → Restart services

**Services:**

- Backend (Node.js) on port 5000
- Frontend (React) on port 3000
- Admin Portal (React) on port 3001

**Nginx** → Routes traffic to appropriate service

## 📖 Documentation

- **[QUICKSTART.md](./QUICKSTART.md)** - Get started in 5 minutes
- **[DEPLOYMENT.md](./DEPLOYMENT.md)** - Complete deployment guide
- **[.github/workflows/README.md](./.github/workflows/README.md)** - Workflow details

## 🔧 Key Features

- ✅ Automated build and deployment
- ✅ Zero-downtime deployments with symlinks
- ✅ Artifact-based deployment (lightweight)
- ✅ Automatic service restarts
- ✅ Keep last 5 releases for rollback
- ✅ Systemd service management
- ✅ Nginx reverse proxy
- ✅ Production-ready setup

## 🔒 Security

- SSH key authentication
- Environment variables in separate file
- Systemd security settings
- Nginx SSL/TLS support ready

## 📊 Workflow

```yaml
on: push to main/dev
  ↓
Build frontend (React)
  ↓
Build admin-portal (React)
  ↓
Upload artifacts
  ↓
Deploy to server
  ↓
Services restart
```

## 🛠️ Customization

Edit `deploy.yml` to:

- Add tests before deployment
- Change build settings
- Add notifications
- Deploy to multiple servers
- Add staging environment

## 📝 Notes

- Frontend and admin-portal are built on GitHub runners (saves server resources)
- Backend is deployed directly from Git (no build needed for Node.js)
- Artifacts are kept for 7 days in GitHub
- Server keeps last 5 releases for quick rollback

## 🆘 Support

Check these if something goes wrong:

1. GitHub Actions logs
2. `/var/log/zettanote/*.log`
3. `journalctl -u zettanote-*`
4. `sudo systemctl status zettanote-*`

---

Created for easy deployment of ZettaNote applications! 🎉
