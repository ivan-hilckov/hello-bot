#!/bin/bash
# Simplified production deployment for Hello Bot
# Reduces complexity from 480 to 50 lines (90% reduction)

set -e

echo "🚀 Starting Hello Bot deployment..."

# Configuration
DEPLOY_DIR="${HOME}/hello-bot"
cd "$DEPLOY_DIR" || { echo "❌ Deployment directory not found"; exit 1; }

# Validate required environment variables
for var in BOT_TOKEN DB_PASSWORD ENVIRONMENT BOT_IMAGE PROJECT_NAME; do
    if [[ -z "${!var:-}" ]]; then
        echo "❌ Missing required variable: $var"
        exit 1
    fi
done

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

# Stop existing services
echo "🛑 Stopping existing services..."
docker compose --profile production down

# Run database migration
echo "🗄️ Running database migration..."
docker compose --profile migration up migration --exit-code-from migration

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

echo "🎉 Hello Bot deployed successfully!"
