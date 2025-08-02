# Hello Bot Deploy Test

Minimal Telegram bot for deployment testing, based on the [hello-bot](https://github.com/ivan-hilckov/hello-bot) project.

## Quick Start

1. **Setup bot token**:

   ```bash
   cp .env.example .env
   # Edit .env and add your BOT_TOKEN
   ```

2. **Install dependencies**:

   ```bash
   uv sync
   ```

3. **Run the bot**:

   ```bash
   make run
   ```

4. **Test**: Send `/start` to your bot on Telegram

## Commands

- `make install` - Install dependencies
- `make run` - Run the bot
- `make format` - Format code
- `make check` - Lint code
- `make clean` - Clean cache files

## Features

- Responds to `/start` with "Hello world, **_username_**"
- Minimal dependencies (aiogram + python-dotenv)
- Ready for deployment testing

See `FORK.md` for detailed setup instructions and migration path to full **Hello-Bot** system.
