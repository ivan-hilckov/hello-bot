#!/bin/bash
# Template Setup Script
# This script initializes a new Telegram bot project from the template

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DEFAULT_PROJECT_NAME="my-telegram-bot"
DEFAULT_BOT_NAME="MyBot"
DEFAULT_DB_NAME="mybot"
DEFAULT_DB_USER="mybot_user"
DEFAULT_CONTAINER_PREFIX="mybot"

echo -e "${BLUE}🤖 Telegram Bot Template Setup${NC}"
echo "This script will configure your new bot project"
echo

# Function to prompt for input with default
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local result
    
    echo -ne "${YELLOW}$prompt${NC} (default: ${BLUE}$default${NC}): "
    read result
    echo "${result:-$default}"
}

# Function to validate project name
validate_project_name() {
    local name="$1"
    if [[ ! "$name" =~ ^[a-z0-9-]+$ ]]; then
        echo -e "${RED}❌ Error: Project name must contain only lowercase letters, numbers, and hyphens${NC}"
        return 1
    fi
    return 0
}

# Function to convert to different naming conventions
to_snake_case() {
    echo "$1" | sed 's/-/_/g'
}

to_pascal_case() {
    echo "$1" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))} 1' | sed 's/ //g'
}

to_title_case() {
    echo "$1" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))} 1'
}

# Collect project information
echo -e "${GREEN}📝 Project Configuration${NC}"
echo

PROJECT_NAME=$(prompt_with_default "Enter project name (kebab-case)" "$DEFAULT_PROJECT_NAME")
while ! validate_project_name "$PROJECT_NAME"; do
    PROJECT_NAME=$(prompt_with_default "Enter project name (kebab-case)" "$DEFAULT_PROJECT_NAME")
done

BOT_NAME=$(prompt_with_default "Enter bot display name" "$(to_title_case "$PROJECT_NAME")")
BOT_DESCRIPTION=$(prompt_with_default "Enter bot description" "A production-ready Telegram bot")

# Generate derived names
PROJECT_SNAKE=$(to_snake_case "$PROJECT_NAME")
PROJECT_PASCAL=$(to_pascal_case "$PROJECT_NAME")
DB_NAME="${PROJECT_SNAKE}_db"
DB_USER="${PROJECT_SNAKE}_user"
CONTAINER_PREFIX="$PROJECT_SNAKE"

echo
echo -e "${GREEN}🔧 Configuration Summary${NC}"
echo "Project Name: $PROJECT_NAME"
echo "Bot Name: $BOT_NAME"
echo "Description: $BOT_DESCRIPTION"
echo "Database: $DB_NAME"
echo "DB User: $DB_USER"
echo "Container Prefix: $CONTAINER_PREFIX"
echo

read -p "Proceed with configuration? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}⚠️  Setup cancelled${NC}"
    exit 0
fi

echo
echo -e "${GREEN}🚀 Configuring project...${NC}"

# Function to replace placeholders in files
replace_in_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        echo "  Updating $file"
        
        # Use temporary file for safe replacement
        local temp_file=$(mktemp)
        
        sed -e "s/hello-bot/$PROJECT_NAME/g" \
            -e "s/hello_bot/$PROJECT_SNAKE/g" \
            -e "s/Hello Bot/$BOT_NAME/g" \
            -e "s/hello_user/$DB_USER/g" \
            -e "s/hello_bot_/$CONTAINER_PREFIX/g" \
            -e "s/hello_bot/$DB_NAME/g" \
            -e "s/Minimal Telegram bot for deployment testing/$BOT_DESCRIPTION/g" \
            "$file" > "$temp_file" && mv "$temp_file" "$file"
    fi
}

# Files to update
FILES_TO_UPDATE=(
    "README.md"
    "pyproject.toml"
    "docker-compose.yml"
    "docker-compose.dev.yml"
    ".github/workflows/deploy.yml"
    "app/config.py"
    "app/main.py"
    "app/handlers/start.py"
    "app/handlers/common.py"
    "alembic.ini"
    "alembic/env.py"
    "scripts/deploy_production.sh"
    "docs/DEVELOPMENT.md"
    "docs/DEPLOYMENT.md"
    "docs/ARCHITECTURE.md"
    "docs/DATABASE.md"
    "docs/API.md"
)

# Update files
for file in "${FILES_TO_UPDATE[@]}"; do
    replace_in_file "$file"
done

# Update handler message to be generic
echo "  Updating bot greeting message"
if [[ -f "app/handlers/start.py" ]]; then
    sed -i.bak 's/Hello world test deploy 🪏🪏🪏/Hello! Welcome to the bot/g' app/handlers/start.py
    rm -f app/handlers/start.py.bak
fi

# Create project-specific .env
echo "  Creating .env file"
cp .env.example .env

# Update README with project-specific information
cat > README.md << EOF
# $BOT_NAME

$BOT_DESCRIPTION

## Quick Start

### 1. Get Bot Token

- Message [@BotFather](https://t.me/botfather) → \`/newbot\` → copy token

### 2. Configure & Run

\`\`\`bash
# Set your bot token in .env file
echo "BOT_TOKEN=your_bot_token_here" >> .env

# Start the bot
docker compose up -d
\`\`\`

### 3. Test

Send \`/start\` to your bot → should respond with personalized greeting

## Features

- **Simple & Fast**: Responds to \`/start\` command with user database integration
- **Production Ready**: Docker containerization + PostgreSQL + health checks
- **Auto Deploy**: Push to \`main\` → automatically deploys to VPS via GitHub Actions
- **Optimized**: Configured for 2GB RAM VPS with performance tuning

## Technology Stack

- **Python 3.12+** with type hints
- **aiogram 3.0+** for Telegram Bot API
- **SQLAlchemy 2.0** async + PostgreSQL
- **FastAPI** for webhook server (production)
- **Docker Compose** for containerization
- **GitHub Actions** for CI/CD
- **Alembic** for database migrations

## Documentation

- **[Development Setup](docs/DEVELOPMENT.md)** - Local development environment
- **[Production Deployment](docs/DEPLOYMENT.md)** - VPS deployment guide
- **[Architecture](docs/ARCHITECTURE.md)** - Technical architecture & dependencies
- **[Database](docs/DATABASE.md)** - Database models & schema
- **[Bot API](docs/API.md)** - Bot commands & handlers

## Development Commands

\`\`\`bash
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
\`\`\`

## Environment Variables

\`\`\`env
BOT_TOKEN=your_telegram_bot_token    # Required
DB_PASSWORD=secure_password_123      # Required for production
ENVIRONMENT=development              # development/production
DEBUG=true                          # true/false
LOG_LEVEL=INFO                      # DEBUG/INFO/WARNING/ERROR
\`\`\`

## License

MIT License
EOF

# Clean up template-specific files
echo "  Cleaning up template files"
rm -f .github/template.yml
rm -f scripts/setup-template.sh

echo
echo -e "${GREEN}✅ Project configured successfully!${NC}"
echo
echo -e "${BLUE}📋 Next Steps:${NC}"
echo "1. Set your BOT_TOKEN in the .env file"
echo "2. Customize your bot logic in app/handlers/"
echo "3. Update documentation as needed"
echo "4. Set up GitHub repository secrets for deployment"
echo
echo -e "${YELLOW}💡 Pro tip:${NC} Check docs/DEVELOPMENT.md for detailed setup instructions"
echo