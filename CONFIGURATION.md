# Configuration Updates - Port 80 & Artifact-Based Backend

## Summary of Changes

### 1. Frontend Service - Port 80 Configuration

**File:** `systemd/zettanote-frontend.service`

**Changed from:**

- Port: 3000 (requires Nginx reverse proxy)
- User: www-data

**Changed to:**

- Port: 80 (direct access, no Nginx needed)
- User: root (required for ports < 1024)

**Benefits:**

- ✅ No Nginx required for basic setup
- ✅ Direct access on standard HTTP port
- ✅ Simpler architecture for small deployments
- ✅ Can still add Nginx later for SSL/caching

### 2. Backend Deployment - Artifact-Based

**File:** `deploy.sh` & `.github/workflows/deploy.yml`

**Changed from:**

- Clone backend from Git on server
- Run `pnpm install` on server
- Git ownership issues

**Changed to:**

- Backend uploaded as pre-built artifact
- Dependencies already installed in artifact
- No Git operations on server

**Benefits:**

- ✅ No Git ownership issues
- ✅ Faster deployments
- ✅ Consistent with frontend/admin-portal approach
- ✅ Exact commit deployed (no drift)

### 3. Setup Script Updates

**File:** `setup-server.sh`

**New behavior:**

- Stops and disables Nginx (frees port 80)
- Removes backend directory creation (comes as artifact)
- Updated firewall rules to include backend API port

## New Architecture

```
┌─────────────────────────────────────┐
│          Internet Traffic            │
└────────────┬────────────────────────┘
             │
             ↓
┌─────────────────────────────────────┐
│       Port 80 - Frontend             │
│   (serve command, root user)         │
│   /opt/zettanote/current/frontend    │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│     Port 3001 - Admin Portal         │
│   (serve command, www-data user)     │
│   /opt/zettanote/current/admin-portal│
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│      Port 5000 - Backend API         │
│   (node/pnpm, www-data user)         │
│   /opt/zettanote/current/backend     │
└─────────────────────────────────────┘
```

## Direct Access URLs

- **Frontend:** `http://your-server-ip/` or `http://your-domain.com/`
- **Admin Portal:** `http://your-server-ip:3001/` or `http://admin.your-domain.com/`
- **Backend API:** `http://your-server-ip:5000/api/` (used by frontends)

## Frontend Configuration

### Update Frontend API URL

Make sure your frontend (`frontend/src/config.js`) points to the correct backend:

```javascript
export const API_URL = process.env.REACT_APP_API_URL || 'http://your-server-ip:5000';
```

### Update Admin Portal API URL

Make sure your admin portal (`admin-portal/src/config.js`) points to the correct backend:

```javascript
export const API_URL = process.env.REACT_APP_API_URL || 'http://your-server-ip:5000';
```

## Firewall Configuration

After setup, configure your firewall:

```bash
# Allow necessary ports
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # Frontend (HTTP)
sudo ufw allow 443/tcp   # HTTPS (if you add SSL later)
sudo ufw allow 3001/tcp  # Admin Portal
sudo ufw allow 5000/tcp  # Backend API

# Enable firewall
sudo ufw enable
```

## Optional: Add Nginx Later

If you want to add Nginx for SSL/reverse proxy later:

1. **Change frontend service back to port 3000**
2. **Enable Nginx** and configure reverse proxy
3. **Add SSL** with Let's Encrypt

Edit `/etc/systemd/system/zettanote-frontend.service`:

```ini
[Service]
User=www-data
Group=www-data
ExecStart=/usr/bin/serve -s . -l 3000
```

Then reload and restart:

```bash
sudo systemctl daemon-reload
sudo systemctl restart zettanote-frontend
sudo systemctl enable nginx
sudo systemctl start nginx
```

## Deployment Workflow (Updated)

```
1. GitHub Actions
   ├─ Build frontend → artifact
   ├─ Build admin-portal → artifact
   └─ Prepare backend → artifact (with node_modules)
        ↓
2. Upload all artifacts to server
   /opt/zettanote/releases/{BUILD_NUMBER}/
   ├─ frontend/
   ├─ admin-portal/
   └─ backend/ (includes node_modules)
        ↓
3. Deploy script (deploy.sh)
   ├─ Verify all artifacts exist
   ├─ Update symlinks to new release
   ├─ Copy .env to backend
   ├─ Set ownership
   └─ Restart all services
        ↓
4. Services running
   ├─ Frontend on port 80
   ├─ Admin Portal on port 3001
   └─ Backend on port 5000
```

## Testing After Deployment

```bash
# Check all services are running
sudo systemctl status zettanote-backend
sudo systemctl status zettanote-frontend
sudo systemctl status zettanote-admin

# Test frontend (should return HTML)
curl http://localhost/

# Test admin portal (should return HTML)
curl http://localhost:3001/

# Test backend API (should return JSON)
curl http://localhost:5000/api/health
```

## Troubleshooting

### Port 80 Permission Denied

If you get permission errors on port 80:

```bash
# Check if service is running as root
sudo systemctl status zettanote-frontend

# Verify no other service is using port 80
sudo netstat -tulpn | grep :80
```

### Backend Not Starting

Check if dependencies are in the artifact:

```bash
# Verify node_modules exists
ls -la /opt/zettanote/current/backend/node_modules/

# Check backend logs
sudo tail -f /var/log/zettanote/backend.log
sudo tail -f /var/log/zettanote/backend-error.log
```

### Frontend Not Accessible

```bash
# Check if frontend service is running
sudo systemctl status zettanote-frontend

# Check logs
sudo tail -f /var/log/zettanote/frontend.log

# Verify files exist
ls -la /opt/zettanote/current/frontend/
```

## Security Considerations

### Running Frontend as Root

- ✅ Required for port 80
- ⚠️ Service is limited by systemd security settings
- ⚠️ NoNewPrivileges prevents privilege escalation
- ✅ Static file serving is low risk

### Alternative: Use Port 3000 + Nginx

For production, consider:

- Frontend on port 3000 (as www-data)
- Nginx on port 80/443 (as root)
- SSL/TLS termination at Nginx
- Better security isolation

## Migration from Git-Based Backend

If you have an existing deployment with Git-based backend:

```bash
# Remove old backend directory
sudo rm -rf /opt/zettanote/backend

# The new deployment will handle backend as artifact
# No manual steps needed
```

---

## Quick Reference

| Component    | Port | User     | Service File               |
| ------------ | ---- | -------- | -------------------------- |
| Frontend     | 80   | root     | zettanote-frontend.service |
| Admin Portal | 3001 | www-data | zettanote-admin.service    |
| Backend API  | 5000 | www-data | zettanote-backend.service  |

All components deployed as artifacts from GitHub Actions! 🚀
