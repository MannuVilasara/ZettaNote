# CI/CD Architecture - Artifact-Based Deployment

## Overview

ZettaNote uses a **modern artifact-based deployment** approach where all three components (frontend, admin-portal, and backend) are built on GitHub Actions runners and deployed as artifacts to the server.

## Why Artifact-Based Deployment?

### ✅ Advantages

1. **No Git on Server** - Server doesn't need Git access or credentials
2. **No Ownership Issues** - No Git permission conflicts
3. **Faster Deployments** - Pre-built artifacts, no compilation on server
4. **Consistent Deployments** - Exact same code that passed CI/CD
5. **Atomic Deployments** - All components deployed together
6. **Easy Rollback** - Keep previous releases, switch symlinks
7. **Resource Efficient** - Build happens on GitHub's infrastructure
8. **Version Control** - Each deployment tagged with build number

### ❌ vs Traditional Git Pull

| Aspect | Artifact-Based ✅ | Git Pull ❌ |
|--------|------------------|-------------|
| **Git Required** | No | Yes |
| **Build Location** | GitHub Actions | Server |
| **Server Resources** | Minimal | High (npm install, build) |
| **Deployment Speed** | Fast | Slow |
| **Ownership Issues** | None | Common |
| **Rollback** | Instant | Complex |
| **Security** | No repo access needed | SSH keys, credentials |

## Architecture Flow

```
┌─────────────────────────────────────────────────────────────┐
│                     GitHub Actions                           │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Job 1: build-frontend                                       │
│  ├─ Checkout code                                           │
│  ├─ Install dependencies (pnpm install)                     │
│  ├─- Build (pnpm run build)                                 │
│  └─ Upload artifact → frontend-build                        │
│                                                              │
│  Job 2: build-admin-portal                                   │
│  ├─ Checkout code                                           │
│  ├─ Install dependencies (pnpm install)                     │
│  ├─ Build (pnpm run build)                                  │
│  └─ Upload artifact → admin-portal-build                    │
│                                                              │
│  Job 3: prepare-backend                                      │
│  ├─ Checkout code                                           │
│  ├─ Install dependencies (pnpm install --production)        │
│  └─ Upload artifact → backend-build                         │
│                                                              │
│  Job 4: deploy                                               │
│  ├─ Download all artifacts                                  │
│  ├─ SCP upload to server → /releases/{BUILD_NUMBER}/       │
│  └─ SSH trigger → deploy.sh                                 │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│                    Server (/opt/zettanote)                   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  /releases/                                                  │
│  ├─ 1/                                                       │
│  │  ├─ frontend/    (React build)                           │
│  │  ├─ admin-portal/ (React build)                          │
│  │  └─ backend/     (Node.js with node_modules)            │
│  ├─ 2/                                                       │
│  ├─ 3/  ← Latest                                             │
│  └─ ...                                                      │
│                                                              │
│  /current/  (Symlinks to latest release)                     │
│  ├─ frontend → /releases/3/frontend                          │
│  ├─ admin-portal → /releases/3/admin-portal                  │
│  └─ backend → /releases/3/backend                            │
│                                                              │
│  /shared/                                                    │
│  └─ .env  (Environment variables)                            │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│                    Systemd Services                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  zettanote-backend.service                                   │
│  ├─ WorkingDirectory: /opt/zettanote/current/backend        │
│  ├─ User: www-data                                          │
│  └─ Exec: pnpm run prod                                      │
│                                                              │
│  zettanote-frontend.service                                  │
│  ├─ WorkingDirectory: /opt/zettanote/current/frontend       │
│  ├─ User: www-data                                          │
│  └─ Exec: serve -s . -l 3000                                │
│                                                              │
│  zettanote-admin.service                                     │
│  ├─ WorkingDirectory: /opt/zettanote/current/admin-portal   │
│  ├─ User: www-data                                          │
│  └─ Exec: serve -s . -l 3001                                │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│                         Nginx                                │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  domain.com → http://localhost:3000 (Frontend)               │
│  domain.com/api → http://localhost:5000 (Backend)            │
│  admin.domain.com → http://localhost:3001 (Admin)            │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Deployment Process

### 1. Build Phase (GitHub Actions)

```yaml
- Checkout code from repository
- Set up Node.js 20.x and pnpm
- Install dependencies for each component
- Build frontend and admin-portal (React apps)
- Package backend with dependencies
- Upload all as artifacts
```

### 2. Upload Phase (SCP)

```bash
artifacts/
├── frontend/
├── admin-portal/
└── backend/

