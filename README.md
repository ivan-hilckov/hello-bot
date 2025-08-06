# Hello Bot Template 🚀

**Production-ready GitHub template for rapid Telegram bot development with AI-assisted evolution.**

A complete, working Telegram bot optimized for AI collaboration with Claude, Cursor, and other coding assistants. Deploy your first bot in minutes, then evolve it into anything you need.

## 🎯 Why This Template?

- ✅ **AI-Optimized**: Designed for collaboration with Claude, Cursor, and ChatGPT
- ✅ **Production Ready**: Deploy to VPS with single `git push`
- ✅ **Simple Architecture**: ~320 lines, easy to understand and modify
- ✅ **Resource Efficient**: Shared PostgreSQL, optimized for 2GB VPS
- ✅ **Template System**: Built-in prompts for systematic bot evolution

## 🚀 Quick Start

### 1. Use This Template
- Click **"Use this template"** → **"Create a new repository"**
- Clone your new repository locally

### 2. Setup Development Environment

**Prerequisites**: [uv](https://docs.astral.sh/uv/getting-started/installation/) (Python package manager)

```bash
# Clone your new repository
git clone https://github.com/your-username/your-bot-name
cd your-bot-name

# Setup Python environment
uv sync

# Configure environment
cp .env.example .env
# Edit .env with your bot token from @BotFather
```

### 3. Get Bot Token
- Message [@BotFather](https://t.me/botfather) → `/newbot` → copy token
- Add to `.env`: `BOT_TOKEN=your_token_here`

### 4. Start Development
```bash
# Start development environment
docker compose -f docker-compose.dev.yml up -d

# View logs  
docker compose -f docker-compose.dev.yml logs -f bot-dev
```

### 5. Verify Setup
- Send `/start` to your bot → should respond with personalized greeting
- User record automatically created in PostgreSQL database

## 🤖 AI-Assisted Development

### Ready for AI Collaboration
This template is optimized for working with AI coding assistants:

**Step 1**: Read [`prompts/START.md`](prompts/START.md) - main template for creating new bots  
**Step 2**: Use [`.cursorrules`](.cursorrules) - Cursor AI context file  
**Step 3**: Reference [`CLAUDE.md`](CLAUDE.md) - Claude collaboration guide

### AI Collaboration Prompts
- **[`prompts/START.md`](prompts/START.md)** - Create new bot from template
- **[`prompts/add_feature.md`](prompts/add_feature.md)** - Add new features systematically  
- **[`prompts/analyze_file.md`](prompts/analyze_file.md)** - Code review and optimization
- **[`prompts/simplify_code.md`](prompts/simplify_code.md)** - Refactoring and cleanup

### Example AI Workflow
```
1. Use template → customize with prompts/START.md
2. Add features → follow prompts/add_feature.md  
3. Code review → use prompts/analyze_file.md
4. Optimize → apply prompts/simplify_code.md
5. Deploy → git push origin main
```

### Bot Evolution System
- **HB-001**: Your first bot from this template
- **HB-002**: Evolved version with new features
- **HB-003**: Advanced bot with specialized functionality
- Track genealogy in README for systematic development

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

## 🛠️ Technology Stack

### Core Dependencies
- **[aiogram](https://docs.aiogram.dev/)** - Modern async Telegram Bot API framework
- **[SQLAlchemy](https://docs.sqlalchemy.org/)** - Async PostgreSQL ORM with type safety
- **[FastAPI](https://fastapi.tiangolo.com/)** - High-performance webhook server
- **[Pydantic](https://docs.pydantic.dev/)** - Data validation and settings management
- **[uvicorn](https://www.uvicorn.org/)** - Lightning-fast ASGI server

### Development Tools  
- **[uv](https://docs.astral.sh/uv/)** - Ultra-fast Python package manager
- **[ruff](https://docs.astral.sh/ruff/)** - Extremely fast Python linter and formatter
- **[pytest](https://docs.pytest.org/)** - Testing framework with async support

### Infrastructure
- **[Docker](https://docs.docker.com/)** - Containerization for consistent environments
- **[PostgreSQL](https://www.postgresql.org/docs/)** - Reliable, powerful database
- **[GitHub Actions](https://docs.github.com/en/actions)** - CI/CD automation

### Performance Optimizations
- **[uvloop](https://github.com/MagicStack/uvloop)** - Ultra-fast asyncio event loop
- **[asyncpg](https://magicstack.github.io/asyncpg/)** - High-performance PostgreSQL driver

*Full technology reference: [`docs/TECHNOLOGIES.md`](docs/TECHNOLOGIES.md)*

## Commands

| Command  | Description                                       |
| -------- | ------------------------------------------------- |
| `/start` | Get personalized greeting + save user to database |

## Documentation

- **[Development Setup](docs/DEVELOPMENT.md)** - Local development environment
- **[Production Deployment](docs/DEPLOYMENT.md)** - VPS deployment guide
- **[Architecture](docs/ARCHITECTURE.md)** - Technical architecture & dependencies
- **[Technologies](docs/TECHNOLOGIES.md)** - Complete technology stack reference
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

## 🔧 Development Setup

### VS Code + Cursor Setup
This template includes optimized settings for AI-assisted development:

**Recommended Extensions:**
```
charliermarsh.ruff                    # Python linting/formatting
ms-python.python                     # Python support
anthropic.claude-code                 # Claude AI integration  
anysphere.cursorpyright              # Enhanced Python typing
ms-azuretools.vscode-docker          # Docker support
github.vscode-github-actions         # GitHub Actions support
mikestead.dotenv                     # .env file support
yzhang.markdown-all-in-one           # Markdown editing
```

**Auto-configuration included:**
- `.vscode/settings.json` - Optimized editor settings
- `.vscode/tasks.json` - Pre-configured development tasks
- `.cursorrules` - Cursor AI context and instructions

### Development Commands

```bash
# Environment setup
uv sync                               # Install dependencies

# Development
docker compose -f docker-compose.dev.yml up -d    # Start with hot reload
docker compose -f docker-compose.dev.yml logs -f bot-dev  # View logs

# Code quality  
uv run ruff format .                  # Format code
uv run ruff check . --fix             # Lint and fix issues
uv run pytest tests/ -v               # Run tests

# VS Code tasks (Ctrl+Shift+P → "Tasks: Run Task")
🚀 Start Dev Environment             # Clean development startup
🧪 Run Tests                         # Execute test suite  
🔧 Format & Lint Code                # Code quality check
✅ Full Quality Check                 # Complete CI/CD simulation
```

### Local Development Workflow

1. **Setup**: `uv sync` → `cp .env.example .env` → add bot token
2. **Start**: Use VS Code task "🚀 Start Dev Environment" or `docker compose -f docker-compose.dev.yml up -d`
3. **Code**: Edit files → auto-reload → test changes immediately
4. **Quality**: Use "🔧 Format & Lint Code" task before commits
5. **Deploy**: `git push origin main` → auto-deploy to VPS

## License

MIT License
