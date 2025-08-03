# Deployment Guide

Complete guide for deploying Hello Bot to production VPS with GitHub Actions.

## Prerequisites

- Ubuntu 22.04+ VPS with 2GB+ RAM
- Docker and Docker Compose
- GitHub repository with Actions enabled
- Telegram Bot Token from @BotFather

## 1. VPS Setup

### Automatic Setup (Recommended)

Run the automated setup script:

```bash
# Copy setup script to your VPS
scp scripts/setup_vps.sh user@your-vps-ip:/tmp/

# SSH to VPS and run setup
ssh user@your-vps-ip
chmod +x /tmp/setup_vps.sh
sudo /tmp/setup_vps.sh
```

### What the Script Does

- Installs Docker and Docker Compose
- Creates 2GB swap file (critical for 2GB RAM VPS)
- Sets up deployment user with proper permissions
- Configures firewall and fail2ban security
- Optimizes system for production workloads
- Creates systemd service for auto-restart

### Manual Setup

If you prefer manual control:

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt update
sudo apt install docker-compose-plugin

# Create deployment directory
sudo mkdir -p /opt/hello-bot
sudo chown $USER:$USER /opt/hello-bot
```

## 2. SSH Keys for GitHub Actions

Create dedicated SSH key for automated deployment:

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "github-actions@hello-bot" -f ~/.ssh/hello_bot_deploy

# Copy public key to VPS
ssh-copy-id -i ~/.ssh/hello_bot_deploy.pub deploy-user@your-vps-ip

# Test connection
ssh -i ~/.ssh/hello_bot_deploy deploy-user@your-vps-ip "docker --version"
```

## 3. GitHub Secrets Configuration

In your GitHub repository, go to Settings → Secrets and variables → Actions:

### Required Secrets

```
VPS_HOST=your.vps.ip.address
VPS_USER=deploy-user
VPS_PORT=22
BOT_TOKEN=your_telegram_bot_token_from_botfather
DB_PASSWORD=secure_database_password_123
```

### VPS_SSH_KEY Secret

Copy the entire private key:

```bash
cat ~/.ssh/hello_bot_deploy
```

Paste the complete output (including BEGIN/END lines) into the `VPS_SSH_KEY` secret.

## 4. Local Testing

Test your Docker configuration locally before deploying:

```bash
# Run automated local test
./scripts/test_local.sh

# Manual testing
cp .env.example .env
# Edit .env with your values
docker compose up -d
docker compose logs -f
```

## 5. Deployment

### Automatic Deployment

Push to `main` branch to trigger automatic deployment:

```bash
git add .
git commit -m "Deploy to production"
git push origin main
```

GitHub Actions will automatically:

1. Run tests and linting
2. Build Docker image
3. Deploy to VPS
4. Run health checks

### Manual Deployment

Trigger deployment manually:

1. Go to GitHub → Actions
2. Select "Deploy to VPS" workflow
3. Click "Run workflow"
4. Choose environment and run

## 6. Monitoring and Maintenance

### Check Deployment Status

```bash
# SSH to VPS
ssh deploy-user@your-vps-ip

# Check service status
cd /opt/hello-bot
docker compose ps
docker compose logs -f

# Run health check
./health_check.sh
```

### Useful Commands

```bash
# View logs
docker compose logs bot --tail=50 -f

# Restart services
docker compose restart

# Update to latest
docker compose pull
docker compose up -d

# Monitor resources
docker stats
free -h
```

## 7. Performance Optimization

### Memory Optimization

For 2GB RAM VPS:

- PostgreSQL: 512MB limit
- Bot application: 256MB limit
- Connection pool: 3 connections
- Automatic cleanup enabled

### Database Optimization

```bash
# Check database performance
docker compose exec postgres psql -U hello_user -d hello_bot

# Run maintenance
docker compose exec postgres psql -U hello_user -d hello_bot -c "VACUUM ANALYZE;"
```

## 8. Troubleshooting

### Common Issues

**Bot not starting:**

```bash
# Check environment variables
docker compose exec bot env | grep BOT_TOKEN

# Check logs
docker compose logs bot
```

**Database connection issues:**

```bash
# Test database connection
docker compose exec postgres pg_isready -U hello_user -d hello_bot

# Check migrations
docker compose exec bot alembic current
```

**Memory issues:**

```bash
# Check memory usage
free -h
docker stats --no-stream

# Restart if needed
docker compose restart
```

### Log Analysis

```bash
# Application logs
docker compose logs bot | grep ERROR

# System logs
journalctl -u docker
dmesg | grep -i memory
```

## 9. Security

### Implemented Security Measures

- fail2ban for SSH protection
- UFW firewall configured
- Non-root Docker containers
- Resource limits enforced
- Secrets management via GitHub
- Automated security updates

### Security Monitoring

```bash
# Check failed login attempts
sudo fail2ban-client status sshd

# Firewall status
sudo ufw status

# System security updates
sudo apt list --upgradable
```

## 10. Backup and Recovery

### Database Backup

```bash
# Create backup
docker compose exec postgres pg_dump -U hello_user hello_bot > backup_$(date +%Y%m%d).sql

# Restore backup
docker compose exec -T postgres psql -U hello_user hello_bot < backup_20241222.sql
```

### Configuration Backup

```bash
# Backup environment and compose files
tar -czf hello-bot-config-$(date +%Y%m%d).tar.gz .env docker-compose.yml
```

## Success Metrics

### Expected Performance

- **Startup time**: <30 seconds
- **Memory usage**: 800MB-1.2GB (of 2GB)
- **Response time**: <500ms for commands
- **Uptime**: 99.9%+

### Health Checks

- Bot responds to `/start` command
- Database accepts connections
- Docker containers healthy
- System resources within limits

---

**Deployment completed successfully when all health checks pass and bot responds to Telegram commands.**
