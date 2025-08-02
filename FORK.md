# Fork Setup Instructions for **Hello-Bot** Deploy Testing

## Project Overview

**Hello-Bot** is a Telegram bot for resume management and cover letter generation using OpenAI API. This document provides instructions for creating a minimal deployment testing prototype.

## Current Architecture

### Core Components

- **Main Bot** (`bot.py`) - Telegram bot interface with aiogram
- **Cover Letter Module** (`cover_letter/`) - OpenAI-powered letter generation
- **Data Storage** (`data/resumes.json`) - Simple JSON-based resume storage
- **Debug Server** (`debug_server.py`) - FastAPI server for prompt testing
- **Test Suite** (`tests/`) - Comprehensive test coverage

### Technology Stack

- **Runtime**: Python 3.11+
- **Package Manager**: uv (ultra-fast Python package installer)
- **Telegram Framework**: aiogram 3.0+
- **AI Integration**: OpenAI API 1.0+
- **Data Validation**: Pydantic 2.0+
- **Environment Management**: python-dotenv
- **Development Tools**: basedpyright, ruff, pytest

## Minimal Deployment Test Bot

### Core Dependencies

```toml
[project]
dependencies = [
    "aiogram>=3.0.0",
    "python-dotenv>=1.0.0",
]

[dependency-groups]
dev = [
    "ruff>=0.12.4",
]
```

### Simple Bot Code (`simple_bot.py`)

```python
import asyncio
import logging
import os
from aiogram import Bot, Dispatcher, types
from aiogram.filters import Command
from dotenv import load_dotenv

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

# Initialize bot
bot_token = os.getenv("BOT_TOKEN")
if not bot_token:
    raise ValueError("BOT_TOKEN environment variable is required")

bot = Bot(token=bot_token)
dp = Dispatcher()

@dp.message(Command("start"))
async def start_handler(message: types.Message) -> None:
    """Handle /start command."""
    username = message.from_user.username if message.from_user else "Unknown"
    await message.answer(f"Hello world, ***{username}***")

async def main() -> None:
    """Main function to start the bot."""
    logger.info("Starting simple deployment test bot")
    try:
        await dp.start_polling(bot)
    except Exception as e:
        logger.error(f"Bot failed to start: {e}", exc_info=True)
        raise

if __name__ == "__main__":
    asyncio.run(main())
```

## Setup Instructions

### 1. Bootstrap New Repository

```bash
# Create new directory
mkdir hello_bot-deploy-test
cd hello_bot-deploy-test

# Initialize git
git init
```

### 2. Install uv Package Manager

```bash
# macOS/Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# Or using pip
pip install uv

# Verify installation
uv --version
```

### 3. Create Project Structure

```bash
# Create project files
touch pyproject.toml
touch simple_bot.py
touch .env
touch .gitignore
```

### 4. Configure pyproject.toml

```toml
[build-system]
requires = ["setuptools>=45", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "hello-bot-deploy-test"
version = "0.1.0"
description = "Minimal Telegram bot for deployment testing"
requires-python = ">=3.11"
dependencies = [
    "aiogram>=3.0.0",
    "python-dotenv>=1.0.0",
]

[dependency-groups]
dev = [
    "ruff>=0.12.4",
]

[tool.ruff]
line-length = 100
target-version = "py311"

[tool.ruff.lint]
select = ["E", "F", "W"]
ignore = ["E501"]
```

### 5. Configure Environment

Create `.env` file:

```env
BOT_TOKEN=your_telegram_bot_token_here
```

Create `.gitignore`:

```gitignore
# Environment
.env
.env.local

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Virtual environments
.venv/
venv/
ENV/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# uv
uv.lock
```

### 6. Install Dependencies

```bash
# Install project dependencies
uv sync

# Or install manually
uv add aiogram python-dotenv
uv add --dev ruff
```

### 7. Create Bot Token

1. Message @BotFather on Telegram
2. Send `/newbot`
3. Follow instructions to create bot
4. Copy token to `.env` file

### 8. Run the Bot

```bash
# Using uv (recommended)
uv run python simple_bot.py

# Or direct Python (if in activated venv)
python simple_bot.py
```

### 9. Test Deployment

1. Start the bot
2. Find your bot on Telegram
3. Send `/start` command
4. Verify response: `Hello world, ***your_username***`

## Development Commands

### Format Code

```bash
uv run ruff format .
```

### Lint Code

```bash
uv run ruff check . --fix
```

### Check Dependencies

```bash
uv tree
```

## Deployment Considerations

### Environment Variables

- `BOT_TOKEN` - Required Telegram bot token
- Optional: `LOG_LEVEL` for logging configuration

### Resource Requirements

- **RAM**: ~50MB minimum
- **CPU**: Minimal (single core sufficient)
- **Storage**: ~100MB including Python environment
- **Network**: HTTPS access to Telegram API

### Production Checklist

- [ ] Bot token configured
- [ ] Logging properly configured
- [ ] Process management (systemd/supervisord)
- [ ] Error monitoring
- [ ] Health check endpoint (if needed)
- [ ] Graceful shutdown handling

## Migration Path to Full System

To upgrade to the full hello-bot system:

1. **Add OpenAI Integration**:

   ```bash
   uv add openai pydantic
   ```

2. **Copy Cover Letter Module**:

   ```bash
   cp -r ../hello-bot/cover_letter/ .
   ```

3. **Update Bot Code**:

   - Replace `simple_bot.py` with full `bot.py`
   - Add resume storage functionality
   - Add cover letter generation handlers

4. **Add Testing**:

   ```bash
   uv add --dev pytest pytest-asyncio pytest-cov
   mkdir tests
   cp -r ../hello-bot/tests/ .
   ```

5. **Add Development Tools**:
   ```bash
   uv add --dev basedpyright
   ```

## Troubleshooting

### Common Issues

1. **Bot Not Responding**:

   - Check BOT_TOKEN is correct
   - Verify bot is not already running elsewhere
   - Check network connectivity

2. **uv Command Not Found**:

   - Restart terminal after installation
   - Check PATH environment variable
   - Install using pip as fallback

3. **Permission Errors**:

   - Ensure write permissions in project directory
   - Check Python installation permissions

4. **Import Errors**:
   - Run `uv sync` to install dependencies
   - Verify Python version (3.11+ required)

### Debug Commands

```bash
# Check uv status
uv --version

# List installed packages
uv pip list

# Check Python environment
uv run python --version

# Verbose bot execution
uv run python simple_bot.py --verbose
```

## Performance Notes

- **uv advantages**: 10-100x faster than pip for dependency resolution
- **Minimal footprint**: Simple bot uses ~30MB RAM
- **Fast startup**: ~2-3 seconds cold start
- **Deployment size**: ~50MB including dependencies

This minimal setup provides a solid foundation for testing deployment pipelines while maintaining compatibility with the full **Hello bot 👋** architecture.
