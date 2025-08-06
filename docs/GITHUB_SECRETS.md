# GitHub Secrets Configuration for Shared PostgreSQL

## Overview

With the new shared PostgreSQL architecture, one additional secret is required for automated deployment. This guide shows exactly which secrets to configure.

## Required GitHub Secrets

### Step 1: Access Repository Settings
1. Go to your GitHub repository
2. Click **Settings** tab
3. Navigate to **Secrets and variables** > **Actions**
4. Click **Repository secrets**

### Step 2: Verify Existing Secrets

Ensure these secrets are already configured:

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `DOCKERHUB_USERNAME` | Docker Hub username | `myusername` |
| `DOCKERHUB_TOKEN` | Docker Hub access token | `dckr_pat_abc123...` |
| `VPS_HOST` | VPS IP address | `192.168.1.100` |
| `VPS_USER` | VPS username | `root` |
| `VPS_SSH_KEY` | Private SSH key | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `VPS_PORT` | SSH port (optional) | `22` |
| `BOT_TOKEN` | Telegram bot token | `123456789:ABCdef...` |
| `DB_PASSWORD` | Database password | `secure_password_123` |
| `WEBHOOK_URL` | Webhook URL (optional) | `https://yourbot.com/webhook` |

### Step 3: Add New Secret for Shared PostgreSQL

**NEW SECRET REQUIRED:**

| Secret Name | Description | How to Generate |
|-------------|-------------|-----------------|
| `POSTGRES_ADMIN_PASSWORD` | Admin password for shared PostgreSQL | `openssl rand -base64 32` |

#### Generate Secure Password
```bash
# Run this command to generate a secure password
openssl rand -base64 32

# Example output:
# K7x9mP2qF4nR8sT1vY3wE6uI0oA5zC7bN9dX
```

#### Add the Secret
1. Click **"New repository secret"**
2. **Name**: `POSTGRES_ADMIN_PASSWORD`  
3. **Value**: Paste the generated password
4. Click **"Add secret"**

## Verification Checklist

Before deploying, verify all secrets are present:

- [ ] `DOCKERHUB_USERNAME` ✅
- [ ] `DOCKERHUB_TOKEN` ✅  
- [ ] `VPS_HOST` ✅
- [ ] `VPS_USER` ✅
- [ ] `VPS_SSH_KEY` ✅
- [ ] `BOT_TOKEN` ✅
- [ ] `DB_PASSWORD` ✅
- [ ] `POSTGRES_ADMIN_PASSWORD` ✅ **NEW**
- [ ] `WEBHOOK_URL` ✅ (optional)

## Deployment After Configuration

Once all secrets are configured:

1. **Commit and push** your code changes
2. **GitHub Actions will automatically**:
   - Test and build the image
   - Deploy to VPS with shared PostgreSQL
   - Create database for your bot automatically

## Troubleshooting

### Missing Secret Error
```
Error: Required secret POSTGRES_ADMIN_PASSWORD not found
```
**Solution**: Add the missing secret following Step 3 above.

### Authentication Failed
```
Error: password authentication failed for user "postgres"
```
**Solution**: Regenerate `POSTGRES_ADMIN_PASSWORD` with a new secure password.

### Deployment Script Fails
```
Error: ./scripts/manage_postgres.sh: Permission denied
```
**Solution**: This is handled automatically by the updated GitHub Actions workflow.

## Security Best Practices

1. **Use strong passwords** (32+ characters)
2. **Never expose secrets** in code or logs
3. **Rotate passwords** periodically for production
4. **Limit repository access** to trusted team members only

## Development vs Production

### Development (Local)
- Uses individual PostgreSQL container
- No shared PostgreSQL needed
- Hot reload enabled for code changes
- Use: `docker compose -f docker-compose.dev.yml up -d`

### Production (VPS)
- Uses shared PostgreSQL container
- Requires `POSTGRES_ADMIN_PASSWORD` secret
- Automatic deployment via GitHub Actions
- Database created automatically per bot

## Next Steps

After configuring secrets:
1. Push code to trigger automatic deployment
2. Monitor deployment logs in GitHub Actions
3. Verify bot functionality on your VPS
4. Check shared PostgreSQL resource usage

The shared PostgreSQL will be created automatically on first deployment and reused for subsequent bot deployments.