# Template Usage Guide

Detailed guide for using this repository as a GitHub template for Telegram bot projects.

## 🎯 Template Overview

This template provides a complete, production-ready foundation for Telegram bots with:

- **Modern Python 3.12+** architecture
- **aiogram 3.0+** framework with Router pattern
- **PostgreSQL** database with async SQLAlchemy 2.0
- **Docker** containerization for all environments
- **GitHub Actions** CI/CD pipeline
- **VPS deployment** optimization

## 🚀 Getting Started

### Step 1: Create Repository from Template

1. **Navigate** to the template repository on GitHub
2. **Click** the green "Use this template" button
3. **Configure** your new repository:
   - Repository name (e.g., `my-awesome-bot`)
   - Description (e.g., `Customer support bot for my business`)
   - Visibility (public/private)
4. **Create** repository from template

### Step 2: Clone and Setup

```bash
# Clone your new repository
git clone https://github.com/yourusername/your-bot-name.git
cd your-bot-name

# Run the interactive setup script
chmod +x scripts/setup-template.sh
./scripts/setup-template.sh
```

### Step 3: Interactive Configuration

The setup script will prompt for:

```
🤖 Telegram Bot Template Setup
This script will configure your new bot project

📝 Project Configuration

Enter project name (kebab-case) (default: my-telegram-bot): customer-support-bot
Enter bot display name (default: Customer Support Bot): CustomerCare Bot
Enter bot description (default: A production-ready Telegram bot): AI-powered customer support bot

🔧 Configuration Summary
Project Name: customer-support-bot
Bot Name: CustomerCare Bot
Description: AI-powered customer support bot
Database: customer_support_bot_db
DB User: customer_support_bot_user
Container Prefix: customer_support_bot

Proceed with configuration? (y/N): y
```

### Step 4: Automatic Updates

The script will automatically update:

- **Code files**: Replace all placeholder names
- **Configuration**: Docker, GitHub Actions, database settings
- **Documentation**: Generate project-specific docs
- **README**: Create customized project README

## 🔧 Manual Customization

### Bot Logic Customization

After setup, customize your bot:

#### 1. Update Start Handler

```python
# app/handlers/start.py
@start_router.message(Command("start"))
async def start_handler(message: types.Message, user_service: UserService) -> None:
    """Customize your welcome message."""
    if not message.from_user:
        await message.answer("Welcome to our bot!", parse_mode=ParseMode.HTML)
        return

    user = await user_service.get_or_create_user(message.from_user)

    # Customize greeting
    greeting = f"👋 Welcome to CustomerCare Bot, <b>{user.display_name}</b>!\n\n"
    greeting += "I'm here to help you with your questions 24/7."

    await message.answer(greeting, parse_mode=ParseMode.HTML)
```

#### 2. Add New Commands

```python
# app/handlers/support.py
support_router = Router(name="support")

@support_router.message(Command("help"))
async def help_handler(message: types.Message) -> None:
    """Show available commands."""
    help_text = """
🤖 <b>Available Commands:</b>

/start - Welcome message
/help - Show this help
/support - Contact human support
/status - Check service status
    """
    await message.answer(help_text, parse_mode=ParseMode.HTML)

# Include in main.py
from app.handlers.support import support_router
dp.include_router(support_router)
```

#### 3. Add Database Models

```python
# app/database/models/ticket.py
class SupportTicket(Base, TimestampMixin):
    """Support ticket model."""

    __tablename__ = "support_tickets"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    title: Mapped[str] = mapped_column(String(255))
    description: Mapped[str] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(50), default="open")

    # Relationship
    user: Mapped["User"] = relationship("User", back_populates="tickets")
```

### Configuration Customization

#### Environment Variables

```bash
# .env - Add your specific settings
BOT_TOKEN=your_actual_bot_token
PROJECT_NAME=my-awesome-bot  # REQUIRED: Your unique project name
DB_PASSWORD=secure_random_password

# Custom features
OPENAI_API_KEY=your_openai_key  # For AI features
WEBHOOK_URL=https://yourdomain.com/webhook
ADMIN_USER_ID=123456789  # Your Telegram user ID
```

> **⚠️ Critical**: `PROJECT_NAME` must be set both locally and in GitHub Secrets for deployment. This creates unique Docker networks and container names.

#### Docker Configuration

```yaml
# docker-compose.yml - Add services
services:
  # Add Redis for caching
  redis:
    image: redis:7-alpine
    container_name: ${PROJECT_NAME}_redis
    restart: unless-stopped

  # Add monitoring
  prometheus:
    image: prom/prometheus
    container_name: ${PROJECT_NAME}_prometheus
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
```

## 🎨 Customization Examples

### Business Bot Template

```python
# For business/e-commerce bot
@dp.message(Command("catalog"))
async def catalog_handler(message: types.Message):
    """Show product catalog."""
    keyboard = InlineKeyboardBuilder()
    keyboard.add(InlineKeyboardButton(text="📱 Electronics", callback_data="cat_electronics"))
    keyboard.add(InlineKeyboardButton(text="👕 Clothing", callback_data="cat_clothing"))

    await message.answer(
        "🛍️ <b>Our Product Catalog:</b>\n\nChoose a category:",
        reply_markup=keyboard.as_markup(),
        parse_mode=ParseMode.HTML
    )
```