↓ Upload via SCP to:

/opt/zettanote/releases/{BUILD_NUMBER}/
├── frontend/
├── admin-portal/
└── backend/
```

### 3. Deploy Phase (deploy.sh)

```bash
1. Verify all artifacts exist
2. Update symlinks:
   - /current/frontend → /releases/{BUILD_NUMBER}/frontend
   - /current/admin-portal → /releases/{BUILD_NUMBER}/admin-portal
   - /current/backend → /releases/{BUILD_NUMBER}/backend
3. Copy .env to backend if needed
4. Set proper ownership (www-data:www-data)
5. Restart all systemd services
6. Verify services are running
7. Clean up old releases (keep last 5)
```

## Zero-Downtime Deployment

The deployment achieves zero-downtime through **atomic symlink switching**:

1. New release uploaded to `/releases/{N}/`
2. Services still running from `/current/` (points to `/releases/{N-1}/`)
3. Symlinks updated atomically (instant operation)
4. Services restarted to use new code
5. Old release still available for rollback

## Rollback Procedure

Instant rollback to any of the last 5 releases:

```bash
# List available releases
ls -la /opt/zettanote/releases/

# Rollback to release 42
sudo ln -snf /opt/zettanote/releases/42/frontend /opt/zettanote/current/frontend
sudo ln -snf /opt/zettanote/releases/42/admin-portal /opt/zettanote/current/admin-portal
sudo ln -snf /opt/zettanote/releases/42/backend /opt/zettanote/current/backend

# Restart services
sudo systemctl restart zettanote-backend
sudo systemctl restart zettanote-frontend
sudo systemctl restart zettanote-admin
```

## Security Benefits

1. **No Repository Access** - Server doesn't need Git credentials
2. **No SSH Keys** - No deploy keys on server
3. **Read-Only Deployments** - Artifacts are immutable
4. **Minimal Attack Surface** - No Git client or credentials
5. **Audit Trail** - Each deployment tracked with build number

## Performance Benefits

1. **Fast Builds** - Parallel builds on GitHub's infrastructure
2. **Fast Uploads** - Pre-built artifacts, compressed transfer
3. **Fast Deployments** - Just copy files and restart services
4. **Low Server Load** - No compilation or dependency installation
5. **Predictable Time** - Consistent deployment duration

## Monitoring & Observability

Each release includes deployment information:

```bash
cat /opt/zettanote/releases/3/deployment-info.txt
```

Output:
```
Release: 3
Commit: 9afb814cbff3c2f4ea4dbe9aa8919592d4232b34
Date: Mon Oct 6 15:32:45 UTC 2025
```

## Comparison with Other Strategies

### vs Docker Containers
- ✅ Simpler setup, no Docker required
- ✅ Less resource overhead
- ✅ Easier debugging (direct file access)
- ❌ No container isolation

### vs Direct Git Deployment
- ✅ No Git issues
- ✅ Faster deployments
- ✅ Better rollback
- ✅ No build on server

### vs FTP/Manual Upload
- ✅ Automated
- ✅ Version controlled
- ✅ CI/CD integrated
- ✅ Rollback support

## Best Practices

1. **Always test locally** before pushing
2. **Monitor GitHub Actions** for build failures
3. **Check logs** after deployment
4. **Keep environment variables** in `/opt/zettanote/shared/.env`
5. **Regular backups** of database and environment files
6. **Monitor disk usage** (old releases accumulate)
7. **Use workflow_dispatch** for manual deployments when needed

---

This architecture provides a **robust, secure, and efficient** deployment pipeline for ZettaNote! 🚀
