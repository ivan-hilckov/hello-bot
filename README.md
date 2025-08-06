# Hello Bot

Simple Telegram bot with PostgreSQL integration and automated deployment.

## Quick Start

### 1. Get Bot Token

- Message [@BotFather](https://t.me/botfather) → `/newbot` → copy token

### 2. Configure Environment

```bash
# Clone repository
git clone <repository>
cd hello-bot

# Copy and configure environment
cp .env.example .env
```

**Edit `.env` with required values:**

```env
BOT_TOKEN=your_telegram_bot_token_from_botfather
DB_PASSWORD=secure_local_password
ENVIRONMENT=development
DEBUG=true
```

### 3. Start Development Environment

```bash
# Start all services (PostgreSQL + Bot)
docker compose up -d

# View logs to verify startup
docker compose logs -f bot
```

### 4. Verify Setup

- **Test Bot**: Send `/start` to your bot → should respond with personalized greeting
- **Check Services**: `docker compose ps` → all services should be running
- **View Database**: User record should be created automatically

### 5. Development Commands

```bash
# Code formatting & linting
uv run ruff format .
uv run ruff check . --fix

# Database migrations
alembic upgrade head

# Restart after code changes
docker compose restart bot
```

## Features

- **Simple & Fast**: Responds to `/start` command with user database integration
- **Clean Architecture**: Straightforward code structure (~320 lines total)
- **Production Ready**: Docker containerization + shared PostgreSQL + automated deployment
- **Resource Optimized**: Shared PostgreSQL reduces database memory by 33-60%
- **Auto Deploy**: Push to `main` → automatically deploys to VPS via GitHub Actions

## Architecture

```
Development Mode          Production Mode (Shared PostgreSQL)
┌─────────────────┐      ┌─────────────────────┐
│ Bot polls       │      │ Telegram → Simple   │
│ Telegram API    │      │ Webhook Endpoint    │
└─────────────────┘      └─────────────────────┘
        │                          │
        └──────────┬─────────────────┘
                   │
            ┌─────────────┐
            │ aiogram     │
            │ Router      │
            └─────────────┘
                   │
            ┌─────────────┐
            │ Simple      │
            │ Handlers    │
            └─────────────┘
                   │
    ┌──────────────┼──────────────┐
    │              │              │
┌───▼───┐      ┌───▼───┐      ┌───▼───┐
│Bot1_DB│      │Bot2_DB│      │Bot3_DB│
└───────┘      └───────┘      └───────┘
    │              │              │
    └──────────────┼──────────────┘
                   │
         ┌─────────▼─────────┐
         │ Shared PostgreSQL │
         │    (512MB)        │
         └───────────────────┘
```

## Technology Stack

- **Python 3.12+** with type hints
- **aiogram 3.0+** for Telegram Bot API
- **SQLAlchemy 2.0** async + PostgreSQL
- **Docker Compose** for containerization
- **GitHub Actions** for CI/CD
- **Alembic** for database migrations

## Commands

| Command  | Description                                       |
| -------- | ------------------------------------------------- |
| `/start` | Get personalized greeting + save user to database |

## Documentation

- **[Development Setup](docs/DEVELOPMENT.md)** - Local development environment
- **[Production Deployment](docs/DEPLOYMENT.md)** - VPS deployment guide
- **[Architecture](docs/ARCHITECTURE.md)** - Technical architecture & dependencies
- **[Database](docs/DATABASE.md)** - Database models & schema
- **[Bot API](docs/API.md)** - Bot commands & handlers
- **[Working with Claude](CLAUDE.md)** - AI assistant collaboration guide

## Performance

- **Memory Usage**: 128-200MB per bot (shared PostgreSQL optimization)
- **Database Memory**: 512MB shared across all bots (33-60% savings)
- **Startup Time**: <10 seconds (shared database already running)
- **Response Time**: <300ms
- **Deployment Time**: ~1-2 minutes (shared infrastructure)

## Environment Variables

```env
BOT_TOKEN=your_telegram_bot_token    # Required
DB_PASSWORD=secure_password_123      # Required for production
POSTGRES_ADMIN_PASSWORD=admin_pass   # Required for shared PostgreSQL
ENVIRONMENT=development              # development/production
DEBUG=true                          # true/false
WEBHOOK_URL=https://domain.com/webhook  # Optional for production
```

## Development Commands

```bash
# Local development (simplified)
docker compose -f docker-compose.dev.yml up     # Start development
docker compose -f docker-compose.dev.yml down   # Stop development
# OR use simplified script:
./scripts/start_dev_simple.sh    # Start with hot reload

# Code quality
uv run ruff format .              # Format code
uv run ruff check . --fix         # Lint code

# Database
alembic upgrade head              # Apply migrations
alembic revision --autogenerate   # Create migration
```

## License

MIT License
