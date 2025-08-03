#!/bin/bash
# Production deployment script for Hello Bot
# This script handles the complete deployment process on VPS

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  INFO:${NC} $1"
}

log_success() {
    echo -e "${GREEN}✅ SUCCESS:${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠️  WARNING:${NC} $1"
}

log_error() {
    echo -e "${RED}❌ ERROR:${NC} $1"
}

# Configuration
DEPLOY_DIR="${HOME}/hello-bot"
BACKUP_DIR="${HOME}/hello-bot-backup"
MAX_RETRIES=3
TIMEOUT=300

# Validate required environment variables
validate_environment() {
    log_info "Validating environment variables..."
    
    local required_vars=(
        "BOT_TOKEN"
        "DB_PASSWORD"
        "ENVIRONMENT"
        "BOT_IMAGE"
    )
    
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "Missing required environment variables: ${missing_vars[*]}"
        exit 1
    fi
    
    log_success "All required environment variables are present"
}

# Create backup of current deployment
create_backup() {
    if [[ -d "$DEPLOY_DIR" ]]; then
        log_info "Creating backup of current deployment..."
        
        # Remove old backup
        rm -rf "$BACKUP_DIR" || true
        
        # Create new backup
        cp -r "$DEPLOY_DIR" "$BACKUP_DIR" || {
            log_warning "Failed to create backup, but continuing..."
        }
        
        log_success "Backup created at $BACKUP_DIR"
    else
        log_info "No existing deployment found, skipping backup"
    fi
}

