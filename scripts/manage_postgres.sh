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
        docker compose -f $POSTGRES_COMPOSE up -d --remove-orphans
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
    
    # Check if database already exists
    DB_EXISTS=$(docker exec vps_postgres_shared psql -U postgres -tAc "SELECT 1 FROM pg_database WHERE datname='${BOT_NAME}_db';" 2>/dev/null || echo "")
    
    if [[ "$DB_EXISTS" == "1" ]]; then
        echo "✅ Database ${BOT_NAME}_db already exists"
    else
        echo "Creating database ${BOT_NAME}_db..."
        docker exec vps_postgres_shared psql -U postgres -c "CREATE DATABASE \"${BOT_NAME}_db\";" || {
            echo "❌ Failed to create database"
            exit 1
        }
    fi
    
    # Check if user already exists
    USER_EXISTS=$(docker exec vps_postgres_shared psql -U postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='${BOT_NAME}_user';" 2>/dev/null || echo "")
    
    if [[ "$USER_EXISTS" == "1" ]]; then
        echo "✅ User ${BOT_NAME}_user already exists"
    else
        echo "Creating user ${BOT_NAME}_user..."
        docker exec vps_postgres_shared psql -U postgres -c "CREATE USER \"${BOT_NAME}_user\" WITH ENCRYPTED PASSWORD '${BOT_PASSWORD}';" || {
            echo "❌ Failed to create user"
            exit 1
        }
    fi
    
    echo "Granting privileges..."
    docker exec vps_postgres_shared psql -U postgres -c "
        GRANT ALL PRIVILEGES ON DATABASE \"${BOT_NAME}_db\" TO \"${BOT_NAME}_user\";
    " 2>/dev/null || echo "Privileges grant failed"
    
    # Additional schema privileges
    docker exec vps_postgres_shared psql -U postgres -d "${BOT_NAME}_db" -c "
        GRANT ALL ON SCHEMA public TO \"${BOT_NAME}_user\";
    " 2>/dev/null || echo "Schema privileges grant failed"
    
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