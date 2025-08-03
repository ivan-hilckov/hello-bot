# Hello Bot - Deployment Guide

Complete step-by-step guide for deploying Hello Bot to your VPS using GitHub Actions.

## Prerequisites

- VPS server with Ubuntu 20.04+ or similar Linux distribution
- SSH access to your VPS
- GitHub repository with Hello Bot code
- Telegram Bot Token from [@BotFather](https://t.me/botfather)

## Step 1: Prepare Your VPS

### 1.1 Test VPS Readiness

Copy and run the readiness test script on your VPS:

```bash
# Copy script to VPS
scp scripts/test_vps.sh your-user@your-vps-ip:~/

# SSH to VPS and run test
ssh your-user@your-vps-ip
chmod +x test_vps.sh
./test_vps.sh
```

The script should show "VPS IS READY" or "VPS IS MOSTLY READY". If it shows "VPS NEEDS CONFIGURATION", fix the issues first.

### 1.2 Generate SSH Key for GitHub Actions

On your local machine:

```bash
# Generate deployment key
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/hello-bot-deploy

# Copy public key to VPS
ssh-copy-id -i ~/.ssh/hello-bot-deploy.pub your-user@your-vps-ip

# Test connection
ssh -i ~/.ssh/hello-bot-deploy your-user@your-vps-ip
```

## Step 2: Configure GitHub Secrets

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions**

Add these secrets:

| Secret        | Value                 | Example                             |
| ------------- | --------------------- | ----------------------------------- |
| `VPS_HOST`    | Your VPS IP or domain | `203.0.113.1`                       |
| `VPS_USER`    | SSH username          | `ubuntu`                            |
| `VPS_SSH_KEY` | Private key content   | Copy from `~/.ssh/hello-bot-deploy` |
| `VPS_PORT`    | SSH port (optional)   | `22`                                |
| `BOT_TOKEN`   | Telegram bot token    | From @BotFather                     |
| `DB_PASSWORD` | Database password     | Strong random password              |

### How to copy private key:

```bash
# Display private key content
cat ~/.ssh/hello-bot-deploy

# Copy the entire output including:
# -----BEGIN OPENSSH PRIVATE KEY-----
# ... key content ...
# -----END OPENSSH PRIVATE KEY-----
```

## Step 3: Deploy

### 3.1 Trigger Deployment

Push any change to the `main` branch:

```bash
git add .
git commit -m "Deploy Hello Bot"
git push origin main
```

### 3.2 Monitor Deployment

1. Go to **Actions** tab in your GitHub repository
2. Click on the latest workflow run
3. Monitor the progress through these stages:
   - Test & Lint
   - Build & Push Image
   - Deploy to VPS

### 3.3 Verify Deployment

After successful deployment, verify on your VPS:

```bash
ssh your-user@your-vps-ip
cd /opt/hello-bot

# Check services status
docker compose ps

# Check bot logs
docker compose logs bot

# Test bot health
docker compose exec bot python -c "from app.config import settings; print('Bot is healthy')"
```

## Step 4: Test Your Bot

1. Open Telegram
2. Find your bot by username
3. Send `/start` command
4. Bot should respond with "Hi 👋"

## Troubleshooting

### Deployment Failed

Check GitHub Actions logs for specific errors:

```bash
# Common issues and solutions:

# SSH connection failed
- Verify VPS_HOST, VPS_USER, VPS_SSH_KEY
- Test SSH connection manually

# Docker issues
- Ensure Docker is running on VPS
- Check VPS has enough resources

# Bot not responding
- Verify BOT_TOKEN is correct
- Check bot logs: docker compose logs bot
```

### VPS Issues

```bash
# Check services on VPS
docker compose ps
docker compose logs

# Check system resources
df -h        # Disk space
free -h      # RAM usage
docker stats # Container resources

# Restart services if needed
docker compose down
docker compose up -d
```

### Database Issues

```bash
# Check database connection
docker compose exec postgres psql -U hello_user -d hello_bot

# Check database logs
docker compose logs postgres

# Reset database (WARNING: deletes all data)
docker compose down
docker volume rm hello_bot_postgres_data
docker compose up -d
```

## Manual Deployment (Alternative)

If GitHub Actions fails, you can deploy manually:

```bash
# On your VPS
cd /opt/hello-bot

# Create .env file
cat > .env << EOF
BOT_TOKEN=your_bot_token_here
DB_PASSWORD=your_secure_password
ENVIRONMENT=production
DEBUG=false
LOG_LEVEL=INFO
EOF

# Pull and start services
docker compose pull
docker compose up -d
```

## Security Recommendations

After successful deployment:

1. **Enable firewall**:

   ```bash
   sudo ufw allow ssh
   sudo ufw enable
   ```

2. **Install fail2ban**:

   ```bash
   sudo apt update
   sudo apt install fail2ban
   ```

3. **Regular updates**:

   ```bash
   sudo apt update && sudo apt upgrade
   ```

4. **Monitor logs**:
   ```bash
   docker compose logs --tail=100 -f
   ```

## Next Steps

- Set up monitoring and alerting
- Configure webhook for better performance (optional)
- Set up automated backups
- Add more bot features

## Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review GitHub Actions logs
3. Verify all secrets are correctly configured
4. Test VPS readiness with `test_vps.sh`

Remember: The deployment script creates everything automatically, including directories, services, and configurations.
