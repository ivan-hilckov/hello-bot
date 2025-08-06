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
DB_PASSWORD=local_password_123
ENVIRONMENT=development
DEBUG=true
```

### 3. Run with Docker (Simplified)

```bash
# Start development with hot reload
./scripts/start_dev_simple.sh

# OR direct command
docker compose -f docker-compose.dev.yml up

# Stop services
docker compose -f docker-compose.dev.yml down
# OR
./scripts/stop_dev.sh
```

**Services Started**:

- **PostgreSQL**: Database server
- **Bot**: Simple Telegram bot with clean architecture
  - Direct database operations
  - Standard Python logging
  - Simple handler structure

### 4. Verify Setup

1. **Test Bot Functionality**:

   - Find your bot in Telegram (search by username)
   - Send `/start` → should respond with personalized greeting
   - User should be stored in database

2. **Check Services**:

   ```bash
   # Verify containers are running
   docker compose -f docker-compose.dev.yml ps

   # Check application logs
   docker compose -f docker-compose.dev.yml logs bot-dev --tail=20
   ```

3. **Verify Database**:

   ```bash
   # Check user creation
   docker compose exec postgres psql -U hello_user -d hello_bot -c "
   SELECT telegram_id, username, first_name, created_at
   FROM users
   ORDER BY created_at DESC
   LIMIT 5;
   "

   # Count total users
   docker compose exec postgres psql -U hello_user -d hello_bot -c "
   SELECT COUNT(*) as total_users FROM users;
   "
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
# Database tables created automatically on startup

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

# Restart services to apply changes (hot reload enabled automatically)
docker compose -f docker-compose.dev.yml restart bot-dev
```

### Database Management

```bash
# Create new migration
# Modify models in app/database.py and restart

# Apply migrations
# Database tables created automatically on startup

# View current migration
# Check database tables: SELECT * FROM information_schema.tables;

# Reset database (DESTRUCTIVE)
docker compose -f docker-compose.dev.yml down -v
docker compose -f docker-compose.dev.yml up -d
```

### Useful Commands

```bash
# Rebuild containers after code changes
docker compose -f docker-compose.dev.yml build --no-cache

# View container resources
docker stats

# Clean up Docker
docker system prune -f

# View all services status
docker compose -f docker-compose.dev.yml ps

# Follow logs for specific service
docker compose -f docker-compose.dev.yml logs -f bot-dev
docker compose -f docker-compose.dev.yml logs -f postgres
```

## Development vs Production

| Feature             | Development                             | Production                              |
| ------------------- | --------------------------------------- | --------------------------------------- |
| **Mode**            | Polling (bot asks Telegram for updates) | Webhook (Telegram sends updates to bot) |
| **Database**        | Local PostgreSQL container             | Remote PostgreSQL on VPS               |
| **Logging**         | Human-readable format, DEBUG level     | Standard format, INFO level             |
| **Operations**      | Direct database operations              | Direct database operations              |
| **Resource Limits** | None                                    | Memory/CPU limits for VPS               |
| **Testing**         | Simple test suite available            | Tested before deployment                |

## Testing

Simple testing for the simplified architecture:

### Running Tests

```bash
# Run all tests
uv run pytest

# Run tests with coverage
uv run pytest --cov=app

# Run with verbose output
uv run pytest -v
```

### Test Structure

```bash
tests/
├── conftest.py          # Test fixtures and setup
├── test_handlers.py     # Handler testing
└── test_database.py     # Database operations testing
```

### Test Features

- **SQLite in-memory database** for fast isolated tests
- **Mock Telegram objects** for handler testing
- **Async test support** with pytest-asyncio
- **Direct database testing** without service layer

### Simple Testing Example

```python
@pytest.mark.asyncio
async def test_start_handler(test_session):
    # Test direct handler function
    message = create_mock_message("/start")
    await start_handler(message, test_session)

    # Verify user created
    user = await test_session.get(User, message.from_user.id)
    assert user is not None
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
DB_PASSWORD=local_password_123

# Development settings
ENVIRONMENT=development
DEBUG=true

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

- **Add Features**: Extend bot with new commands in `app/handlers.py`
- **Database Changes**: Add models to `app/database.py` and create migrations
- **Production Deploy**: Follow [Deployment Guide](DEPLOYMENT.md)
- **Architecture**: Read [Technical Architecture](ARCHITECTURE.md)
