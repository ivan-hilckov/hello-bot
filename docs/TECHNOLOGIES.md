# Technology Stack Reference

Complete reference of all technologies, frameworks, and tools used in Hello Bot template.

## Core Technologies

### Python 3.12+
- **Purpose**: Primary programming language
- **Why**: Modern async support, type hints, excellent ecosystem
- **Documentation**: [python.org](https://docs.python.org/3/)
- **Repository**: [github.com/python/cpython](https://github.com/python/cpython)
- **Version**: 3.12+ (for latest async features and performance)

### aiogram 3.0+
- **Purpose**: Telegram Bot API framework
- **Why**: Modern async framework, excellent type safety, active development
- **Documentation**: [docs.aiogram.dev](https://docs.aiogram.dev/)
- **Repository**: [github.com/aiogram/aiogram](https://github.com/aiogram/aiogram)
- **Key Features**: Router system, middleware, webhook support, filters

### SQLAlchemy 2.0
- **Purpose**: Database ORM and query builder
- **Why**: Modern async support, excellent PostgreSQL integration, type safety
- **Documentation**: [docs.sqlalchemy.org](https://docs.sqlalchemy.org/)
- **Repository**: [github.com/sqlalchemy/sqlalchemy](https://github.com/sqlalchemy/sqlalchemy)
- **Pattern**: Async Session, declarative mapping, modern query syntax

### PostgreSQL 15
- **Purpose**: Primary database
- **Why**: Reliability, performance, excellent Python support, JSONB
- **Documentation**: [postgresql.org/docs](https://www.postgresql.org/docs/)
- **Repository**: [github.com/postgres/postgres](https://github.com/postgres/postgres)
- **Features**: ACID compliance, concurrent access, shared container architecture

## Infrastructure & Deployment

### Docker & Docker Compose
- **Purpose**: Containerization and local development
- **Why**: Consistent environments, easy deployment, resource isolation
- **Documentation**: [docs.docker.com](https://docs.docker.com/)
- **Repository**: [github.com/docker](https://github.com/docker)
- **Usage**: Development environments, production deployment, shared PostgreSQL

### GitHub Actions
- **Purpose**: CI/CD pipeline automation
- **Why**: Integrated with GitHub, free for public repos, powerful workflow system
- **Documentation**: [docs.github.com/actions](https://docs.github.com/en/actions)
- **Repository**: [github.com/actions](https://github.com/actions)
- **Workflow**: Test → Build → Deploy → Verify

### FastAPI
- **Purpose**: Webhook server for production mode
- **Why**: Fast, modern, automatic docs, excellent async support
- **Documentation**: [fastapi.tiangolo.com](https://fastapi.tiangolo.com/)
- **Repository**: [github.com/tiangolo/fastapi](https://github.com/tiangolo/fastapi)
- **Usage**: Simple webhook endpoint, health checks



## Development Tools

### uv
- **Purpose**: Modern Python package and project manager
- **Why**: Fast, reliable, modern alternative to pip/poetry
- **Documentation**: [docs.astral.sh/uv](https://docs.astral.sh/uv/)
- **Repository**: [github.com/astral-sh/uv](https://github.com/astral-sh/uv)
- **Features**: Dependency resolution, virtual environments, lock files

### Ruff
- **Purpose**: Code formatting and linting
- **Why**: Extremely fast, combines multiple tools (flake8, black, isort)
- **Documentation**: [docs.astral.sh/ruff](https://docs.astral.sh/ruff/)
- **Repository**: [github.com/astral-sh/ruff](https://github.com/astral-sh/ruff)
- **Usage**: Code formatting, import sorting, style checking

### pytest
- **Purpose**: Testing framework
- **Why**: Excellent async support, powerful fixtures, clear syntax
- **Documentation**: [docs.pytest.org](https://docs.pytest.org/)
- **Repository**: [github.com/pytest-dev/pytest](https://github.com/pytest-dev/pytest)
- **Plugins**: pytest-asyncio, pytest-mock

### asyncpg
- **Purpose**: PostgreSQL async driver
- **Why**: High performance, native async support, excellent SQLAlchemy integration
- **Documentation**: [magicstack.github.io/asyncpg](https://magicstack.github.io/asyncpg/)
- **Repository**: [github.com/MagicStack/asyncpg](https://github.com/MagicStack/asyncpg)
- **Features**: Connection pooling, prepared statements, type conversion

## Configuration & Environment

### Pydantic Settings
- **Purpose**: Configuration management and validation
- **Why**: Type safety, environment variable handling, validation
- **Documentation**: [docs.pydantic.dev](https://docs.pydantic.dev/)
- **Repository**: [github.com/pydantic/pydantic](https://github.com/pydantic/pydantic)
- **Features**: Environment variable parsing, validation, type conversion

### python-dotenv
- **Purpose**: Environment variable management
- **Why**: Development convenience, secure secret handling
- **Documentation**: [pypi.org/project/python-dotenv](https://pypi.org/project/python-dotenv/)
- **Repository**: [github.com/theskumar/python-dotenv](https://github.com/theskumar/python-dotenv)
- **Usage**: Load `.env` files, development configuration

### uvicorn
- **Purpose**: ASGI server for production
- **Why**: High performance, automatic reloading, production-ready
- **Documentation**: [uvicorn.org](https://www.uvicorn.org/)
- **Repository**: [github.com/encode/uvicorn](https://github.com/encode/uvicorn)
- **Usage**: Webhook server, production deployment

## Architecture Integration

### How Technologies Work Together

```
┌─────────────────┐    ┌─────────────────┐
│   Telegram API  │────│   aiogram 3.0   │
└─────────────────┘    └─────────────────┘
                                │
                        ┌───────▼───────┐
                        │   FastAPI     │ (Production)
                        │   Webhook     │
                        └───────────────┘
                                │
                    ┌───────────▼───────────┐
                    │   Hello Bot App       │
                    │   (Python 3.12+)     │
                    └───────────────────────┘
                                │
                        ┌───────▼───────┐
                        │  SQLAlchemy   │
                        │  2.0 Async    │
                        └───────────────┘
                                │
                        ┌───────▼───────┐
                        │  PostgreSQL   │
                        │      15       │
                        └───────────────┘
```

### Development Workflow

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│      uv      │────│     ruff     │────│    pytest   │
│  Dependencies│    │   Formatting │    │   Testing    │
└──────────────┘    └──────────────┘    └──────────────┘
                                               │
                    ┌──────────────────────────▼──────────────────────────┐
                    │              GitHub Actions                          │
                    │  Test → Build → Deploy → Verify                    │
                    └─────────────────────────────────────────────────────┘
                                               │
                    ┌──────────────────────────▼──────────────────────────┐
                    │                  VPS Deployment                     │
                    │            Docker + Shared PostgreSQL               │
                    └─────────────────────────────────────────────────────┘
```

## Version Requirements

| Technology | Minimum Version | Recommended | Notes |
|------------|----------------|-------------|-------|
| Python | 3.12.0 | 3.12.11+ | Modern async features |
| aiogram | 3.0.0 | 3.15.0+ | Router system, latest fixes |
| SQLAlchemy | 2.0.0 | 2.0.36+ | Modern async patterns |
| PostgreSQL | 13.0 | 15.0+ | Performance, features |
| Docker | 20.10 | 27.0+ | Compose v2 support |
| FastAPI | 0.100.0 | 0.115.0+ | Modern async features |

## Performance Characteristics

### Resource Usage (Per Bot Instance)
- **Memory**: 128-200MB (including shared PostgreSQL overhead)
- **CPU**: Low (<5% on 2GB VPS)
- **Disk**: ~50MB (excluding database)
- **Network**: Minimal (polling: ~1KB/s, webhook: event-driven)

### Database Performance
- **Shared PostgreSQL**: 512MB memory for all bots
- **Connection Pool**: 3 connections per bot + 5 overflow
- **Query Performance**: <50ms for simple operations
- **Concurrent Users**: 100+ per bot without issues

### Deployment Performance
- **Build Time**: 2-3 minutes (with cache)
- **Deploy Time**: 30-60 seconds
- **Startup Time**: <10 seconds
- **Health Check**: <5 seconds

## Security Considerations

### Environment Security
- **Secrets**: Stored in GitHub Secrets, environment variables
- **Database**: User isolation, encrypted passwords
- **Containers**: Non-root users, minimal attack surface
- **Network**: Private networks, minimal port exposure

### Code Security
- **Input Validation**: Pydantic models, type hints
- **SQL Injection**: SQLAlchemy ORM protection
- **Async Safety**: Proper session management
- **Error Handling**: No sensitive data in logs

## Troubleshooting Reference

### Common Issues and Solutions

| Issue | Technology | Solution |
|-------|------------|----------|
| Import errors | uv | `uv sync` to install dependencies |
| Database connection | asyncpg/PostgreSQL | Check connection string, container status |
| Bot not responding | aiogram | Verify token, check logs, webhook URL |
| Schema changes | SQLAlchemy | Update models, restart application |
| Build failures | Docker | Check Dockerfile, dependency conflicts |
| Test failures | pytest | Review async patterns, mock configurations |

### Useful Commands

```bash
# Development
uv run ruff format .              # Format code
uv run ruff check . --fix         # Lint and fix
uv run pytest tests/ -v           # Run tests
# Database tables are created automatically on startup

# Docker
docker compose up -d              # Start development
docker compose logs -f bot        # View logs
docker compose down               # Stop services

# Production
git push origin main              # Auto-deploy via GitHub Actions
```

## Learning Resources

### Essential Reading
1. **aiogram 3.0 Guide**: [docs.aiogram.dev/en/latest/dispatcher/router.html](https://docs.aiogram.dev/en/latest/dispatcher/router.html)
2. **SQLAlchemy 2.0 Tutorial**: [docs.sqlalchemy.org/en/20/tutorial/](https://docs.sqlalchemy.org/en/20/tutorial/)
3. **FastAPI Async Guide**: [fastapi.tiangolo.com/async/](https://fastapi.tiangolo.com/async/)
4. **Python Asyncio**: [docs.python.org/3/library/asyncio.html](https://docs.python.org/3/library/asyncio.html)

### Advanced Topics
1. **PostgreSQL Performance**: [postgresql.org/docs/current/performance-tips.html](https://www.postgresql.org/docs/current/performance-tips.html)
2. **Docker Multi-stage Builds**: [docs.docker.com/develop/dev-best-practices/](https://docs.docker.com/develop/dev-best-practices/)
3. **GitHub Actions Optimization**: [docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)

## Migration Guide

### From Hello Bot to Your Bot
1. Keep all core technologies
2. Add domain-specific packages as needed
3. Maintain version compatibility
4. Follow simplified architecture principles
5. Test thoroughly after any technology changes

Remember: Hello Bot's strength comes from using proven, modern technologies in a simple, direct way. Avoid adding unnecessary complexity or exotic tools unless they solve specific problems.