# Hello Bot

Production-ready Telegram bot with PostgreSQL integration and automated CI/CD deployment.

## Quick Start

### 1. Get Bot Token

- Message [@BotFather](https://t.me/botfather) → `/newbot` → copy token

### 2. Configure & Run

```bash
cp .env.example .env
# Edit .env: add your BOT_TOKEN
docker compose up -d
```

### 3. Test

Send `/start` to your bot → should respond with personalized greeting

## Features

- **Simple & Fast**: Responds to `/start` command with user database integration
- **Production Ready**: Docker containerization + PostgreSQL + health checks
- **Auto Deploy**: Push to `main` → automatically deploys to VPS via GitHub Actions
- **Optimized**: Configured for 2GB RAM VPS with performance tuning

## Architecture

```
Development Mode          Production Mode
┌─────────────────┐      ┌─────────────────────┐
│ Bot polls       │      │ Telegram → Webhook  │
│ Telegram API    │      │ → FastAPI server    │
└─────────────────┘      └─────────────────────┘
        │                          │
        └──────────┬─────────────────┘
                   │
            ┌─────────────┐
            │ aiogram     │
            │ Dispatcher  │
            └─────────────┘
                   │
            ┌─────────────┐
            │ Database    │
            │ Middleware  │
            └─────────────┘
                   │
            ┌─────────────┐
            │ PostgreSQL  │
            │ + User      │
            │ Management  │
            └─────────────┘
```

## Technology Stack

- **Python 3.12+** with type hints
- **aiogram 3.0+** for Telegram Bot API
- **SQLAlchemy 2.0** async + PostgreSQL
- **FastAPI** for webhook server (production)
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

- **Memory Usage**: 800MB-1.2GB (optimized for 2GB VPS)
- **Startup Time**: <30 seconds
- **Response Time**: <500ms
- **Deployment Time**: ~2-3 minutes (optimized from 8-10 minutes)

## Environment Variables

```env
BOT_TOKEN=your_telegram_bot_token    # Required
DB_PASSWORD=secure_password_123      # Required for production
ENVIRONMENT=development              # development/production
DEBUG=true                          # true/false
LOG_LEVEL=INFO                      # DEBUG/INFO/WARNING/ERROR
```

## Development Commands

```bash
# Local development
docker compose up -d              # Start all services
docker compose logs -f            # View logs
docker compose down               # Stop services

# Code quality
uv run ruff format .              # Format code
uv run ruff check . --fix         # Lint code

# Database
alembic upgrade head              # Apply migrations
alembic revision --autogenerate   # Create migration
```

## License

MIT License
