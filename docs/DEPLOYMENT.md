# Production Deployment Guide

Deploy Hello Bot to VPS with automated CI/CD via GitHub Actions.

## Prerequisites

- **Ubuntu 22.04+ VPS** with 2GB+ RAM
- **GitHub repository** with Actions enabled
- **Telegram Bot Token** from [@BotFather](https://t.me/botfather)
- **Domain name** (optional, for webhook mode)

## Quick Deployment

### 1. VPS Setup

**SSH to your VPS and run**:

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt install docker-compose-plugin

# Create deployment directory
sudo mkdir -p /opt/hello-bot
sudo chown $USER:$USER /opt/hello-bot

# Logout and login again for Docker group to take effect
```

### 2. GitHub Secrets

In GitHub repository → **Settings** → **Secrets and variables** → **Actions**:

**Required Secrets**:

```
VPS_HOST=your.vps.ip.address
VPS_USER=your-username
VPS_PORT=22
BOT_TOKEN=your_telegram_bot_token
DB_PASSWORD=secure_random_password_123
PROJECT_NAME=hello-bot
```

> **⚠️ Important**: `PROJECT_NAME` is now **required** and must match your project name. This creates unique Docker networks and container names.

**SSH Key Setup**:

```bash
# Generate SSH key for GitHub Actions
ssh-keygen -t ed25519 -C "github-actions" -f ~/.ssh/github_actions

# Copy public key to VPS
ssh-copy-id -i ~/.ssh/github_actions.pub your-user@your-vps-ip

# Copy private key content to GitHub secret VPS_SSH_KEY
cat ~/.ssh/github_actions
```

### 3. Deploy

**Automatic Deployment**:

```bash
# Push to main branch triggers deployment
git add .
git commit -m "Deploy to production"
git push origin main
```

**Manual Deployment**:

1. Go to GitHub → **Actions**
2. Select **"Deploy to VPS"** workflow
3. Click **"Run workflow"**
4. Choose **production** environment

## Deployment Process

### GitHub Actions Workflow

**What happens on `git push origin main`**:

1. **Build Stage** (~2 minutes):

   - Lint code with ruff
   - Build optimized Docker image
   - Push to GitHub Container Registry

2. **Deploy Stage** (~2-3 minutes):
   - SSH to VPS
   - Pull latest Docker image
   - Run migration and health checks
   - Start services with zero downtime

**Total Time**: ~4-5 minutes (optimized from previous 8-10 minutes)

### VPS Configuration

**Services on VPS**:

```yaml
postgres: # PostgreSQL database with optimized indexes
redis: # Redis cache with memory fallback
migration: # One-time database migration
bot: # Modern Telegram bot with full enterprise features
```

**Enterprise Features Deployed**:

- ✅ **Router Pattern**: Modern aiogram 3.0+ architecture
- ✅ **Service Layer**: Separated business logic with dependency injection
- ✅ **Redis Caching**: High-performance user data caching
- ✅ **Prometheus Metrics**: `/metrics` endpoint for monitoring
- ✅ **Enhanced Health Checks**: Database, Redis, Bot API monitoring
- ✅ **Structured Logging**: JSON logs for production
- ✅ **Rate Limiting**: Protection against abuse
- ✅ **Testing Suite**: 12 comprehensive tests

**Resource Allocation** (2GB VPS):

- **PostgreSQL**: 512MB memory limit (with optimized indexes)
- **Redis**: 128MB memory limit (caching layer)
- **Bot App**: 256MB memory limit (with Service Layer + DI)
- **System**: ~1GB for OS + Docker overhead

**Memory Usage Monitoring**:

- **Prometheus Metrics**: Real-time memory tracking via `/metrics`
- **Health Checks**: Memory usage included in `/health` endpoint
- **Structured Logging**: Memory consumption logged in JSON format

## Monitoring & Maintenance

### Check Deployment Status

```bash
# SSH to VPS
ssh your-user@your-vps-ip

# Check services
cd /opt/hello-bot
docker compose ps

# View logs
docker compose logs -f
docker compose logs bot --tail=50
```

### Enhanced Health Checks

**Comprehensive Automated Monitoring**:

- **PostgreSQL**: Database connectivity + query performance
- **Redis**: Cache connectivity with fallback testing
- **Bot API**: Telegram API connectivity via `getMe()`
- **Memory Usage**: Real-time memory consumption tracking
- **Response Time**: Request processing latency monitoring

**Health Check Endpoints**:

```bash
# Enhanced health check with full status
curl http://localhost:8000/health
# Response:
{
  "status": "healthy",
  "checks": {
    "database": "healthy",
    "redis": "healthy",
    "bot_api": "healthy",
    "memory_usage_mb": 245.6
  },
  "timestamp": 1703234567.89,
  "version": "1.1.0"
}

# Prometheus metrics
curl http://localhost:8000/metrics
# Returns metrics in Prometheus format
```

**Manual Verification**:

```bash
# Test bot functionality
# Send /start → should respond with greeting + user cached

# Check all services
docker compose ps
docker compose logs -f bot | grep "healthy"

# Check database with indexes
docker compose exec postgres psql -U hello_user -d hello_bot -c "
SELECT
  COUNT(*) as total_users,
  COUNT(*) FILTER (WHERE is_active = true) as active_users
FROM users;
"

# Check Redis cache
docker compose exec redis redis-cli ping
docker compose exec redis redis-cli info memory

# Resource monitoring
docker stats --no-stream
```

### Performance Monitoring

```bash
# Resource usage
free -h
df -h
docker stats

# Application logs
docker compose logs bot | grep ERROR
docker compose logs postgres | grep ERROR

# Database performance
docker compose exec postgres psql -U hello_user -d hello_bot -c "
SELECT count(*) as connections FROM pg_stat_activity;
"
```

## Configuration

### Environment Variables

**Production `.env` (auto-generated)**:

```env
# Bot configuration
BOT_TOKEN=from_github_secrets
PROJECT_NAME=hello-bot
ENVIRONMENT=production
DEBUG=false
LOG_LEVEL=INFO

# Database
DATABASE_URL=postgresql+asyncpg://hello_user:password@postgres:5432/hello_bot
DB_PASSWORD=from_github_secrets

# Performance optimization for 2GB VPS
DB_POOL_SIZE=3
DB_MAX_OVERFLOW=5
PYTHONOPTIMIZE=1
```

### Webhook Mode (Optional)

**For high-traffic bots**:

```env
WEBHOOK_URL=https://yourdomain.com/webhook
WEBHOOK_SECRET_TOKEN=random_secret_token
```

**Nginx Configuration** (if using webhook):

```nginx
server {
    listen 80;
    server_name yourdomain.com;

    location /webhook {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## Troubleshooting

### Common Issues

**Deployment Failed**:

```bash
# Check GitHub Actions logs
# Go to Actions tab → failed workflow → view logs

# Check VPS connectivity
ssh your-user@your-vps-ip "docker --version"
```

**Bot Not Responding**:

```bash
# Check bot logs
docker compose logs bot

# Verify bot token
docker compose exec bot env | grep BOT_TOKEN

# Test bot token
curl https://api.telegram.org/bot$BOT_TOKEN/getMe
```

**Database Issues**:

```bash
# Check PostgreSQL status
docker compose exec postgres pg_isready -U hello_user -d hello_bot

# View database logs
docker compose logs postgres

# Check migrations
docker compose exec bot alembic current
```

**Memory Issues**:

```bash
# Check memory usage
free -h
docker stats --no-stream

# Restart if needed
docker compose restart
```

### Recovery Procedures

**Rollback Deployment**:

```bash
# Automatic rollback via GitHub Actions
# Re-run previous successful workflow

# Manual rollback
cd /opt/hello-bot
docker compose down
# Restore previous version
docker compose up -d
```

**Database Recovery**:

```bash
# Restore from backup (if available)
docker compose exec -T postgres psql -U hello_user hello_bot < backup.sql

# Reset to clean state (DESTRUCTIVE)
docker compose down -v
docker compose up -d
```

## Optimization Features

### Performance Improvements

- **Parallel Deployment**: Multiple operations run simultaneously
- **Docker Caching**: Optimized layer caching reduces build time
- **Health Checks**: 5-second intervals for faster startup detection
- **Resource Limits**: Prevents memory exhaustion on 2GB VPS

### Deployment Speed

| Phase      | Time         | Optimizations                            |
| ---------- | ------------ | ---------------------------------------- |
| **Build**  | ~2 min       | Docker layer caching, multi-stage builds |
| **Deploy** | ~2-3 min     | Parallel operations, fast health checks  |
| **Total**  | **~4-5 min** | **70% improvement from 8-10 minutes**    |

## Security

### Implemented Security

- **SSH Key Authentication**: No password-based access
- **Environment Secrets**: Secure secrets management via GitHub
- **Non-root Containers**: Security-first containerization
- **Resource Limits**: Prevents resource-based attacks

### Recommended Additional Security

```bash
# Firewall setup
sudo ufw allow 22    # SSH
sudo ufw allow 80    # HTTP (if using webhook)
sudo ufw allow 443   # HTTPS (if using webhook)
sudo ufw enable

# Fail2ban for SSH protection
sudo apt install fail2ban
sudo systemctl enable fail2ban
```

## Backup & Recovery

### Automated Backups

**Database Backup**:

```bash
# Create backup script
docker compose exec postgres pg_dump -U hello_user hello_bot > backup_$(date +%Y%m%d).sql

# Restore from backup
docker compose exec -T postgres psql -U hello_user hello_bot < backup_20241222.sql
```

### Configuration Backup

```bash
# Backup deployment files
tar -czf hello-bot-config-$(date +%Y%m%d).tar.gz .env docker-compose.yml
```

## Scaling Considerations

### Current Limits (2GB VPS)

- **Concurrent Users**: ~100-200 active users
- **Messages/Second**: ~10-20 messages
- **Database**: ~10,000 user records

### Scaling Options

1. **Vertical Scaling**: Upgrade to 4GB/8GB VPS
2. **Horizontal Scaling**: Multiple bot instances with load balancer
3. **Database Scaling**: Separate database server
4. **CDN/Proxy**: Cloudflare for webhook endpoint

## Support

### Getting Help

1. **Check this documentation** for common issues
2. **Review GitHub Actions logs** for deployment failures
3. **Monitor VPS logs** for runtime issues
4. **Test locally first** before production deployment

### Useful Commands

```bash
# Quick status check
cd /opt/hello-bot && docker compose ps

# View recent logs
docker compose logs --tail=100 -f

# Restart all services
docker compose restart

# Update to latest version
docker compose pull && docker compose up -d

# Clean restart
docker compose down && docker compose up -d
```
