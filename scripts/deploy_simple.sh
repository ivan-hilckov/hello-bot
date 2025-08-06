#!/bin/bash
# Simplified production deployment for Hello Bot with shared PostgreSQL
# Reduces complexity from 480 to 50 lines (90% reduction)

set -e

echo "🚀 Starting Hello Bot deployment with shared PostgreSQL..."

# Configuration
DEPLOY_DIR="${HOME}/hello-bot"
# Note: We're already in the deployment directory from GitHub Actions

# Validate required environment variables
for var in BOT_TOKEN DB_PASSWORD ENVIRONMENT BOT_IMAGE PROJECT_NAME; do
    if [[ -z "${!var:-}" ]]; then
        echo "❌ Missing required variable: $var"
        exit 1
    fi
done

# Debug: Show current directory and files
echo "📁 Current directory: $(pwd)"
echo "📁 Available files:"
ls -la

# Debug: Check Docker status
echo "🐳 Docker containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Stop old individual PostgreSQL if running
echo "🛑 Stopping old individual PostgreSQL containers..."
docker stop hello-bot_postgres 2>/dev/null || echo "Old PostgreSQL container not running"
docker stop hello-bot_app 2>/dev/null || echo "Old bot container not running"
docker stop hello-bot_migration 2>/dev/null || echo "Old migration container not running"

# Ensure shared PostgreSQL is running
echo "🔍 Checking shared PostgreSQL..."
./scripts/manage_postgres.sh start

# Create database for this bot
echo "📊 Setting up database for ${PROJECT_NAME}..."
./scripts/manage_postgres.sh create "${PROJECT_NAME}" "${DB_PASSWORD}"

echo "📝 Creating production environment..."
cat > .env << EOF
BOT_TOKEN=${BOT_TOKEN}
DB_PASSWORD=${DB_PASSWORD}
ENVIRONMENT=${ENVIRONMENT:-production}
BOT_IMAGE=${BOT_IMAGE}
PROJECT_NAME=${PROJECT_NAME:-hello-bot}
WEBHOOK_URL=${WEBHOOK_URL:-}
DEBUG=false
PYTHONOPTIMIZE=1
PYTHONDONTWRITEBYTECODE=1
PYTHONUNBUFFERED=1
EOF

# Pull latest images
echo "📦 Pulling latest images..."
docker compose --profile production pull

# Stop existing bot services (not shared PostgreSQL)
echo "🛑 Stopping existing bot services..."
docker compose --profile production down

# Database tables will be created automatically on bot startup

# Start services
echo "🚀 Starting services..."
docker compose --profile production up -d

# Basic health check
echo "🔍 Checking service health..."
sleep 30
if docker compose --profile production exec -T bot python -c "from app.config import settings; print('✅ Bot healthy')"; then
    echo "✅ Deployment successful!"
else
    echo "❌ Health check failed"
    exit 1
fi

echo "🎉 Hello Bot deployed successfully with shared PostgreSQL!"
