#!/bin/bash
# Local deployment script for Hello Bot
# Usage: ./scripts/deploy.sh [environment]

set -euo pipefail

# Configuration
ENVIRONMENT=${1:-production}
PROJECT_NAME="hello-bot"
DEPLOY_DIR="/opt/$PROJECT_NAME"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ ${1}${NC}"
}

log_success() {
    echo -e "${GREEN}✅ ${1}${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  ${1}${NC}"
}

log_error() {
    echo -e "${RED}❌ ${1}${NC}"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    log_error "Don't run this script as root"
    exit 1
fi

# Check if Docker is available
if ! command -v docker >/dev/null 2>&1; then
    log_error "Docker is not installed"
    exit 1
fi

# Check if Docker Compose is available
if ! docker compose version >/dev/null 2>&1; then
    if ! command -v docker-compose >/dev/null 2>&1; then
        log_error "Docker Compose is not installed"
        exit 1
    fi
    COMPOSE_CMD="docker-compose"
else
    COMPOSE_CMD="docker compose"
fi

log_info "Starting $PROJECT_NAME deployment (Environment: $ENVIRONMENT)"

# Create deployment directory if it doesn't exist
if [ ! -d "$DEPLOY_DIR" ]; then
    log_info "Creating deployment directory: $DEPLOY_DIR"
    sudo mkdir -p "$DEPLOY_DIR"
    sudo chown $USER:$USER "$DEPLOY_DIR"
fi

# Copy files to deployment directory
log_info "Copying project files..."
cp docker-compose.yml "$DEPLOY_DIR/"
cp -r scripts "$DEPLOY_DIR/"
cp env.example "$DEPLOY_DIR/"

# Create .env file if it doesn't exist
if [ ! -f "$DEPLOY_DIR/.env" ]; then
    log_warning ".env file not found, copying from env.example"
    cp "$DEPLOY_DIR/env.example" "$DEPLOY_DIR/.env"
    log_warning "Please edit $DEPLOY_DIR/.env with your actual values"
    exit 1
fi

cd "$DEPLOY_DIR"

# Pull latest images
log_info "Pulling Docker images..."
$COMPOSE_CMD pull

# Stop existing services
log_info "Stopping existing services..."
$COMPOSE_CMD down --timeout 30 || true

# Start services
log_info "Starting services..."
$COMPOSE_CMD up -d --remove-orphans

# Wait for services to be ready
log_info "Waiting for services to start..."
sleep 10

# Check service status
log_info "Checking service status..."
if $COMPOSE_CMD ps | grep -q "Up"; then
    log_success "Services are running"
else
    log_error "Some services failed to start"
    $COMPOSE_CMD logs --tail=20
    exit 1
fi

# Run health checks
log_info "Running health checks..."
if $COMPOSE_CMD exec -T postgres pg_isready -U hello_user -d hello_bot >/dev/null 2>&1; then
    log_success "Database is ready"
else
    log_error "Database health check failed"
    exit 1
fi

# Cleanup
log_info "Cleaning up old Docker images..."
docker system prune -f >/dev/null 2>&1 || true

log_success "Deployment completed successfully!"

echo
echo "📊 Service Status:"
$COMPOSE_CMD ps

echo
echo "💡 Useful commands:"
echo "  View logs: cd $DEPLOY_DIR && $COMPOSE_CMD logs -f"
echo "  Restart bot: cd $DEPLOY_DIR && $COMPOSE_CMD restart bot"
echo "  Stop all: cd $DEPLOY_DIR && $COMPOSE_CMD down"
echo "  Update: cd $DEPLOY_DIR && $COMPOSE_CMD pull && $COMPOSE_CMD up -d"