# GitHub Actions Workflows

## Deploy Workflow

The `deploy.yml` workflow automates the build and deployment process for ZettaNote.

### Workflow Triggers

- **Push to main/dev branches**: Automatically builds and deploys
- **Manual trigger**: Use the "Run workflow" button in GitHub Actions

### Jobs

1. **build-frontend**
   - Builds the frontend React application
   - Creates production-ready build artifacts
   - Uploads artifacts for deployment

2. **build-admin-portal**
   - Builds the admin portal React application
   - Creates production-ready build artifacts
   - Uploads artifacts for deployment

3. **deploy**
   - Downloads built artifacts
   - Uploads artifacts to server via SCP
   - Triggers deployment script on server via SSH

### Required Secrets

Configure these in GitHub repository settings:

| Secret | Description |
|--------|-------------|
| `SERVER_HOST` | Server IP or domain |
| `SERVER_USERNAME` | SSH username |
| `SERVER_SSH_KEY` | Private SSH key for authentication |
| `SERVER_PORT` | SSH port (default: 22) |
| `DEPLOY_PATH` | Deployment directory on server |

### Customization

You can customize the workflow by:
- Changing Node.js version
- Adding tests before deployment
- Adding notifications (Slack, Discord, etc.)
- Configuring different deployment strategies per branch
