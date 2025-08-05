#!/bin/bash
# Stop development environment

echo "🛑 Stopping Hello Bot development environment..."
docker compose -f docker-compose.dev.yml down
echo "✅ Development environment stopped!"
