# Production Deployment Guide

Deploy simplified Hello Bot to VPS with automated CI/CD via GitHub Actions.

## Prerequisites

- **Ubuntu 22.04+ VPS** with 1GB+ RAM (optimized with shared PostgreSQL)
- **GitHub repository** with Actions enabled
- **Telegram Bot Token** from [@BotFather](https://t.me/botfather)
- **Domain name** (optional, for webhook mode)

### Resource Efficiency (v2.1.0+)

With shared PostgreSQL architecture:
- **Single Bot**: ~640MB total (512MB PostgreSQL + 128MB app)
- **3 Bots**: ~896MB total (512MB shared PostgreSQL + 384MB apps)  
- **5 Bots**: ~1.15GB total (512MB shared PostgreSQL + 640MB apps)

Previous individual PostgreSQL approach required 400-600MB per bot.

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
mkdir -p $HOME/hello-bot

# Logout and login again for Docker group to take effect
```

**Test VPS readiness**:
```bash
# Download and run simplified VPS check
curl -fsSL https://raw.githubusercontent.com/your-repo/hello-bot/main/scripts/check_vps_simple.sh -o check_vps.sh
chmod +x check_vps.sh
./check_vps.sh
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
POSTGRES_ADMIN_PASSWORD=shared_postgres_admin_password  # NEW for v2.1.0+
```

**Optional Secrets** (for webhook mode):

```
WEBHOOK_URL=https://yourdomain.com/webhook
WEBHOOK_SECRET_TOKEN=random_webhook_secret
```

**Docker Hub Secrets** (for custom images):

```
DOCKERHUB_USERNAME=your_dockerhub_username
DOCKERHUB_TOKEN=your_dockerhub_access_token
```

### 3. Deploy

**Push to main branch**:

```bash
git add .
git commit -m "Deploy simplified bot"
git push origin main
```

**GitHub Actions will automatically**:

1. ✅ Build Docker image
2. ✅ Run simple tests
3. ✅ Deploy to VPS
4. ✅ Run database migrations
5. ✅ Start bot services
6. ✅ Verify basic health

**Deployment time**: ~2-3 minutes

## Verification

### Basic Health Check

```bash
# SSH to VPS
ssh user@your-vps-ip

# Check services
cd $HOME/hello-bot
docker compose --profile production ps

# Check logs
docker compose --profile production logs -f bot

# Test bot
# Send /start to your bot → should respond with greeting
```

### Database Verification

```bash
# Check user creation
docker compose exec postgres psql -U hello_user -d hello_bot -c "
SELECT telegram_id, username, first_name, created_at
FROM users
ORDER BY created_at DESC
LIMIT 5;
"

# Count users
docker compose exec postgres psql -U hello_user -d hello_bot -c "
SELECT COUNT(*) as total_users FROM users;
"
```

### Performance Check

```bash
# Resource usage
free -h
df -h
docker stats --no-stream

# Application logs
docker compose logs bot --tail=20
docker compose logs postgres --tail=10
```

## Configuration

### Environment Variables

**Production `.env` (auto-generated)**:

```env
# Bot configuration
BOT_TOKEN=from_github_secrets
ENVIRONMENT=production
DEBUG=false

# Database
DATABASE_URL=postgresql+asyncpg://hello_user:password@postgres:5432/hello_bot
DB_PASSWORD=from_github_secrets

# Optional webhook
WEBHOOK_URL=https://yourdomain.com/webhook
```

### Docker Compose

**Simple production stack**:

```yaml
services:
  postgres:
    image: postgres:15-alpine
    restart: unless-stopped
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: hello_bot
      POSTGRES_USER: hello_user
      POSTGRES_PASSWORD: ${DB_PASSWORD}

  bot:
    build: .
    restart: unless-stopped
    depends_on:
      - postgres
    environment:
      BOT_TOKEN: ${BOT_TOKEN}
      DATABASE_URL: postgresql+asyncpg://hello_user:${DB_PASSWORD}@postgres:5432/hello_bot
      ENVIRONMENT: production
      WEBHOOK_URL: ${WEBHOOK_URL:-}

volumes:
  postgres_data:
```

## Webhook Setup (Optional)

### Nginx Configuration

```bash
# Install Nginx
sudo apt install nginx

# Create config
sudo nano /etc/nginx/sites-available/hello-bot
```

**Nginx config**:

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

**Enable and restart**:

```bash
sudo ln -s /etc/nginx/sites-available/hello-bot /etc/nginx/sites-enabled/
sudo systemctl restart nginx
```

### SSL with Let's Encrypt

```bash
# Install certbot
sudo apt install certbot python3-certbot-nginx

# Get certificate
sudo certbot --nginx -d yourdomain.com

# Auto-renewal
sudo systemctl enable certbot.timer
```

## Monitoring

### Simple Monitoring

```bash
# Check if bot is running
docker compose ps | grep bot

# Check recent logs
docker compose logs bot --tail=50 --since=1h

# Check database connectivity
docker compose exec postgres pg_isready -U hello_user -d hello_bot

# Resource usage
docker stats --no-stream | grep hello-bot
```

### Log Analysis

```bash
# Error logs
docker compose logs bot | grep ERROR

# User activity
docker compose logs bot | grep "Created new user\|Updated user"

# Database queries (if DEBUG=true)
docker compose logs bot | grep "SELECT\|INSERT\|UPDATE"
```

## Troubleshooting

### Bot Not Responding

```bash
# Check bot status
docker compose ps

# Check logs for errors
docker compose logs bot | tail -50

# Restart bot
docker compose restart bot

# Check bot token
curl https://api.telegram.org/bot$BOT_TOKEN/getMe
```

### Database Issues

```bash
# Check database status
docker compose exec postgres pg_isready

# Check connections
docker compose exec postgres psql -U hello_user -d hello_bot -c "
SELECT count(*) FROM pg_stat_activity;
"

# Reset database (DESTRUCTIVE)
docker compose down -v
docker compose up -d
```

### Deployment Failures

```bash
# Check GitHub Actions logs
# Go to repository → Actions → failed workflow

# Manual deploy
ssh user@vps
cd $HOME/hello-bot
git pull origin main
docker compose build --no-cache
docker compose up -d
```

### Resource Issues

```bash
# Check disk space
df -h

# Check memory
free -h

# Check Docker resources
docker system df
docker system prune -f

# Optimize containers
docker compose down
docker system prune -a -f
docker compose up -d
```

## Performance Optimization

### Database Optimization

```sql
-- Check index usage
SELECT indexname, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
WHERE relname = 'users';

-- Analyze tables
ANALYZE users;

-- Check table sizes
SELECT
    tablename,
    pg_size_pretty(pg_total_relation_size(tablename::regclass)) as size
FROM pg_tables
WHERE schemaname = 'public';
```

### Container Optimization

```bash
# Optimize Docker images
docker image prune -f

# Check container resources
docker stats

# Restart containers
docker compose restart
```

## Backup and Recovery

### Database Backup

```bash
# Create backup
docker compose exec postgres pg_dump -U hello_user hello_bot > backup_$(date +%Y%m%d).sql

# Restore backup
docker compose exec -i postgres psql -U hello_user hello_bot < backup_20240103.sql
```

### Full System Backup

```bash
# Backup docker-compose and data
tar -czf hello-bot-backup_$(date +%Y%m%d).tar.gz \
  $HOME/hello-bot/docker-compose.yml \
  $HOME/hello-bot/.env

# Backup database data
docker run --rm -v hello-bot_postgres_data:/data -v $(pwd):/backup \
  alpine tar czf /backup/postgres_data_$(date +%Y%m%d).tar.gz /data
```

## Security

### Basic Security

```bash
# Update system regularly
sudo apt update && sudo apt upgrade -y

# Configure firewall
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable

# Secure Docker daemon
sudo systemctl enable docker
```

### Environment Security

```bash
# Secure .env file
chmod 600 $HOME/hello-bot/.env

# Check for sensitive data in logs
docker compose logs bot | grep -i "token\|password\|secret"
```

## Scaling Considerations

### When to Scale Up

Consider adding complexity when:

- **Daily active users > 1,000**
- **Response times > 1 second**
- **Memory usage > 80% consistently**
- **Need for caching or monitoring**

### Scaling Options

1. **Add Redis caching** for frequent database queries
2. **Add monitoring** with Prometheus/Grafana
3. **Add service layer** for complex business logic
4. **Scale database** with read replicas
5. **Load balancing** for multiple bot instances

## Conclusion

This simplified deployment approach provides:

- ✅ **Fast deployment** (2-3 minutes)
- ✅ **Low resource usage** (1GB+ RAM sufficient)
- ✅ **Simple monitoring** and troubleshooting
- ✅ **Easy maintenance** and updates
- ✅ **Reliable operations** for small to medium bots

Perfect for learning, prototyping, and production bots with <1,000 daily active users.
