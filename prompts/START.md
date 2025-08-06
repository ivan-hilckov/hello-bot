# Create New Telegram Bot from Hello Bot Template

You are helping create a new Telegram bot based on the Hello Bot template. This template uses a simplified architecture (~320 lines) optimized for rapid development and AI collaboration.

## Bot Specification

**Fill in the following details for your new bot:**

### Basic Information
- **Bot Name**: [e.g., "Weather Bot", "Task Manager Bot"]
- **Bot Username**: [e.g., @weatherhelper_bot]
- **Description**: [One sentence describing what the bot does]
- **Bot ID**: HB-[next number] (e.g., HB-001 for first bot from template)

### Core Functionality
**Primary Features** (1-3 main features):
1. [Feature 1 - e.g., "Get current weather for any city"]
2. [Feature 2 - e.g., "Save favorite locations"]
3. [Feature 3 - optional]

**Commands**:
- `/start` - Welcome message and user registration
- [Add 2-4 main commands your bot will handle]

### Technical Requirements
- **Database Tables**: User + [additional tables needed]
- **External APIs**: [List any APIs you'll integrate]
- **Special Dependencies**: [Any additional Python packages]
- **Deployment**: VPS alongside Hello Bot (shared PostgreSQL)

## Development Roadmap

### Phase 1: Setup (30 minutes)
- [ ] Clone Hello Bot template repository
- [ ] Update project name and descriptions
- [ ] Configure environment variables
- [ ] Test basic deployment

### Phase 2: Core Features (2-4 hours)
- [ ] Design database schema for additional tables
- [ ] Implement main bot commands
- [ ] Add basic error handling
- [ ] Write tests for new functionality

### Phase 3: Enhancement (1-2 hours)
- [ ] Add advanced features
- [ ] Improve user experience
- [ ] Optimize performance
- [ ] Documentation updates

### Phase 4: Production (30 minutes)
- [ ] Deploy to VPS alongside Hello Bot
- [ ] Configure monitoring
- [ ] Test production deployment
- [ ] Update genealogy documentation

## Template Customization Checklist

### Required Changes (Must Do):
- [ ] **Project Name**: Update in `app/config.py` default and `.env` file
- [ ] **Repository Name**: Rename repository to match your bot
- [ ] **Bot Token**: Get new token from @BotFather
- [ ] **Database Name**: Update database URL in environment variables
- [ ] **README.md**: Update title, description, and features list
- [ ] **docker-compose.yml**: Update container names and project name

### Recommended Changes:
- [ ] **Handlers**: Replace greeting message in `app/handlers.py`
- [ ] **Commands**: Add your bot's specific commands
- [ ] **Models**: Add database models for your bot's data
- [ ] **Tests**: Update tests to match your bot's functionality

### Optional Changes:
- [ ] **Logging**: Customize log messages for your domain
- [ ] **Error Messages**: Customize error responses
- [ ] **Documentation**: Add domain-specific documentation

## AI Collaboration Instructions

When working with AI assistants on this bot:

### Context to Provide:
```
This is a Telegram bot built from Hello Bot template with simplified architecture:
- ~320 total lines of code across 5 main files
- Direct database operations (no service layer)
- Async SQLAlchemy 2.0 with PostgreSQL
- aiogram 3.0+ for Telegram API
- Simple middleware for database sessions
- Production deployment via Docker and GitHub Actions

Current bot purpose: [YOUR BOT DESCRIPTION]
Target features: [YOUR FEATURE LIST]
```

### Effective Prompts:
- "Add a new command `/weather <city>` that fetches weather data"
- "Create a UserLocation model to store user's favorite cities"
- "Add error handling for invalid city names"
- "Write tests for the weather command functionality"

### Architecture Constraints:
- Keep total codebase under 400 lines
- Use direct database operations in handlers
- No service layer or complex abstractions
- Simple error handling with standard logging
- One file per major component

## File Structure After Customization

```
your-bot/
├── app/
│   ├── config.py          # Settings with your project name
│   ├── database.py        # Models including your custom tables
│   ├── handlers.py        # Your bot's command handlers
│   ├── middleware.py      # Database middleware (unchanged)
│   └── main.py           # Entry point (minimal changes)
├── prompts/              # AI collaboration templates
├── tests/                # Tests for your bot's functionality
├── docs/                 # Documentation (update as needed)
└── README.md            # Updated with your bot's information
```

## Bot Genealogy

Add this to your new bot's README.md:

```markdown
## Bot Genealogy
- **Parent Template**: Hello Bot Template
- **Bot ID**: [YOUR BOT ID]
- **Created**: [DATE]
- **Purpose**: [YOUR BOT DESCRIPTION]
- **GitHub**: [YOUR REPOSITORY URL]
```

## Success Criteria

Your bot is ready when:
- [ ] All tests pass (`uv run pytest tests/ -v`)
- [ ] Deploys successfully to VPS alongside Hello Bot
- [ ] Core commands work as expected
- [ ] Database operations function correctly
- [ ] AI assistants understand the codebase for future development

## Example Implementation

For reference, here's how a Weather Bot might be structured:

**New commands in `app/handlers.py`:**
```python
@router.message(Command("weather"))
async def weather_handler(message: types.Message, session: AsyncSession) -> None:
    """Get weather for specified city."""
    # Implementation here

@router.message(Command("favorites"))
async def favorites_handler(message: types.Message, session: AsyncSession) -> None:
    """Show user's favorite cities."""
    # Implementation here
```

**New model in `app/database.py`:**
```python
class UserLocation(Base, TimestampMixin):
    """User's favorite weather locations."""
    __tablename__ = "user_locations"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    city_name: Mapped[str] = mapped_column(String(100))
    country_code: Mapped[str] = mapped_column(String(2))
```

Now start building your bot! Use the other prompt templates in this directory for specific development tasks.