# Setup deployment directory
setup_deployment_directory() {
    log_info "Setting up deployment directory..."
    
    # Create deployment directory if it doesn't exist
    mkdir -p "$DEPLOY_DIR"
    
    # Copy deployment files
    if [[ -d "/tmp/hello-bot-deploy" ]]; then
        log_info "Copying deployment files..."
        cp -r /tmp/hello-bot-deploy/* "$DEPLOY_DIR/"
        chmod +x "$DEPLOY_DIR/scripts"/*.sh || true
        log_success "Deployment files copied"
    else
        log_error "Deployment files not found at /tmp/hello-bot-deploy"
        exit 1
    fi
}

# Create production environment file
create_env_file() {
    log_info "Creating production environment file..."
    
    cd "$DEPLOY_DIR"
    
    cat > .env << EOF
# Production environment for Hello Bot
BOT_TOKEN=${BOT_TOKEN}
DB_PASSWORD=${DB_PASSWORD}
ENVIRONMENT=${ENVIRONMENT}
BOT_IMAGE=${BOT_IMAGE}
WEBHOOK_URL=${WEBHOOK_URL:-}
WEBHOOK_SECRET_TOKEN=${WEBHOOK_SECRET_TOKEN:-}

# Production settings
DEBUG=false
LOG_LEVEL=INFO

# Performance optimizations
DB_POOL_SIZE=3
DB_MAX_OVERFLOW=5
PYTHONOPTIMIZE=1
PYTHONDONTWRITEBYTECODE=1
PYTHONUNBUFFERED=1
EOF

    log_success "Environment file created"
}

# Pull Docker images with retry logic
pull_docker_images() {
    log_info "Pulling Docker images..."
    
    for attempt in $(seq 1 $MAX_RETRIES); do
        if docker compose --profile production pull; then
            log_success "Docker images pulled successfully"
            return 0
        else
            log_warning "Failed to pull images (attempt $attempt/$MAX_RETRIES)"
            if [[ $attempt -eq $MAX_RETRIES ]]; then
                log_error "Failed to pull Docker images after $MAX_RETRIES attempts"
                return 1
            fi
            sleep 10
        fi
    done
}

# Stop existing services gracefully
stop_existing_services() {
    log_info "Stopping existing services..."
    
    if docker compose --profile production ps | grep -q "Up"; then
        docker compose --profile production down --timeout 30 || {
            log_warning "Graceful shutdown failed, forcing stop..."
            docker compose --profile production kill || true
            docker compose --profile production down --timeout 5 || true
        }
        log_success "Existing services stopped"
    else
        log_info "No running services found"
    fi
}

# Check and handle existing database state
check_migration_state() {
    log_info "Checking database migration state..."
    
    # Check if users table exists
    local table_exists=$(docker compose --profile migration run --rm migration python -c "
import asyncio
import asyncpg
import os
import sys

async def check_table():
    try:
        conn = await asyncpg.connect(os.environ['DATABASE_URL'])
        result = await conn.fetchval(\"\"\"
            SELECT EXISTS (
                SELECT FROM information_schema.tables 
                WHERE table_schema = 'public' 
                AND table_name = 'users'
            );
        \"\"\")
        await conn.close()
        return result
    except Exception as e:
        print(f'Error checking table: {e}', file=sys.stderr)
        return False

result = asyncio.run(check_table())
print('true' if result else 'false')
" 2>/dev/null || echo "false")
    
    # Check if alembic_version table exists
    local alembic_exists=$(docker compose --profile migration run --rm migration python -c "
import asyncio
import asyncpg
import os
import sys

async def check_alembic():
    try:
        conn = await asyncpg.connect(os.environ['DATABASE_URL'])
        result = await conn.fetchval(\"\"\"
            SELECT EXISTS (
                SELECT FROM information_schema.tables 
                WHERE table_schema = 'public' 
                AND table_name = 'alembic_version'
            );
        \"\"\")
        await conn.close()
        return result
    except Exception as e:
        print(f'Error checking alembic table: {e}', file=sys.stderr)
        return False

result = asyncio.run(check_alembic())
print('true' if result else 'false')
" 2>/dev/null || echo "false")
    
    log_info "Table exists: $table_exists, Alembic tracking: $alembic_exists"
    
    if [[ "$table_exists" == "true" && "$alembic_exists" == "false" ]]; then
        log_info "Database tables exist but migration history is missing - marking migration as completed"
        docker compose --profile migration run --rm migration alembic stamp head
        log_success "Migration state synchronized"
        return 0
    elif [[ "$table_exists" == "true" && "$alembic_exists" == "true" ]]; then
        log_info "Database and migration history both exist - checking if migration is needed"
        return 1  # Proceed with normal migration check
    else
        log_info "Clean database state - proceeding with migration"
        return 1  # Proceed with normal migration
    fi
}

# Run database migration
run_database_migration() {
    log_info "Running database migration..."
    
    # First check the migration state
    if check_migration_state; then
        log_success "Migration state already synchronized"
        return 0
    fi
    
    # Run migration in isolation
    docker compose --profile migration up --exit-code-from migration migration
    
    local migration_exit_code=$?
    if [[ $migration_exit_code -eq 0 ]]; then
        log_success "Database migration completed successfully"
        
        # Cleanup migration container
        docker compose --profile migration down migration || true
    else
        log_error "Database migration failed with exit code: $migration_exit_code"
        return 1
    fi
}

# Start services
start_services() {
    log_info "Starting services..."
    
    docker compose --profile production up -d --remove-orphans
    
    if [[ $? -eq 0 ]]; then
        log_success "Services started successfully"
    else
        log_error "Failed to start services"
        return 1
    fi
}

# Wait for services to be healthy
wait_for_health() {
    log_info "Waiting for services to be healthy..."
    
    local start_time=$(date +%s)
    local end_time=$((start_time + TIMEOUT))
    
    while [[ $(date +%s) -lt $end_time ]]; do
        if docker compose --profile production exec -T bot python -c "from app.config import settings; print('Bot configuration OK')" 2>/dev/null; then
            log_success "Services are healthy"
            return 0
        fi
        
        log_info "Waiting for services to become healthy..."
        sleep 10
    done
    
    log_error "Health check timeout after ${TIMEOUT} seconds"
    return 1
}

# Cleanup old Docker resources
cleanup_docker() {
    log_info "Cleaning up old Docker resources..."
    
    # Remove unused images and containers
    docker system prune -f --volumes || log_warning "Docker cleanup failed"
    
    log_success "Docker cleanup completed"
}

# Show deployment status
show_status() {
    log_info "Deployment status:"
    echo ""
    echo "=== SERVICE STATUS ==="
    docker compose --profile production ps
    echo ""
    echo "=== RESOURCE USAGE ==="
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
}

# Rollback function
rollback() {
    log_error "Deployment failed, initiating rollback..."
    
    if [[ -d "$BACKUP_DIR" ]]; then
        log_info "Restoring from backup..."
        
        # Stop current services
        docker compose --profile production down --timeout 30 || true
        
        # Restore backup
        rm -rf "$DEPLOY_DIR"
        mv "$BACKUP_DIR" "$DEPLOY_DIR"
        
        # Start backup version
        cd "$DEPLOY_DIR"
        docker compose --profile production up -d --remove-orphans
        
        log_success "Rollback completed"
    else
        log_warning "No backup found, cannot rollback"
    fi
}

# Step timing function for performance tracking
step_timer() {
    local step_name=$1
    local start_time=$(date +%s)
    shift
    "$@"
    local result=$?
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    log_info "Step '$step_name' completed in ${duration}s"
    return $result
}

# Parallel preparation function
parallel_preparation() {
    log_info "Starting parallel preparation tasks..."
    
    # Pull Docker images in background
    (
        step_timer "pull_docker_images" pull_docker_images
        echo "PULL_COMPLETE" > /tmp/pull_status
    ) &
    local pull_pid=$!
    
    # Environment preparation in background
    (
        step_timer "environment_preparation" prepare_environment
        echo "ENV_COMPLETE" > /tmp/env_status
    ) &
    local env_pid=$!
    
    # Cleanup old resources in background
    (
        step_timer "cleanup_preparation" cleanup_old_resources
        echo "CLEANUP_COMPLETE" > /tmp/cleanup_status
    ) &
    local cleanup_pid=$!
    
    # Wait for all parallel tasks to complete
    local failed_tasks=()
    
    if ! wait $pull_pid; then
        failed_tasks+=("docker_pull")
    fi
    
    if ! wait $env_pid; then
        failed_tasks+=("environment_preparation")
    fi
    
    if ! wait $cleanup_pid; then
        failed_tasks+=("cleanup_preparation")
    fi
    
    # Check for failures
    if [[ ${#failed_tasks[@]} -gt 0 ]]; then
        log_error "Parallel preparation failed: ${failed_tasks[*]}"
        return 1
    fi
    
    log_success "All parallel preparation tasks completed successfully"
    
    # Cleanup status files
    rm -f /tmp/pull_status /tmp/env_status /tmp/cleanup_status
}

# Environment preparation function
prepare_environment() {
    log_info "Preparing environment variables and configuration..."
    
    # Pre-validate Docker Compose configuration
    if [[ -f "docker-compose.yml" ]]; then
        docker compose config > /dev/null || {
            log_warning "Docker Compose configuration validation failed"
            return 1
        }
    fi
    
    # Pre-create necessary directories
    mkdir -p "$HOME/.docker" || true
    
    log_success "Environment preparation completed"
}

# Cleanup old resources function
cleanup_old_resources() {
    log_info "Cleaning up old resources in background..."
    
    # Remove old unused images (keep recent ones)
    docker image prune -f --filter "until=72h" || log_warning "Image cleanup failed"
    
    # Remove unused networks
    docker network prune -f || log_warning "Network cleanup failed"
    
    # Remove unused build cache (keep recent)
    docker builder prune -f --filter "until=24h" || log_warning "Build cache cleanup failed"
    
    log_success "Resource cleanup completed"
}

# Fast health check function
wait_for_health_fast() {
    log_info "Performing fast health checks..."
    
    local start_time=$(date +%s)
    local end_time=$((start_time + 120))  # Reduced from 300s to 120s
    local check_interval=3  # Reduced from 10s to 3s
    
    while [[ $(date +%s) -lt $end_time ]]; do
        # Quick connectivity check first
        if docker compose --profile production exec -T bot python -c "
import sys
try:
    from app.config import settings
    if settings.bot_token:
        print('✅ Bot configuration OK')
        sys.exit(0)
    else:
        print('❌ Bot token not configured')
        sys.exit(1)
except Exception as e:
    print(f'❌ Configuration error: {e}')
    sys.exit(1)
" 2>/dev/null; then
            local elapsed=$(($(date +%s) - start_time))
            log_success "Services are healthy (verified in ${elapsed}s)"
            return 0
        fi
        
        log_info "Health check in progress... ($(date +%s) < $end_time)"
        sleep $check_interval
    done
    
    log_error "Fast health check timeout after 120 seconds"
    return 1
}

# Main deployment function
main() {
    local start_time=$(date +%s)
    local start_time_human=$(date)
    log_info "Starting Hello Bot production deployment at $start_time_human"
    
    # Set trap for cleanup on failure
    trap rollback ERR
    
    # Execute sequential preparation steps
    step_timer "validate_environment" validate_environment
    step_timer "create_backup" create_backup
    step_timer "setup_deployment_directory" setup_deployment_directory
    step_timer "create_env_file" create_env_file
    
    cd "$DEPLOY_DIR"
    
    # Execute parallel preparation tasks
    step_timer "parallel_preparation" parallel_preparation
    
    # Execute sequential deployment steps
    step_timer "stop_existing_services" stop_existing_services
    step_timer "run_database_migration" run_database_migration
    step_timer "start_services" start_services
    step_timer "wait_for_health_fast" wait_for_health_fast
    step_timer "cleanup_docker" cleanup_docker
    
    # Clear trap on success
    trap - ERR
    
    # Show final status
    show_status
    
    local end_time=$(date +%s)
    local total_duration=$((end_time - start_time))
    local end_time_human=$(date)
    
    log_success "Deployment completed successfully!"
    log_info "Started: $start_time_human"
    log_info "Completed: $end_time_human"
    log_info "Total deployment time: ${total_duration}s"
    
    # Clean up temporary files
    rm -rf /tmp/hello-bot-deploy || true
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi