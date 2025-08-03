# Local Development Setup

Guide for setting up Hello Bot for local development and testing.

## Prerequisites

- Python 3.11+
- Docker and Docker Compose
- Git
- Code editor (VS Code recommended)

## 1. Get Telegram Bot Token

1. Message [@BotFather](https://t.me/botfather) in Telegram
2. Send `/newbot` command
3. Follow instructions to create your bot
4. Copy the token (format: `1234567890:ABCdefGHIjklMNOpqrsTUVwxyz`)

## 2. Environment Configuration

Create and configure your environment file:

```bash
# Copy example environment file
cp .env.example .env

# Edit with your values
code .env  # or nano .env
```

Set these values in `.env`:

```env
# Telegram Bot Configuration
BOT_TOKEN=your_real_token_from_botfather

# Database Configuration
DB_PASSWORD=local_password_123

# Development Settings
ENVIRONMENT=development
DEBUG=true
LOG_LEVEL=DEBUG
```

## 3. Development Options

### Option 1: Docker (Recommended)

**Start all services:**

```bash
# Start PostgreSQL + Bot in containers
docker compose up -d

# View logs in real-time
docker compose logs -f

# Check service status
docker compose ps
```

**Stop services:**

```bash
# Stop all services
docker compose down

# Stop and remove database data
docker compose down -v
```

### Option 2: Local Python

**Install dependencies:**

```bash
# Install uv package manager
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install project dependencies
uv sync

# Activate virtual environment
source .venv/bin/activate
```

**Setup PostgreSQL:**

```bash
# Option A: Local PostgreSQL (macOS)
brew install postgresql
brew services start postgresql
createdb hello_bot

# Option B: Docker PostgreSQL only
docker run -d \
  --name postgres-local \
  -e POSTGRES_DB=hello_bot \
  -e POSTGRES_USER=hello_user \
  -e POSTGRES_PASSWORD=local_password_123 \
  -p 5432:5432 \
  postgres:15-alpine
```

**Run the bot:**

```bash
# Set environment variables
export BOT_TOKEN="your_token_here"
export DATABASE_URL="postgresql+asyncpg://hello_user:local_password_123@localhost:5432/hello_bot"

# Start the bot
python -m app.main
```

## 4. Testing Your Setup

### Test Bot Connection

1. Find your bot in Telegram (search by username)
2. Send `/start` command
3. Verify you receive a personalized greeting

### View Logs

```bash
# Docker setup
docker compose logs bot --tail=50 -f

# Local Python setup
# Logs appear in your terminal
```

### Check Database

```bash
# Docker setup
docker compose exec postgres psql -U hello_user -d hello_bot -c "SELECT * FROM users;"

# Local PostgreSQL
psql -U hello_user -d hello_bot -c "SELECT * FROM users;"
```

## 5. Development Tools

### Code Quality

```bash
# Format code
uv run ruff format .

# Lint code
uv run ruff check . --fix

# Type checking (if mypy installed)
uv run mypy app/
```

### Database Management

```bash
# Create new migration
alembic revision --autogenerate -m "description"

# Apply migrations
alembic upgrade head

# View current migration
alembic current

# Migration history
alembic history
```

### Docker Management

```bash
# Rebuild containers
docker compose build --no-cache

# View container resources
docker stats

# Clean up Docker
docker system prune -f
```

## 6. Debugging

### Common Issues

**Bot not responding:**

```bash
# Check bot token
docker compose exec bot env | grep BOT_TOKEN

# Check bot logs
docker compose logs bot | grep ERROR
```

**Database connection errors:**

```bash
# Test database connection
docker compose exec postgres pg_isready -U hello_user -d hello_bot

# Check database logs
docker compose logs postgres
```

**Import errors:**

```bash
# Reinstall dependencies
uv sync --no-cache

# Check Python environment
python -c "from app.config import settings; print('Config OK')"
```

### Debug Mode

Enable detailed debugging:

```bash
# In .env file
DEBUG=true
LOG_LEVEL=DEBUG

# Restart services
docker compose restart bot
```

### Manual Testing

```bash
# Test configuration loading
python -c "
from app.config import settings
print(f'Bot token present: {bool(settings.bot_token)}')
print(f'Database URL: {settings.database_url}')
print(f'Environment: {settings.environment}')
"

# Test database connection
python -c "
import asyncio
from app.database.session import engine

async def test():
    try:
        async with engine.begin() as conn:
            await conn.execute('SELECT 1')
        print('✅ Database connection OK')
    except Exception as e:
        print(f'❌ Database error: {e}')

asyncio.run(test())
"
```

## 7. Performance Monitoring

### Resource Usage

```bash
# Docker resource usage
docker stats --no-stream

# System resources
free -h
df -h

# Process monitoring
ps aux | grep python
```

### Application Metrics

```bash
# Database queries
docker compose exec postgres psql -U hello_user -d hello_bot -c "
SELECT schemaname,tablename,n_tup_ins,n_tup_upd,n_tup_del
FROM pg_stat_user_tables;
"

# Connection pool status
# (logged in application output when DEBUG=true)
```

## 8. Development vs Production

### Development Mode

- `DEBUG=true`
- `LOG_LEVEL=DEBUG`
- Detailed SQL query logging
- Hot reload on code changes
- No resource limits

### Production Mode

- `DEBUG=false`
- `LOG_LEVEL=INFO`
- Optimized logging
- Health checks enabled
- Resource limits enforced

## 9. Useful Commands

```bash
# Quick development cycle
docker compose down && docker compose up -d && docker compose logs -f bot

# Reset everything
docker compose down -v
docker system prune -f
docker compose up -d

# Update dependencies
uv sync
docker compose build

# Database reset
docker compose down -v
docker compose up -d postgres
# Wait for PostgreSQL to start
docker compose up -d bot
```

## 10. IDE Setup

### VS Code Configuration

Create `.vscode/settings.json`:

```json
{
  "python.defaultInterpreterPath": "./.venv/bin/python",
  "python.linting.enabled": true,
  "python.linting.ruffEnabled": true,
  "python.formatting.provider": "ruff"
}
```

### Recommended Extensions

- Python
- Docker
- PostgreSQL
- Ruff
- Python Type Hint

---

**Your development environment is ready when the bot responds to `/start` with a personalized greeting and user data is saved to PostgreSQL.**
