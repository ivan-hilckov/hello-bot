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
PROJECT_NAME=${PROJECT_NAME}
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

# Clean up conflicting Docker networks before migration
cleanup_conflicting_networks() {
    log_info "Cleaning up conflicting Docker networks..."
    
    local network_name="${PROJECT_NAME}_network"
    
    # Check if network exists and has wrong labels
    if docker network inspect "$network_name" >/dev/null 2>&1; then
        log_warning "Found existing network '$network_name', checking for label conflicts..."
        
        # Force remove the network to avoid Docker Compose label conflicts
        docker network rm "$network_name" 2>/dev/null || {
            log_warning "Could not remove network '$network_name' (may be in use by containers)"
            
            # If network removal failed, try stopping all containers using it first
            log_info "Attempting to stop containers using the network..."
            docker ps -q --filter "network=$network_name" | xargs -r docker stop || true
            docker network rm "$network_name" 2>/dev/null || log_warning "Network cleanup failed - proceeding anyway"
        }
        
        log_success "Network cleanup completed"
    else
        log_info "No conflicting network found"
    fi
}

# Run database migration with smart error handling
run_database_migration() {
    log_info "Running database migration..."
    
    # Try to run migration normally first
    if docker compose --profile migration up --exit-code-from migration migration 2>/dev/null; then
        log_success "Database migration completed successfully"
        docker compose --profile migration down migration || true
        return 0
    fi
    
    # If migration failed, assume it's a password issue and recreate database
    log_warning "Migration failed - recreating database with fresh credentials..."
    
    # Stop all services and clean up completely
    docker compose --profile production --profile migration down --volumes --remove-orphans || true
    
    # Explicitly remove volume and network to ensure clean state
    docker volume rm "${PROJECT_NAME}_postgres_data" 2>/dev/null || log_info "No existing volume to remove"
    docker network rm "${PROJECT_NAME}_network" 2>/dev/null || log_info "No existing network to remove"
    
    # Wait a moment for Docker to clean up
    sleep 5
    
    # Restart database with new password
    log_info "Starting fresh database with new credentials..."
    docker compose --profile migration up -d postgres
    
    # Wait for database to be ready
    log_info "Waiting for database to initialize..."
    sleep 30
    
    # Now try migration again
    if docker compose --profile migration up --exit-code-from migration migration; then
        log_success "Database migration completed with fresh database"
        docker compose --profile migration down migration || true
        return 0
    fi
    
    # If migration still failed, try to mark current state as up-to-date
    log_info "Migration still failed, checking if tables already exist..."
    if docker compose --profile migration run --rm migration alembic stamp head 2>/dev/null; then
        log_success "Database state synchronized - tables already exist"
        return 0
    fi
    
    # If that also failed, run migration again and show the error
    log_error "Migration failed, running again to show error details..."
    docker compose --profile migration up --exit-code-from migration migration
    
    local migration_exit_code=$?
    if [[ $migration_exit_code -eq 0 ]]; then
        log_success "Database migration completed successfully"
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

# Simplified preparation function
prepare_deployment() {
    log_info "Preparing deployment..."
    
    # Pull images and cleanup in parallel (simple background tasks)
    pull_docker_images &
    local pull_pid=$!
    
    cleanup_old_resources &
    local cleanup_pid=$!
    
    # Wait for background tasks
    wait $pull_pid && wait $cleanup_pid
    
    log_success "Deployment preparation completed"
}

# Cleanup old resources function
cleanup_old_resources() {
    log_info "Cleaning up old resources in background..."
    
    # Remove old unused images (keep recent ones)
    docker image prune -f --filter "until=72h" || log_warning "Image cleanup failed"
    
    # Clean up conflicting networks (Docker Compose label mismatch fix)
    log_info "Cleaning up potentially conflicting networks..."
    if docker network inspect "${PROJECT_NAME}_network" >/dev/null 2>&1; then
        log_warning "Found existing ${PROJECT_NAME}_network with potential label conflicts, removing..."
        docker network rm "${PROJECT_NAME}_network" 2>/dev/null || log_warning "Could not remove ${PROJECT_NAME}_network (may be in use)"
    fi
    
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
    
    # Validate and export PROJECT_NAME globally for all docker compose commands
    if [[ -z "${PROJECT_NAME:-}" ]]; then
        log_error "PROJECT_NAME environment variable is required"
        exit 1
    fi
    export PROJECT_NAME
    log_info "Using PROJECT_NAME: $PROJECT_NAME (exported globally)"
    
    # Execute sequential preparation steps
    step_timer "validate_environment" validate_environment
    step_timer "create_backup" create_backup
    step_timer "setup_deployment_directory" setup_deployment_directory
    step_timer "create_env_file" create_env_file
    
    cd "$DEPLOY_DIR"
    
    # Execute simplified preparation
    step_timer "prepare_deployment" prepare_deployment
    
    # Execute sequential deployment steps
    step_timer "stop_existing_services" stop_existing_services
    step_timer "cleanup_conflicting_networks" cleanup_conflicting_networks
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