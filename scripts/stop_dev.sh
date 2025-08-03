#!/bin/bash
# Stop development environment

echo "🛑 Stopping Hello Bot development environment..."
docker compose --profile development down
echo "✅ Development environment stopped!"