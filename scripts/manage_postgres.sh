#!/bin/bash
set -e

POSTGRES_COMPOSE="docker-compose.postgres.yml"

ensure_postgres_running() {
    if ! docker ps -q -f name=vps_postgres_shared; then
        echo "🚀 Starting shared PostgreSQL..."
        export POSTGRES_ADMIN_PASSWORD="${POSTGRES_ADMIN_PASSWORD:-$(openssl rand -base64 32)}"
        docker compose -f $POSTGRES_COMPOSE up -d
        
        echo "⏳ Waiting for PostgreSQL..."
        until docker exec vps_postgres_shared pg_isready -U postgres; do
            sleep 2
        done
        echo "✅ PostgreSQL ready"
    else
        echo "✅ PostgreSQL already running"
    fi
}

create_bot_database() {
    local BOT_NAME="$1"
    local BOT_PASSWORD="$2"
    
    echo "📊 Creating database for ${BOT_NAME}..."
    
    docker exec vps_postgres_shared psql -U postgres << EOF
CREATE DATABASE IF NOT EXISTS ${BOT_NAME}_db;
CREATE USER IF NOT EXISTS ${BOT_NAME}_user WITH ENCRYPTED PASSWORD '${BOT_PASSWORD}';
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