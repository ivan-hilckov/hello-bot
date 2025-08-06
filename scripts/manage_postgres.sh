#!/bin/bash
set -e

POSTGRES_COMPOSE="docker-compose.postgres.yml"

ensure_postgres_running() {
    # Check if container is running
    if docker ps -q -f name=vps_postgres_shared | grep -q .; then
        echo "✅ PostgreSQL already running"
        return 0
    fi
    
    # Check if container exists but stopped
    if docker ps -aq -f name=vps_postgres_shared | grep -q .; then
        echo "🔄 Starting existing PostgreSQL container..."
        docker start vps_postgres_shared
    else
        echo "🚀 Creating new shared PostgreSQL..."
        export POSTGRES_ADMIN_PASSWORD="${POSTGRES_ADMIN_PASSWORD:-$(openssl rand -base64 32)}"
        docker compose -f $POSTGRES_COMPOSE up -d
    fi
    
    echo "⏳ Waiting for PostgreSQL..."
    until docker exec vps_postgres_shared pg_isready -U postgres 2>/dev/null; do
        echo "Waiting for PostgreSQL to be ready..."
        sleep 2
    done
    echo "✅ PostgreSQL ready"
}

create_bot_database() {
    local BOT_NAME="$1"
    local BOT_PASSWORD="$2"
    
    if [[ -z "$BOT_NAME" || -z "$BOT_PASSWORD" ]]; then
        echo "❌ Bot name and password required"
        exit 1
    fi
    
    echo "📊 Creating database for ${BOT_NAME}..."
    
    # Ensure container is running first
    ensure_postgres_running
    
    # Create database and user (PostgreSQL syntax)
    docker exec vps_postgres_shared psql -U postgres << EOF || {
        echo "❌ Failed to create database"
        exit 1
    }
-- Create database if not exists
SELECT 'CREATE DATABASE ${BOT_NAME}_db'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${BOT_NAME}_db')\gexec

-- Create user if not exists  
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${BOT_NAME}_user') THEN
        CREATE USER ${BOT_NAME}_user WITH ENCRYPTED PASSWORD '${BOT_PASSWORD}';
    END IF;
END
\$\$;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE ${BOT_NAME}_db TO ${BOT_NAME}_user;
GRANT ALL ON SCHEMA public TO ${BOT_NAME}_user;
EOF
    
    echo "✅ Database ${BOT_NAME}_db ready"
}

case "$1" in
    start)
        ensure_postgres_running
        ;;
    create)
        create_bot_database "$2" "$3"
        ;;
    *)
        echo "Usage: $0 {start|create BOT_NAME BOT_PASSWORD}"
        exit 1
        ;;
esac