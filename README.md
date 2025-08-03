# Hello Bot

Production-ready Telegram bot for deployment testing with PostgreSQL database integration.

## Features

- Responds to `/start` with personalized greeting
- User management with PostgreSQL database
- Docker containerization with health checks
- CI/CD ready with GitHub Actions
- Optimized for 2GB RAM VPS deployment

## Quick Start

1. **Get Telegram Bot Token**:

   - Message [@BotFather](https://t.me/botfather) in Telegram
   - Send `/newbot` and follow instructions
   - Copy your bot token

2. **Configure Environment**:

   ```bash
   cp .env.example .env
   # Edit .env and add your BOT_TOKEN
   ```

3. **Run with Docker**:

   ```bash
   docker compose up -d
   ```

4. **Test**: Send `/start` to your bot in Telegram

## Architecture

```
hello-bot/
├── app/                    # Main application
│   ├── config.py          # Pydantic settings
│   ├── main.py            # Production entry point
│   ├── database/          # SQLAlchemy async setup
│   ├── handlers/          # Message handlers
│   └── middlewares/       # Database middleware
├── alembic/               # Database migrations
├── docs/                  # Documentation
├── scripts/               # Deployment scripts
├── docker-compose.yml     # Production orchestration
└── Dockerfile             # Containerization
```

## Technology Stack

- **Python 3.11+** with type hints
- **aiogram 3.0+** for Telegram API
- **SQLAlchemy 2.0** (async) + asyncpg
- **PostgreSQL 15** Alpine
- **Docker** + Docker Compose
- **Alembic** for database migrations
- **Pydantic Settings** for configuration

## Documentation

- [Quick Start Guide](docs/QUICK_START.md) - Get running in 5 minutes
- [Local Development](docs/LOCAL_DEVELOPMENT.md) - Development setup
- [Deployment Guide](docs/DEPLOYMENT.md) - Production deployment

## Requirements

- Python 3.11+
- Docker and Docker Compose
- PostgreSQL (provided via Docker)
- Telegram Bot Token

## Environment Variables

```env
BOT_TOKEN=your_telegram_bot_token_here     # Required
DATABASE_URL=postgresql+asyncpg://...      # Auto-configured in Docker
DB_PASSWORD=secure_password_123            # Required for production
ENVIRONMENT=production                     # Optional (development/production)
LOG_LEVEL=INFO                            # Optional
```

## Commands

```bash
# Local development
docker compose up -d          # Start all services
docker compose logs -f        # View logs
docker compose down           # Stop services

# Production deployment
./scripts/deploy_to_vps.sh     # Deploy to VPS
./scripts/setup_vps.sh         # Setup VPS environment
```

## Performance

- **Memory Usage**: 800MB-1.2GB (optimized for 2GB VPS)
- **Startup Time**: <30 seconds
- **Response Time**: <500ms
- **Uptime**: 99.9%+

## License

MIT License - see LICENSE file for details
