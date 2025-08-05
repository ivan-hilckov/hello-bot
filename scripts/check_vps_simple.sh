#!/bin/bash
# Simplified VPS readiness check for Hello Bot
# Reduces complexity from 379 to 30 lines (92% reduction)

echo "🔍 Checking VPS readiness for Hello Bot..."

# Check Docker installation
command -v docker >/dev/null || { echo "❌ Docker not found - install Docker first"; exit 1; }
echo "✅ Docker: $(docker --version | cut -d' ' -f3)"

# Check Docker Compose
docker compose version >/dev/null || { echo "❌ Docker Compose not found"; exit 1; }
echo "✅ Docker Compose: Available"

# Check Docker daemon
docker ps >/dev/null || { echo "❌ Docker daemon not running"; exit 1; }
echo "✅ Docker daemon: Running"

# Basic resource checks
total_ram=$(free -m 2>/dev/null | awk 'NR==2{printf "%.1f", $2/1024}' || echo "unknown")
available_disk=$(df -h / 2>/dev/null | awk 'NR==2{print $4}' || echo "unknown")

echo "💾 RAM: ${total_ram}GB total"
echo "💽 Disk: ${available_disk} available"

# Simple warnings for minimal requirements
if command -v bc >/dev/null 2>&1 && (( $(echo "$total_ram < 0.5" | bc -l 2>/dev/null) )); then
    echo "⚠️ Warning: Less than 0.5GB RAM - performance may be limited"
fi

echo "✅ VPS ready for Hello Bot deployment!"
