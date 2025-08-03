# 🤖 Telegram Bot Template

Production-ready Telegram bot template with PostgreSQL integration, Docker containerization, and automated CI/CD deployment.

## 🚀 Quick Start with Template

### 1. Create Repository from Template

1. Click **"Use this template"** button on GitHub
2. Create your new repository
3. Clone the repository locally
4. Run the setup script:

```bash
# Make setup script executable
chmod +x scripts/setup-template.sh

# Run interactive setup
./scripts/setup-template.sh
```

The setup script will:

- Ask for your project name and details
- Replace all placeholder names throughout the codebase
- Update Docker configurations
- Create a customized README
- Clean up template-specific files

### 2. Configure Your Bot

```bash
# Set your bot token (get from @BotFather)
echo "BOT_TOKEN=your_bot_token_here" >> .env

# Start development environment
docker compose up -d
```

### 3. Test Your Bot

Send `/start` to your bot → should respond with personalized greeting

## 📋 What's Included

### 🏗️ Architecture

- **Modern aiogram 3.0+** with Router pattern
- **Service Layer** with dependency injection
- **SQLAlchemy 2.0** async ORM with PostgreSQL
- **FastAPI** webhook server for production
- **Redis caching** with memory fallback
- **Prometheus metrics** collection

### 🐳 Infrastructure

- **Docker Compose** for full containerization
- **GitHub Actions** CI/CD pipeline
- **VPS deployment** optimized for 2GB RAM
- **Health checks** and monitoring
- **Database migrations** with Alembic

### 🔧 Development Tools

- **Structured logging** with JSON output
- **Code formatting** with Ruff
- **Type hints** throughout
- **Comprehensive testing** suite
- **VS Code** configuration

## 🛠️ Template Features

### Auto-Configuration

The setup script automatically configures:

- **Project names** throughout all files
- **Docker container** and network names
- **Database** names and users
- **GitHub Actions** workflow
- **Documentation** updates

### Production Ready

- **Memory optimization** for 2GB VPS
- **Connection pooling** tuned for performance
- **Rate limiting** and security middleware
- **Structured logging** for monitoring
- **Health checks** with metrics

### Developer Experience

- **Hot reload** in development
- **Fast startup** (< 30 seconds)
- **Clear documentation** and examples
- **Testing infrastructure** ready
- **Code quality** tools configured

## 📚 Documentation Structure

After setup, you'll have:

- **README.md** - Project-specific guide
- **docs/DEVELOPMENT.md** - Local development setup
- **docs/DEPLOYMENT.md** - Production deployment
- **docs/ARCHITECTURE.md** - Technical architecture
- **docs/DATABASE.md** - Database schema and models
- **docs/API.md** - Bot commands and handlers

## 🔐 Required Secrets

For GitHub Actions deployment, set these repository secrets:

```
BOT_TOKEN              # From @BotFather
DB_PASSWORD           # Secure database password
VPS_HOST              # Your VPS IP address
VPS_USER              # VPS username
VPS_SSH_KEY           # Private SSH key for VPS
DOCKERHUB_USERNAME    # Docker Hub username
DOCKERHUB_TOKEN       # Docker Hub access token
```

Optional webhook secrets:

```
WEBHOOK_URL           # For webhook mode
WEBHOOK_SECRET_TOKEN  # Webhook security token
```

## 🎯 Customization Points

### Bot Logic

- **Handlers**: `app/handlers/` - Add your bot commands
- **Services**: `app/services/` - Business logic layer
- **Models**: `app/database/models/` - Database entities

### Configuration

- **Settings**: `app/config.py` - Application configuration
- **Environment**: `.env` - Runtime environment variables
- **Docker**: `docker-compose.yml` - Container orchestration

### Deployment

- **CI/CD**: `.github/workflows/deploy.yml` - Automation pipeline
- **Scripts**: `scripts/` - Deployment and utility scripts

## 📈 Performance Specs

- **Memory Usage**: 800MB-1.2GB total
- **Startup Time**: < 30 seconds
- **Response Time**: < 500ms average
- **Deployment**: ~2-3 minutes
- **Concurrent Users**: 100-200 on 2GB VPS

## 🔄 Migration from Hello Bot

If migrating from the original Hello Bot:

1. **Backup your data**: Export user database
2. **Update configuration**: Run setup script with your names
3. **Restore data**: Import to new database structure
4. **Test thoroughly**: Verify all functionality

## 🤝 Contributing to Template

To improve this template:

1. Fork the repository
2. Make your improvements
3. Test with the setup script
4. Submit a pull request

Keep template features **generic** and **configurable**.

## 📄 License

MIT License - use freely for your projects.

---

**🎉 Happy bot building!** This template provides everything you need for a production-ready Telegram bot.
