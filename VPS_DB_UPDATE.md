# PostgreSQL Optimization Plan - Shared Database Container

## Problem Statement

**Current Issue**: Each bot creates individual PostgreSQL container (256MB RAM each)
**VPS Limitation**: 2GB RAM total
**Impact**: 3 bots = 768MB just for databases (38% of total RAM)

**Target Solution**: Single PostgreSQL container serving all bots with isolated databases

## Architecture Change

### Before (Per-Bot PostgreSQL)
```
VPS Server (2GB RAM)
├── bot1 + postgres1 (256MB)
├── bot2 + postgres2 (256MB)  
└── bot3 + postgres3 (256MB)
Total DB RAM: 768MB
```

### After (Shared PostgreSQL)
```
VPS Server (2GB RAM)
├── postgres-shared (512MB) 
│   ├── bot1_db
│   ├── bot2_db
│   └── bot3_db
├── bot1 (128MB)
├── bot2 (128MB)
└── bot3 (128MB)
Total DB RAM: 512MB (33% savings)
```

## Implementation Plan

### Phase 1: Create Shared PostgreSQL Container

#### 1.1 Create Shared Database Configuration
Create `docker-compose.postgres.yml`:

```yaml
services:
  postgres-shared:
    image: postgres:15-alpine
    container_name: vps_postgres_shared
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: ${POSTGRES_ADMIN_PASSWORD}
      POSTGRES_DB: postgres
    volumes:
      - postgres_shared_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    deploy:
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 6
      start_period: 30s
    restart: unless-stopped
    networks:
      - shared_network

volumes:
  postgres_shared_data:
    name: vps_postgres_shared_data

networks:
  shared_network:
    name: vps_shared_network
    driver: bridge
```

#### 1.2 Create Database Management Script
Create `scripts/manage_postgres.sh`:

```bash
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
```

### Phase 2: Update Bot Configuration

#### 2.1 Update docker-compose.yml
Replace existing postgres service configuration:

```yaml
services:
  migration:
    image: ${BOT_IMAGE}
    container_name: ${PROJECT_NAME}_migration
    env_file: .env
    environment:
      DATABASE_URL: postgresql+asyncpg://${PROJECT_NAME}_user:${DB_PASSWORD}@postgres-shared:5432/${PROJECT_NAME}_db
    command: ["alembic", "upgrade", "head"]
    depends_on:
      - postgres-check
    networks:
      - shared_network
    profiles:
      - migration
      - production
    restart: "no"

  postgres-check:
    image: postgres:15-alpine
    container_name: ${PROJECT_NAME}_db_check
    command: >
      sh -c "until pg_isready -h postgres-shared -p 5432 -U postgres; do
        echo 'Waiting for PostgreSQL...'; sleep 2;
      done && echo 'PostgreSQL ready!'"
    networks:
      - shared_network
    profiles:
      - migration
      - production
    restart: "no"

  bot:
    image: ${BOT_IMAGE}
    container_name: ${PROJECT_NAME}_app
    env_file: .env
    environment:
      DATABASE_URL: postgresql+asyncpg://${PROJECT_NAME}_user:${DB_PASSWORD}@postgres-shared:5432/${PROJECT_NAME}_db
      BOT_TOKEN: ${BOT_TOKEN}
      ENVIRONMENT: ${ENVIRONMENT:-production}
      DEBUG: ${DEBUG:-false}
      WEBHOOK_URL: ${WEBHOOK_URL:-}
      PYTHONOPTIMIZE: "1"
      PYTHONDONTWRITEBYTECODE: "1"
      PYTHONUNBUFFERED: "1"
    ports:
      - "8000:8000"
    depends_on:
      postgres-check:
        condition: service_completed_successfully
      migration:
        condition: service_completed_successfully
    deploy:
      resources:
        limits:
          memory: 128M
        reservations:
          memory: 64M
    restart: unless-stopped
    networks:
      - shared_network
    healthcheck:
      test: ["CMD", "python", "-c", "from app.config import settings; exit(0 if settings.bot_token else 1)"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    profiles:
      - production

# Remove postgres service and postgres_data volume entirely

networks:
  shared_network:
    name: vps_shared_network
    external: true
```

#### 2.2 Update Deployment Script
Modify `scripts/deploy_simple.sh`:

