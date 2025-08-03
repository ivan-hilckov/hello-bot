#!/bin/bash
# Local testing script for Hello Bot Docker configuration
# This script tests Docker setup without VPS deployment
# Usage: ./scripts/test_local.sh

set -euo pipefail

echo "🧪 Testing Hello Bot Docker configuration locally..."
echo

# Check if Docker is installed
if ! command -v docker >/dev/null 2>&1; then
    echo "❌ Docker is not installed. Please install Docker first:"
    echo "   https://docs.docker.com/get-docker/"
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker daemon is not running. Please start Docker."
    exit 1
fi

echo "✅ Docker is available"

# Check if Docker Compose is available
if docker compose version >/dev/null 2>&1; then
    echo "✅ Docker Compose is available"
elif command -v docker-compose >/dev/null 2>&1; then
    echo "✅ Docker Compose (legacy) is available"
else
    echo "❌ Docker Compose is not available. Please install it."
    exit 1
fi

# Test Docker configuration validation
echo
echo "🔍 Validating Docker Compose configuration..."
if docker compose config >/dev/null 2>&1; then
    echo "✅ docker-compose.yml is valid"
else
    echo "❌ docker-compose.yml has configuration errors"
    docker compose config
    exit 1
fi

# Check if .env file exists
if [ ! -f .env ]; then
    echo "⚠️  .env file not found. Creating from template..."
    cp env.example .env
    echo "📝 Please edit .env file with your BOT_TOKEN and DB_PASSWORD"
    echo "   Required variables:"
    echo "   - BOT_TOKEN=your_telegram_bot_token"
    echo "   - DB_PASSWORD=secure_password"
    exit 1
fi

# Check if BOT_TOKEN is set
if ! grep -q "BOT_TOKEN=" .env || grep -q "BOT_TOKEN=your_telegram_bot_token" .env; then
    echo "⚠️  BOT_TOKEN not set in .env file"
    echo "   Please set your actual Telegram bot token"
    exit 1
fi

echo "✅ Environment configuration looks good"

# Test building the Docker image
echo
echo "🔨 Testing Docker image build..."
if docker build -t hello-bot-test . >/dev/null 2>&1; then
    echo "✅ Docker image builds successfully"
    
    # Cleanup test image
    docker rmi hello-bot-test >/dev/null 2>&1 || true
else
    echo "❌ Docker image build failed"
    exit 1
fi

# Test Docker Compose services start
echo
echo "🚀 Testing Docker Compose services..."
echo "This will start the services briefly to test configuration..."

# Start services in detached mode
if docker compose up -d >/dev/null 2>&1; then
    echo "✅ Services started successfully"
    
    # Wait a moment for services to initialize
    sleep 5
    
    # Check service status
    echo
    echo "📊 Service Status:"
    docker compose ps
    
    # Check if PostgreSQL is responding
    echo
    echo "🔍 Testing PostgreSQL connection..."
    if docker compose exec -T postgres pg_isready -U hello_user -d hello_bot >/dev/null 2>&1; then
        echo "✅ PostgreSQL is responding"
    else
        echo "⚠️  PostgreSQL is not ready yet (this is normal on first start)"
    fi
    
    # Show recent logs
    echo
    echo "📝 Recent logs (last 10 lines):"
    docker compose logs --tail=10
    
    # Stop services
    echo
    echo "🛑 Stopping test services..."
    docker compose down >/dev/null 2>&1
    
    echo "✅ Local testing completed successfully!"
    echo
    echo "🎯 Your Docker configuration is ready for VPS deployment!"
    echo "   Next step: Run ./scripts/deploy_to_vps.sh"
    
else
    echo "❌ Failed to start services"
    echo "Checking logs..."
    docker compose logs
    
    # Cleanup
    docker compose down >/dev/null 2>&1 || true
    exit 1
fi