# Local Development Setup

Quick guide for setting up Hello Bot for local development.

## Prerequisites

- **Python 3.12+**
- **Docker & Docker Compose**
- **Telegram Bot Token** from [@BotFather](https://t.me/botfather)

## Quick Start

### 1. Get Bot Token

1. Message [@BotFather](https://t.me/botfather) in Telegram
2. Send `/newbot` and follow instructions
3. Copy your token (format: `1234567890:ABCdef...`)

### 2. Setup Environment

```bash
# Clone and configure
git clone <repository>
cd hello-bot

# Copy environment template
cp .env.example .env

# Edit with your bot token
nano .env  # or code .env
```

**Required in `.env`**:

```env
BOT_TOKEN=your_real_token_from_botfather
PROJECT_NAME=telegram-bot
DB_PASSWORD=local_password_123
ENVIRONMENT=development
DEBUG=true
LOG_LEVEL=DEBUG
```

> **💡 Note**: Set `PROJECT_NAME` to your bot's name (use in template or keep default `telegram-bot`).

### 3. Run with Docker (Recommended)

```bash
# Start all services
docker compose up -d

# View logs
docker compose logs -f

# Stop services
docker compose down
```

**Services Started**:

- **PostgreSQL**: Database server with optimized indexes
- **Redis**: Cache server with memory fallback
- **Bot**: Modern Telegram bot with enterprise features
  - Router pattern + Service Layer architecture
  - Dependency injection system
  - Prometheus metrics collection
  - Enhanced health checks with monitoring

### 4. Verify Setup

1. **Test Bot Functionality**:

   - Find your bot in Telegram (search by username)
   - Send `/start` → should respond with personalized greeting
   - User should be cached for subsequent requests

2. **Check All Services**:

   ```bash
   # Verify all containers are running
   docker compose ps

   # Check application logs
   docker compose logs bot --tail=20
   ```

3. **Test Enhanced Health Checks**:

   ```bash
   # Test health endpoint (if webhook mode)
   curl http://localhost:8000/health

   # Check Prometheus metrics (if enabled)
   curl http://localhost:8000/metrics
   ```

4. **Verify Database with Optimizations**:

   ```bash
   # Check user creation and indexes
   docker compose exec postgres psql -U hello_user -d hello_bot -c "
   SELECT
     COUNT(*) as total_users,
     COUNT(*) FILTER (WHERE username IS NOT NULL) as users_with_username
   FROM users;
   "

   # Verify indexes exist
   docker compose exec postgres psql -U hello_user -d hello_bot -c "
   SELECT indexname, indexdef
   FROM pg_indexes
   WHERE tablename = 'users';
   "
   ```

5. **Test Redis Cache**:

   ```bash
   # Check Redis connectivity
   docker compose exec redis redis-cli ping

   # Monitor cache usage
   docker compose exec redis redis-cli info memory | grep used_memory_human
   ```

## Alternative: Local Python Development

### Install Dependencies

```bash
# Install uv package manager
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install project dependencies
uv sync

# Activate virtual environment
source .venv/bin/activate  # Linux/macOS
# or .venv\Scripts\activate  # Windows
```

### Run PostgreSQL Only

```bash
# Start PostgreSQL in Docker
docker run -d --name postgres-local \
  -e POSTGRES_DB=hello_bot \
  -e POSTGRES_USER=hello_user \
  -e POSTGRES_PASSWORD=local_password_123 \
  -p 5432:5432 \
  postgres:15-alpine
```

### Run Bot Locally

```bash
# Set environment variables
export BOT_TOKEN="your_token_here"
export DATABASE_URL="postgresql+asyncpg://hello_user:local_password_123@localhost:5432/hello_bot"

# Apply database migrations
alembic upgrade head

# Start the bot
python -m app.main
```

## Development Workflow

### Code Changes

```bash
# Format code
uv run ruff format .

# Lint code
uv run ruff check . --fix

# Restart services to apply changes
docker compose restart bot
```

### Database Management

```bash
# Create new migration
alembic revision --autogenerate -m "description"

# Apply migrations
alembic upgrade head

# View current migration
alembic current

# Reset database (DESTRUCTIVE)
docker compose down -v
docker compose up -d
```

### Useful Commands

```bash
# Rebuild containers after code changes
docker compose build --no-cache

# View container resources
docker stats

# Clean up Docker
docker system prune -f

# View all services status
docker compose ps

# Follow logs for specific service
docker compose logs -f bot
docker compose logs -f postgres
```

## Development vs Production

| Feature             | Development                             | Production                              |
| ------------------- | --------------------------------------- | --------------------------------------- |
| **Mode**            | Polling (bot asks Telegram for updates) | Webhook (Telegram sends updates to bot) |
| **Database**        | Local PostgreSQL container with indexes | Remote PostgreSQL on VPS (optimized)    |
| **Caching**         | Redis + memory fallback (same as prod)  | Redis + memory fallback                 |
| **Logging**         | Human-readable format, DEBUG level      | JSON format, INFO level                 |
| **Metrics**         | Available but not mandatory             | Prometheus metrics enabled              |
| **Health Checks**   | Basic checks                            | Enhanced multi-service monitoring       |
| **Service Layer**   | Full DI + Service Layer (same as prod)  | Full DI + Service Layer                 |
| **Resource Limits** | None                                    | Memory/CPU limits for 2GB VPS           |
| **Testing**         | 12 comprehensive tests available        | Tested before deployment                |

## Testing Infrastructure

The bot now includes comprehensive testing suite:

### Running Tests

```bash
# Run all tests
uv run pytest

# Run tests with coverage
uv run pytest --cov=app

# Run specific test file
uv run pytest tests/test_services.py

# Run with verbose output
uv run pytest -v
```

### Test Structure

```bash
tests/
├── conftest.py          # Test fixtures and setup
├── test_handlers.py     # Handler testing (4 tests)
├── test_services.py     # Service layer testing (4 tests)
└── test_webhook.py      # FastAPI webhook testing (4 tests)
```

### Test Features

- **SQLite in-memory database** for fast isolated tests
- **Mock Telegram objects** for handler testing
- **Async test support** with pytest-asyncio
- **Service layer testing** with dependency injection
- **FastAPI client testing** for webhook endpoints

### Test Examples

```bash
# Test output example
================================ test session starts ================================
collected 12 items

tests/test_handlers.py::test_start_handler_success ✓
tests/test_handlers.py::test_start_handler_no_user ✓
tests/test_services.py::test_get_or_create_user_new ✓
tests/test_services.py::test_get_or_create_user_existing ✓
tests/test_webhook.py::test_health_check ✓
tests/test_webhook.py::test_metrics_endpoint ✓
...

================================ 12 passed in 2.34s ================================
```

## Troubleshooting

### Bot Not Responding

```bash
# Check bot token
docker compose exec bot env | grep BOT_TOKEN

# Check bot logs
docker compose logs bot | grep ERROR

# Test bot token manually
curl https://api.telegram.org/bot$BOT_TOKEN/getMe
```

### Database Connection Issues

```bash
# Test database connection
docker compose exec postgres pg_isready -U hello_user -d hello_bot

# Check database logs
docker compose logs postgres

# Reset database
docker compose down -v && docker compose up -d
```

### Container Issues

```bash
# Check container status
docker compose ps

# View container logs
docker compose logs

# Restart specific service
docker compose restart bot

# Rebuild containers
docker compose build --no-cache
docker compose up -d
```

### Import/Module Errors

```bash
# Reinstall dependencies
uv sync --no-cache

# Check Python environment
python -c "from app.config import settings; print('✅ Config OK')"

# Test database connection
python -c "
import asyncio
from app.database.session import engine

async def test():
    async with engine.begin() as conn:
        await conn.execute('SELECT 1')
    print('✅ Database OK')

asyncio.run(test())
"
```

## Development Tools

### VS Code Setup

**`.vscode/settings.json`**:

```json
{
  "python.defaultInterpreterPath": "./.venv/bin/python",
  "python.linting.enabled": true,
  "python.linting.ruffEnabled": true,
  "python.formatting.provider": "ruff"
}
```

**Recommended Extensions**:

- Python
- Docker
- PostgreSQL
- Ruff

### Environment Variables

**Development `.env`**:

```env
# Required
BOT_TOKEN=your_telegram_bot_token
PROJECT_NAME=telegram-bot
DB_PASSWORD=local_password_123

# Development settings
ENVIRONMENT=development
DEBUG=true
LOG_LEVEL=DEBUG

# Database (auto-configured in Docker)
DATABASE_URL=postgresql+asyncpg://hello_user:local_password_123@postgres:5432/hello_bot
```

## Testing Changes

### Manual Testing Flow

1. **Make code changes** in `app/` directory
2. **Restart bot**: `docker compose restart bot`
3. **Test in Telegram**: Send `/start` to your bot
4. **Check logs**: `docker compose logs -f bot`
5. **Verify database**: Check user record creation

### Database Testing

```bash
# View all users
docker compose exec postgres psql -U hello_user -d hello_bot -c "
SELECT telegram_id, username, first_name, created_at FROM users;
"

# Count total users
docker compose exec postgres psql -U hello_user -d hello_bot -c "
SELECT COUNT(*) as total_users FROM users;
"

# Recent activity (last hour)
docker compose exec postgres psql -U hello_user -d hello_bot -c "
SELECT * FROM users WHERE created_at > NOW() - INTERVAL '1 hour';
"
```

## Performance Monitoring

### Resource Usage

```bash
# Docker container stats
docker stats --no-stream

# System resources
free -h  # Memory usage
df -h    # Disk usage
```

### Application Metrics

```bash
# Database connection info
docker compose exec postgres psql -U hello_user -d hello_bot -c "
SELECT count(*) as active_connections
FROM pg_stat_activity
WHERE state = 'active';
"

# Table statistics
docker compose exec postgres psql -U hello_user -d hello_bot -c "
SELECT schemaname, tablename, n_tup_ins, n_tup_upd
FROM pg_stat_user_tables;
"
```

## Next Steps

- **Add Features**: Extend bot with new commands in `app/handlers/`
- **Database Changes**: Add models and migrations
- **Production Deploy**: Follow [Deployment Guide](DEPLOYMENT.md)
- **Architecture**: Read [Technical Architecture](ARCHITECTURE.md)