### AI Assistant Template

```python
# For AI-powered assistant
@dp.message(F.text & ~Command())
async def ai_chat_handler(message: types.Message):
    """Process AI chat requests."""
    # Add OpenAI integration
    response = await openai_client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[{"role": "user", "content": message.text}]
    )

    await message.answer(response.choices[0].message.content)
```

### Notification Bot Template

```python
# For notification/broadcast bot
@dp.message(Command("subscribe"))
async def subscribe_handler(message: types.Message, user_service: UserService):
    """Subscribe to notifications."""
    user = await user_service.get_or_create_user(message.from_user)
    user.notifications_enabled = True
    await user_service.update_user(user)

    await message.answer("✅ You're subscribed to notifications!")
```

## 📦 Deployment Customization

### GitHub Actions Secrets

Set up repository secrets for your deployment:

```bash
# Required secrets
BOT_TOKEN              # From @BotFather
DB_PASSWORD           # Secure database password
VPS_HOST              # Your server IP
VPS_USER              # SSH username
VPS_SSH_KEY           # Private SSH key content
DOCKERHUB_USERNAME    # Docker Hub username
DOCKERHUB_TOKEN       # Docker Hub access token

# Optional secrets
WEBHOOK_URL           # For webhook mode
WEBHOOK_SECRET_TOKEN  # Webhook security
ADMIN_CHAT_ID         # For admin notifications
```

### VPS Configuration

```bash
# On your VPS
sudo mkdir -p /opt/your-bot-name
sudo chown $USER:$USER /opt/your-bot-name

# Set up Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

### Custom Deployment Script

```bash
# scripts/deploy_production.sh - Customize deployment
#!/bin/bash

# Add your custom deployment steps
echo "🚀 Deploying Your Bot Name..."

# Custom pre-deployment tasks
./scripts/backup_database.sh

# Standard deployment
docker compose --profile production down
docker compose --profile production pull
docker compose --profile production up -d

# Custom post-deployment tasks
./scripts/send_deploy_notification.sh
```

## 🔍 Testing Your Template

### Local Testing

```bash
# Test all services
docker compose up -d
docker compose logs -f

# Test bot commands
# Send /start to your bot
# Verify database connection
docker compose exec postgres psql -U your_db_user -d your_db_name -c "SELECT * FROM users;"
```

### Production Testing

```bash
# Deploy to staging first
git push origin staging

# Verify health checks
curl https://your-domain.com/health

# Test production deployment
git push origin main
```

## 🛠️ Advanced Customization

### Custom Middleware

```python
# app/middlewares/analytics.py
class AnalyticsMiddleware(BaseMiddleware):
    """Track user interactions."""

    async def __call__(self, handler, event, data):
        # Track message analytics
        await analytics_service.track_event(event)
        return await handler(event, data)
```

### Custom Services

```python
# app/services/analytics.py
class AnalyticsService(BaseService):
    """Analytics and tracking service."""

    async def track_user_action(self, user_id: int, action: str):
        """Track user actions for analytics."""
        # Implementation here
        pass
```

### Environment-Specific Configuration

```python
# app/config.py - Add custom settings
class Settings(BaseSettings):
    # Your custom settings
    openai_api_key: str | None = None
    admin_user_id: int | None = None
    analytics_enabled: bool = True
    max_daily_requests: int = 100
```

## 🐛 Common Issues and Solutions

### Template Setup Issues

**Problem**: Setup script fails

```bash
# Solution: Check permissions
chmod +x scripts/setup-template.sh
# Or run directly
bash scripts/setup-template.sh
```

**Problem**: Database names not updated

```bash
# Solution: Run manual replacement
sed -i 's/hello_bot/your_project_name/g' docker-compose.yml
```

### Deployment Issues

**Problem**: GitHub Actions fails

```bash
# Solution: Check secrets are set
# Go to Settings > Secrets and variables > Actions
# Verify all required secrets are present
```

**Problem**: Docker build fails

```bash
# Solution: Clear cache and rebuild
docker compose build --no-cache
```

## 📚 Additional Resources

- **[aiogram Documentation](https://docs.aiogram.dev/)** - Bot framework docs
- **[SQLAlchemy 2.0](https://docs.sqlalchemy.org/)** - Database ORM
- **[FastAPI Docs](https://fastapi.tiangolo.com/)** - Web framework
- **[Docker Compose](https://docs.docker.com/compose/)** - Container orchestration
- **[GitHub Actions](https://docs.github.com/en/actions)** - CI/CD automation

## 🤝 Contributing

To improve this template:

1. **Fork** the template repository
2. **Make** your improvements
3. **Test** with the setup script
4. **Submit** a pull request

Keep features **generic** and **configurable** for broad use.

---

🎉 **You're ready to build amazing Telegram bots!**
