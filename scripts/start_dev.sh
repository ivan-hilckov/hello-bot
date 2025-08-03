#!/bin/bash
# Start development environment with hot reloading

set -e

echo "🚀 Starting Hello Bot development environment..."

# Check if .env exists
if [ ! -f .env ]; then
    echo "❌ .env file not found. Please copy .env.example to .env and configure it."
    echo "   cp .env.example .env"
    echo "   # Then edit .env with your BOT_TOKEN and other settings"
    exit 1
fi

# Stop any existing containers
echo "🧹 Cleaning up existing containers..."
docker compose --profile development down

# Build and start development services
echo "🔨 Building and starting development services..."
docker compose --profile development up --build -d postgres
echo "⏳ Waiting for database to be ready..."
sleep 5

echo "🤖 Starting bot with hot reloading..."
docker compose --profile development up --build bot-dev

echo "✅ Development environment is running!"
echo "   - Bot will restart automatically when you change code"
echo "   - Database: postgres://hello_user@localhost:5432/hello_bot"
echo "   - Adminer: http://localhost:8080 (if development profile is active)"
echo ""
echo "To stop: docker compose --profile development down"