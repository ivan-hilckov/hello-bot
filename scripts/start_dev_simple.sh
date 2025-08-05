#!/bin/bash
# Simplified development startup (35→15 lines reduction)

echo "🚀 Starting Hello Bot development..."

# Check .env file exists
[ ! -f .env ] && {
    echo "❌ Copy .env.example to .env and add your BOT_TOKEN first"
    echo "   cp .env.example .env"
    exit 1
}

# Start development with auto-reload via Docker volumes
docker compose -f docker-compose.dev.yml up --build

echo "✅ Development environment running!"
echo "   Code changes will auto-restart the bot"
echo "   Database: http://localhost:8080 (Adminer)"