```bash
#!/bin/bash
set -e

echo "🚀 Starting Hello Bot deployment with shared PostgreSQL..."

DEPLOY_DIR="${HOME}/hello-bot"
cd "$DEPLOY_DIR" || { echo "❌ Deployment directory not found"; exit 1; }

# Validate required environment variables
for var in BOT_TOKEN DB_PASSWORD ENVIRONMENT BOT_IMAGE PROJECT_NAME; do
    if [[ -z "${!var:-}" ]]; then
        echo "❌ Missing required variable: $var"
        exit 1
    fi
done

# Ensure shared PostgreSQL is running
echo "🔍 Checking shared PostgreSQL..."
./scripts/manage_postgres.sh start

# Create database for this bot
echo "📊 Setting up database for ${PROJECT_NAME}..."
./scripts/manage_postgres.sh create "${PROJECT_NAME}" "${DB_PASSWORD}"

echo "📝 Creating production environment..."
cat > .env << EOF
BOT_TOKEN=${BOT_TOKEN}
DB_PASSWORD=${DB_PASSWORD}
ENVIRONMENT=${ENVIRONMENT:-production}
BOT_IMAGE=${BOT_IMAGE}
PROJECT_NAME=${PROJECT_NAME:-hello-bot}
WEBHOOK_URL=${WEBHOOK_URL:-}
DEBUG=false
PYTHONOPTIMIZE=1
PYTHONDONTWRITEBYTECODE=1
PYTHONUNBUFFERED=1
EOF

# Pull latest images
echo "📦 Pulling latest images..."
docker compose --profile production pull

# Stop existing bot services (not shared PostgreSQL)
echo "🛑 Stopping existing bot services..."
docker compose --profile production down

# Run database migration
echo "🗄️ Running database migration..."
docker compose --profile migration up migration --exit-code-from migration

# Start services
echo "🚀 Starting bot services..."
docker compose --profile production up -d

# Health check
echo "🔍 Checking service health..."
sleep 30
if docker compose --profile production exec -T bot python -c "from app.config import settings; print('✅ Bot healthy')"; then
    echo "✅ Deployment successful!"
else
    echo "❌ Health check failed"
    exit 1
fi

echo "🎉 Hello Bot deployed successfully with shared PostgreSQL!"
```

### Phase 3: Connection Pool Optimization

#### 3.1 Update Database Configuration
Modify `app/database.py`:

```python
# Optimized connection pool for shared PostgreSQL
engine = create_async_engine(
    settings.database_url,
    echo=settings.debug,
    future=True,
    pool_size=2,        # Reduced per bot (shared instance)
    max_overflow=3,     # Reduced overflow
    pool_timeout=30,
    pool_recycle=3600,
)
```

## Verification Steps

### Step 1: Pre-Migration Check
```bash
# Check current memory usage
docker stats --no-stream

# List current containers
docker ps -a | grep postgres
```

### Step 2: Deploy Shared PostgreSQL
```bash
# Create shared PostgreSQL
./scripts/manage_postgres.sh start

# Verify container running
docker ps | grep vps_postgres_shared

# Check memory usage
docker stats vps_postgres_shared --no-stream
```

### Step 3: Test Bot Database Creation
```bash
# Test database creation
./scripts/manage_postgres.sh create "test-bot" "test123"

# Verify database exists
docker exec vps_postgres_shared psql -U postgres -c "\l" | grep test-bot
```

### Step 4: Deploy Updated Bot
```bash
# Deploy with new configuration
./scripts/deploy_simple.sh

# Verify bot connects to shared DB
docker logs hello-bot_app | grep -i "database\|postgres"
```

### Step 5: Resource Verification
```bash
# Check total memory usage
docker stats --no-stream | grep -E "(postgres|hello-bot)"

# Verify network connectivity
docker exec hello-bot_app pg_isready -h postgres-shared -p 5432
```

## Migration Guide

### For New Bots
1. Use updated template with shared PostgreSQL configuration
2. Run `./scripts/deploy_simple.sh` - automatically creates database

### For Existing Bots
1. **Backup existing data**:
   ```bash
   docker exec ${PROJECT_NAME}_postgres pg_dump -U hello_user hello_bot > backup.sql
   ```

2. **Deploy shared PostgreSQL**:
   ```bash
   ./scripts/manage_postgres.sh start
   ```

3. **Create new database in shared instance**:
   ```bash
   ./scripts/manage_postgres.sh create "${PROJECT_NAME}" "${DB_PASSWORD}"
   ```

4. **Restore data**:
   ```bash
   docker exec -i vps_postgres_shared psql -U ${PROJECT_NAME}_user ${PROJECT_NAME}_db < backup.sql
   ```

5. **Update configuration and redeploy**:
   ```bash
   git pull origin main
   ./scripts/deploy_simple.sh
   ```

## Expected Results

