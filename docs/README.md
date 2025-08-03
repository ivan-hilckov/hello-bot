# Documentation

Complete documentation for Hello Bot production deployment.

## Getting Started

- **[Quick Start Guide](QUICK_START.md)** - Get running in 5 minutes
- **[Local Development](LOCAL_DEVELOPMENT.md)** - Development environment setup
- **[Deployment Guide](DEPLOYMENT.md)** - Production deployment to VPS

## Project Overview

Hello Bot is a production-ready Telegram bot with PostgreSQL database integration, designed for easy deployment and scalability.

### Key Features

- **Modern Architecture**: Python 3.11+, async/await, SQLAlchemy 2.0
- **Database Integration**: PostgreSQL with automatic migrations
- **Container Ready**: Docker and Docker Compose optimized
- **CI/CD Ready**: GitHub Actions integration
- **VPS Optimized**: Tuned for 2GB RAM servers
- **Production Ready**: Health checks, logging, graceful shutdown

### Technology Stack

- **Backend**: Python 3.11+, aiogram 3.0+, SQLAlchemy 2.0 async
- **Database**: PostgreSQL 15 Alpine
- **Containerization**: Docker + Docker Compose
- **Configuration**: Pydantic Settings
- **Migrations**: Alembic
- **Package Management**: uv (ultra-fast)

## Documentation Structure

### User Guides

| Document                                  | Purpose                  | Audience      |
| ----------------------------------------- | ------------------------ | ------------- |
| [Quick Start](QUICK_START.md)             | Get running in 5 minutes | All users     |
| [Local Development](LOCAL_DEVELOPMENT.md) | Development setup        | Developers    |
| [Deployment](DEPLOYMENT.md)               | Production deployment    | DevOps/Admins |

### Technical Information

| Topic            | Coverage                                      |
| ---------------- | --------------------------------------------- |
| **Architecture** | Modular app structure, async patterns         |
| **Database**     | PostgreSQL setup, migrations, models          |
| **Docker**       | Containerization, health checks, optimization |
| **CI/CD**        | GitHub Actions, automated deployment          |
| **Monitoring**   | Logging, health checks, performance           |
| **Security**     | Best practices, secrets management            |

## Quick Reference

### Essential Commands

```bash
# Start locally
docker compose up -d

# View logs
docker compose logs -f

# Deploy to production
git push origin main

# Check health
./scripts/health_check.sh
```

### Environment Variables

| Variable       | Purpose               | Required         |
| -------------- | --------------------- | ---------------- |
| `BOT_TOKEN`    | Telegram bot token    | Yes              |
| `DATABASE_URL` | PostgreSQL connection | Auto-generated   |
| `DB_PASSWORD`  | Database password     | Yes (production) |
| `ENVIRONMENT`  | dev/production        | No               |
| `LOG_LEVEL`    | Logging verbosity     | No               |

### Project Structure

```
hello-bot/
├── app/                    # Main application
│   ├── config.py          # Configuration
│   ├── main.py            # Entry point
│   ├── database/          # Database layer
│   ├── handlers/          # Message handlers
│   └── middlewares/       # Middleware
├── alembic/               # Database migrations
├── docs/                  # Documentation
├── scripts/               # Deployment scripts
├── docker-compose.yml     # Container orchestration
└── Dockerfile             # Container definition
```

## Support and Troubleshooting

### Common Issues

- **Bot not responding**: Check `BOT_TOKEN` in environment
- **Database errors**: Verify PostgreSQL connection
- **Memory issues**: Monitor resource usage on VPS
- **Deployment failures**: Check GitHub Actions logs

### Getting Help

1. Check relevant documentation section
2. Review logs: `docker compose logs -f`
3. Verify configuration: `docker compose config`
4. Test locally before production deployment

### Performance Expectations

- **Memory Usage**: 800MB-1.2GB (optimized for 2GB VPS)
- **Startup Time**: <30 seconds
- **Response Time**: <500ms for commands
- **Uptime**: 99.9%+

## Development Workflow

1. **Local Setup**: Follow [Local Development](LOCAL_DEVELOPMENT.md)
2. **Code Changes**: Edit in `app/` directory
3. **Testing**: Test locally with Docker
4. **Deployment**: Push to `main` branch for auto-deploy

## Contributing

When contributing:

1. Follow existing code style (Ruff formatting)
2. Add type hints for new functions
3. Update documentation for new features
4. Test locally before submitting PR

## Version History

- **v0.1.0**: Initial production-ready version
  - PostgreSQL integration
  - Docker containerization
  - GitHub Actions CI/CD
  - VPS optimization

---

For quick questions, start with the [Quick Start Guide](QUICK_START.md).

For development, see [Local Development](LOCAL_DEVELOPMENT.md).

For production deployment, follow the [Deployment Guide](DEPLOYMENT.md).
