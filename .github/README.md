# GitHub Actions Configuration

## Setup GitHub Secrets

Для работы GitHub Actions необходимо настроить следующие секреты в разделе `Settings → Secrets and variables → Actions`:

### Required Secrets

```
VPS_HOST=your.vps.ip.address
VPS_USER=deploy_user
VPS_SSH_KEY=-----BEGIN OPENSSH PRIVATE KEY-----
...your private key...
-----END OPENSSH PRIVATE KEY-----
VPS_PORT=22
BOT_TOKEN=your_telegram_bot_token_from_botfather
DB_PASSWORD=secure_database_password_for_production
```

### Optional Environment Variables

В разделе `Variables` можно настроить:

```
APP_URL=https://your-domain.com (for environment URL)
```

## SSH Key Setup

1. **Создайте SSH ключ для деплоя:**

```bash
ssh-keygen -t ed25519 -C "github-actions@hello-bot" -f ~/.ssh/hello_bot_deploy
```

2. **Скопируйте публичный ключ на VPS:**

```bash
ssh-copy-id -i ~/.ssh/hello_bot_deploy.pub user@your-vps-ip
```

3. **Добавьте приватный ключ в GitHub Secrets:**

```bash
cat ~/.ssh/hello_bot_deploy
# Скопируйте весь вывод в VPS_SSH_KEY secret
```

## VPS Preparation

### 1. Install Docker & Docker Compose

```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt-get update
sudo apt-get install docker-compose-plugin
```

### 2. Create deployment user

```bash
sudo useradd -m -s /bin/bash deploy
sudo usermod -aG docker deploy
sudo mkdir -p /opt/hello-bot
sudo chown deploy:deploy /opt/hello-bot
```

### 3. Test deployment script

```bash
# Upload and run VPS analysis script
scp scripts/test_log_vps.sh user@your-vps:/tmp/
ssh user@your-vps
chmod +x /tmp/test_log_vps.sh
./tmp/test_log_vps.sh
```

## Workflow Features

### 🔄 Automatic Deployment

- Triggered on push to `main` branch
- Manual deployment via workflow_dispatch
- Environment selection (production/staging)

### ✅ Quality Checks

- Code linting with ruff
- Docker configuration validation
- Multi-stage security scanning

### 🐳 Docker Optimization

- Multi-stage builds for smaller images
- GitHub Actions cache for faster builds
- Automatic cleanup of old images

### 🚀 Zero-Downtime Deployment

- Graceful service shutdown
- Health checks before completion
- Automatic rollback on failure

### 📊 Monitoring

- Deployment status verification
- Service health checks
- Comprehensive logging

## Manual Deployment

For manual deployment without GitHub Actions:

```bash
# 1. Copy files to VPS
scp -r . user@your-vps:/opt/hello-bot/

# 2. Run deployment script
ssh user@your-vps
cd /opt/hello-bot
./scripts/deploy.sh production
```

## Troubleshooting

### Common Issues

1. **Permission denied (publickey)**

   - Check SSH key is correctly added to VPS
   - Verify VPS_SSH_KEY secret is complete private key

2. **Docker permission denied**

   - Add deployment user to docker group
   - Restart SSH session after adding to group

3. **Services fail to start**

   - Check logs: `docker compose logs`
   - Verify environment variables
   - Check resource usage on VPS

4. **Health checks fail**
   - Increase timeout values
   - Check network connectivity
   - Verify BOT_TOKEN is valid

### Debugging Commands

```bash
# On VPS
cd /opt/hello-bot

# Check service status
docker compose ps

# View logs
docker compose logs -f

# Check resource usage
docker stats

# Test bot manually
docker compose exec bot python -c "from app.config import settings; print(settings.bot_token[:10] + '...')"
```