### Resource Optimization
- **RAM Savings**: 33% reduction in database memory usage
- **3 bots**: From 768MB to 512MB (256MB saved)
- **5 bots**: From 1.28GB to 512MB (768MB saved)

### Operational Benefits
- **Centralized monitoring**: Single database container
- **Simplified backups**: One backup process for all bots
- **Faster deployment**: Reuse existing PostgreSQL instance
- **Better resource utilization**: Shared buffers and cache

### Performance Impact
- **Startup time**: Faster (no PostgreSQL startup per bot)
- **Memory efficiency**: Shared PostgreSQL system processes
- **Network optimization**: Single database network

## Monitoring Commands

### Check PostgreSQL Status
```bash
# Container status and memory
docker stats vps_postgres_shared --no-stream

# Database list
docker exec vps_postgres_shared psql -U postgres -c "\l" | grep "_db"

# Active connections
docker exec vps_postgres_shared psql -U postgres -c "
SELECT datname, count(*) as connections 
FROM pg_stat_activity 
WHERE datname IS NOT NULL 
GROUP BY datname;"
```

### Bot Health Check
```bash
# Check all bot containers
docker ps | grep "_app"

# Check database connectivity
for bot in $(docker ps --format "{{.Names}}" | grep "_app"); do
    echo "Testing $bot connection..."
    docker exec $bot python -c "
import asyncio
from app.database import engine
async def test():
    async with engine.begin() as conn:
        result = await conn.execute('SELECT 1')
        print('✅ Database connected')
asyncio.run(test())
" || echo "❌ $bot database connection failed"
done
```

## Rollback Plan

If issues occur:

1. **Stop shared PostgreSQL**:
   ```bash
   docker compose -f docker-compose.postgres.yml down
   ```

2. **Restore original docker-compose.yml**:
   ```bash
   git checkout HEAD~1 docker-compose.yml
   ```

3. **Restore individual PostgreSQL**:
   ```bash
   ./scripts/deploy_simple.sh
   ```

## GitHub Actions Configuration

### Required Secrets

Add these secrets in GitHub repository settings (`Settings > Secrets and variables > Actions`):

#### Existing Secrets (no changes needed)
- `DOCKERHUB_USERNAME` - Docker Hub username
- `DOCKERHUB_TOKEN` - Docker Hub access token  
- `VPS_HOST` - VPS IP address
- `VPS_USER` - VPS username (usually `root`)
- `VPS_SSH_KEY` - Private SSH key for VPS access
- `VPS_PORT` - SSH port (default: 22)
- `BOT_TOKEN` - Telegram bot token from BotFather
- `DB_PASSWORD` - Database password for bot user
- `WEBHOOK_URL` - (Optional) Webhook URL for production
- `WEBHOOK_SECRET_TOKEN` - (Optional) Webhook secret

#### New Secret Required for Shared PostgreSQL
- `POSTGRES_ADMIN_PASSWORD` - Strong password for shared PostgreSQL admin user

**Generate secure password:**
```bash
openssl rand -base64 32
```

### GitHub Secrets Setup Instructions

1. **Navigate to Repository Settings**:
   ```
   GitHub Repository > Settings > Secrets and variables > Actions > Repository secrets
   ```

2. **Add New Secret**:
   - Click "New repository secret"
   - Name: `POSTGRES_ADMIN_PASSWORD`
   - Value: Generated secure password (32+ characters)

3. **Verify All Secrets Present**:
   - ✅ `DOCKERHUB_USERNAME`
   - ✅ `DOCKERHUB_TOKEN`
   - ✅ `VPS_HOST`
   - ✅ `VPS_USER`
   - ✅ `VPS_SSH_KEY`
   - ✅ `BOT_TOKEN`
   - ✅ `DB_PASSWORD`
   - ✅ `POSTGRES_ADMIN_PASSWORD` ← **NEW**
   - ✅ `WEBHOOK_URL` (optional)

## Documentation Updates

This plan updates:
- `docs/ARCHITECTURE.md` - Add shared PostgreSQL section
- `docs/DEPLOYMENT.md` - Update deployment process
- `docs/DATABASE.md` - Update database architecture
- `README.md` - Update resource requirements
- `.env.example` - Add shared PostgreSQL variables
- `.github/workflows/deploy.yml` - Add new secret support

## Implementation Timeline

- **Phase 1**: Create shared PostgreSQL infrastructure (1 day)
- **Phase 2**: Update bot template and test (1 day)  
- **Phase 3**: Deploy and monitor optimization (1 day)

**Total**: 3 days with 33% RAM savings for database layer.