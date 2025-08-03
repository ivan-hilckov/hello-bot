# Quick Start Guide

Get Hello Bot running in 5 minutes with Docker.

## Problem: Bot Not Starting?

**Common Cause**: Missing or invalid `BOT_TOKEN` in `.env` file

## Solution: 3 Simple Steps

### 1. Get Bot Token from @BotFather

1. Open Telegram
2. Find [@BotFather](https://t.me/botfather)
3. Send `/newbot` command
4. Follow instructions:
   - Enter bot name (e.g., "My Test Bot")
   - Enter username (e.g., "my_test_bot_123")
5. Copy your token: `1234567890:ABCdefGHIjklMNOpqrsTUVwxyz`

### 2. Configure Environment

```bash
# Copy example file
cp .env.example .env

# Edit .env file
nano .env
```

Replace this line:

```env
BOT_TOKEN=your_telegram_bot_token_here
```

With your real token:

```env
BOT_TOKEN=1234567890:ABCdefGHIjklMNOpqrsTUVwxyz
```

### 3. Start the Bot

```bash
# Start with Docker
docker compose up -d

# Check logs
docker compose logs -f

# Check status
docker compose ps
```

### 4. Test Your Bot

1. Find your bot in Telegram (search by username)
2. Send `/start` command
3. Bot should respond: "Hello world, **_your_name_**"

## Alternative: Without Docker

### Prerequisites

```bash
# Install uv package manager
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install dependencies
uv sync

# Activate environment
source .venv/bin/activate
```

### Start PostgreSQL

```bash
# PostgreSQL in Docker
docker run -d --name postgres-local \
  -e POSTGRES_DB=hello_bot \
  -e POSTGRES_USER=hello_user \
  -e POSTGRES_PASSWORD=local_password_123 \
  -p 5432:5432 postgres:15-alpine
```

### Run Bot

```bash
# Set environment variables
export BOT_TOKEN="your_token_here"
export DATABASE_URL="postgresql+asyncpg://hello_user:local_password_123@localhost:5432/hello_bot"

# Start bot
python -m app.main
```

## Verification

### Check Configuration

```bash
# Docker configuration
docker compose config

# Environment variables
docker compose exec bot env | grep BOT_TOKEN

# Database connection
docker compose exec postgres pg_isready -U hello_user -d hello_bot
```

### Check Logs

```bash
# Bot logs
docker compose logs bot

# PostgreSQL logs
docker compose logs postgres

# Real-time logs
docker compose logs -f
```

## Common Issues

### "BOT_TOKEN is required but not provided"

**Solution**: Set token in `.env` file (see step 2 above)

### "Database connection failed"

**Solution**:

```bash
# Restart PostgreSQL
docker compose restart postgres

# Check connection
docker compose exec postgres pg_isready -U hello_user -d hello_bot
```

### "Container failed to start"

**Solution**:

```bash
# Clean restart
docker compose down -v
docker compose up -d

# Check logs
docker compose logs
```

### "Permission denied"

**Solution**:

```bash
# Stop containers
docker compose down

# Remove old volumes
docker volume rm hello_bot_postgres_data

# Start fresh
docker compose up -d
```

## Monitoring

```bash
# Service status
docker compose ps

# Resource usage
docker stats

# Live logs
docker compose logs -f --tail=50
```

## Success Indicators

After correct setup, you should see:

```
✅ Bot configuration OK
✅ Database connection OK
🚀 Starting Hello Bot application
✅ Services are running
```

**Done! Your bot is working!** 🎉

## Next Steps

- [Local Development](LOCAL_DEVELOPMENT.md) - Full development setup
- [Deployment Guide](DEPLOYMENT.md) - Production deployment
- Customize bot behavior in `app/handlers/`
- Add new commands and features

## Quick Commands

```bash
# View status
docker compose ps

# Restart bot only
docker compose restart bot

# Stop everything
docker compose down

# Update and restart
docker compose pull && docker compose up -d

# Clean restart
docker compose down -v && docker compose up -d
```
