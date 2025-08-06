# START_HELLO_AI_BOT.md

Create **Hello AI Bot (HB-002)** - Telegram bot that forwards user messages to OpenAI API with enhanced role prompts and returns AI-generated responses.

## 🎯 Bot Specification

### Basic Information
- **Bot Name**: Hello AI Bot
- **Bot Username**: @hello_ai_bot (or your preferred username)
- **Description**: Telegram proxy bot that processes user requests through OpenAI API with configurable role enhancement
- **Bot ID**: HB-002 (second generation from Hello Bot Template)
- **Parent Template**: Hello Bot Template (HB-001)

### Core Functionality
**Primary Features**:
1. **AI Proxy**: `/do <text>` command forwards user text to OpenAI API with role enhancement
2. **Role Customization**: Users can set AI personality/role via `/role` command
3. **Conversation History**: Store and retrieve user conversation history
4. **Smart Responses**: Enhanced prompts for better AI responses

**Commands**:
- `/start` - Welcome message and user registration
- `/do <text>` - Process text through OpenAI API with role enhancement
- `/role [role_name]` - Set or view current AI assistant role/personality
- `/history [count]` - Show recent conversation history (default: 5 messages)
- `/models` - List available OpenAI models
- `/clear` - Clear conversation history

### Technical Requirements
- **Database Tables**: User + Conversation + UserRole
- **External APIs**: OpenAI API (GPT-4, GPT-3.5-turbo)
- **Special Dependencies**: `openai>=1.0.0`, `tiktoken` for token counting
- **Deployment**: VPS alongside Hello Bot with shared PostgreSQL
- **Resource Limit**: ~150MB RAM, optimized for shared 2GB VPS

## 🚀 Development Roadmap

### Phase 1: Project Setup (30 minutes)
- [ ] Clone Hello Bot template to new repository `hello-ai-bot`
- [ ] Update project configuration (names, descriptions, environment)
- [ ] Configure OpenAI API key in environment variables
- [ ] Install required dependencies (`openai`, `tiktoken`)
- [ ] Test basic setup and deployment pipeline

### Phase 2: Core AI Integration (2-3 hours)
- [ ] **Database Models**: Add Conversation and UserRole models
- [ ] **OpenAI Integration**: Implement AI service with role enhancement
- [ ] **Main Command**: Create `/do` handler with OpenAI API calls
- [ ] **Error Handling**: Add comprehensive error handling for API failures
- [ ] **Token Management**: Implement token counting and limits

### Phase 3: Enhanced Features (2 hours)
- [ ] **Role System**: Implement `/role` command with predefined personalities
- [ ] **History Management**: Add conversation storage and `/history` command
- [ ] **Model Selection**: Support multiple OpenAI models via `/models`
- [ ] **Rate Limiting**: Implement user rate limits and usage tracking
- [ ] **Advanced Prompting**: Add context-aware role enhancement

### Phase 4: Production Optimization (1 hour)
- [ ] **Performance**: Optimize API calls and database queries
- [ ] **Monitoring**: Add logging for API usage and costs
- [ ] **Security**: Implement input validation and sanitization
- [ ] **Documentation**: Update all documentation for AI bot
- [ ] **Testing**: Create comprehensive test suite

### Phase 5: Deployment (30 minutes)
- [ ] Deploy to VPS alongside Hello Bot (shared PostgreSQL)
- [ ] Configure production environment variables
- [ ] Test production deployment and monitoring
- [ ] Document genealogy and usage patterns

## 📋 Required Changes Checklist

### Must Do (Critical):
- [ ] **Project Name**: Update `PROJECT_NAME=Hello AI Bot` in `.env`
- [ ] **Database Name**: Change database URL to `hello_ai_bot` database
- [ ] **Bot Token**: Get new token from @BotFather for AI bot
- [ ] **OpenAI API Key**: Add `OPENAI_API_KEY` to environment variables
- [ ] **Dependencies**: Add `openai>=1.0.0` and `tiktoken` to `pyproject.toml`
- [ ] **Config**: Update `project_name` default in `app/config.py`

### Core Implementation:
- [ ] **AI Service**: Create `app/services/openai_service.py` for API integration
- [ ] **Database Models**: Add new models in `app/database.py`
- [ ] **Handlers**: Implement AI commands in `app/handlers.py`
- [ ] **Role System**: Create predefined roles and enhancement logic
- [ ] **Conversation Storage**: Implement history management

### Optional Enhancements:
- [ ] **Token Counting**: Add usage statistics and limits
- [ ] **Model Switching**: Support multiple OpenAI models
- [ ] **Export History**: Allow users to export conversation history
- [ ] **Admin Commands**: Add admin panel for monitoring and management

## 🛠️ Implementation Guide

### 1. Environment Configuration

**Add to `.env`:**
```env
# AI Bot Specific
PROJECT_NAME=Hello AI Bot
OPENAI_API_KEY=sk-your-openai-api-key-here
DEFAULT_AI_MODEL=gpt-3.5-turbo
DEFAULT_ROLE_PROMPT=You are a helpful AI assistant.

# Rate Limiting
MAX_REQUESTS_PER_HOUR=60
MAX_TOKENS_PER_REQUEST=4000

# Database (separate from Hello Bot)
DB_NAME=hello_ai_bot
```

### 2. Database Models

**Add to `app/database.py`:**
```python
class UserRole(Base, TimestampMixin):
    """User's AI assistant role preference."""
    __tablename__ = "user_roles"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), unique=True)
    role_name: Mapped[str] = mapped_column(String(50), default="helpful_assistant")
    role_prompt: Mapped[str] = mapped_column(Text, default="You are a helpful AI assistant.")
    
class Conversation(Base, TimestampMixin):
    """User conversation history."""
    __tablename__ = "conversations"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    user_message: Mapped[str] = mapped_column(Text)
    ai_response: Mapped[str] = mapped_column(Text)
    model_used: Mapped[str] = mapped_column(String(50))
    tokens_used: Mapped[int] = mapped_column(Integer, default=0)
    role_used: Mapped[str] = mapped_column(String(50))
```

### 3. OpenAI Service

**Create `app/services/openai_service.py`:**
```python
import openai
from typing import Optional
import tiktoken

class OpenAIService:
    """Service for OpenAI API integration."""
    
    def __init__(self, api_key: str, default_model: str = "gpt-3.5-turbo"):
        self.client = openai.AsyncOpenAI(api_key=api_key)
        self.default_model = default_model
    
    async def generate_response(
        self, 
        user_message: str, 
        role_prompt: str,
        model: Optional[str] = None
    ) -> tuple[str, int]:
        """Generate AI response with role enhancement."""
        # Implementation here
        pass
    
    def count_tokens(self, text: str, model: str) -> int:
        """Count tokens in text for specified model."""
        # Implementation here
        pass
```

### 4. Main Commands

**Add to `app/handlers.py`:**
```python
@router.message(Command("do"))
async def do_ai_handler(message: types.Message, session: AsyncSession) -> None:
    """Process user text through OpenAI API."""
    # Extract text after /do command
    text = message.text.replace("/do ", "", 1).strip()
    if not text:
        await message.reply("Usage: /do <your message>\nExample: /do Explain quantum physics")
        return
    
    # Get user and role, call OpenAI, save conversation
    # Implementation here

@router.message(Command("role"))
async def role_handler(message: types.Message, session: AsyncSession) -> None:
    """Set or view AI assistant role."""
    # Implementation here

@router.message(Command("history"))
async def history_handler(message: types.Message, session: AsyncSession) -> None:
    """Show conversation history."""
    # Implementation here

@router.message(Command("models"))
async def models_handler(message: types.Message, session: AsyncSession) -> None:
    """List available OpenAI models."""
    # Implementation here
```

### 5. Predefined Roles

**Role Examples:**
```python
PREDEFINED_ROLES = {
    "helpful_assistant": "You are a helpful AI assistant.",
    "coder": "You are an expert programmer. Provide clear, efficient code solutions.",
    "teacher": "You are a patient teacher. Explain concepts clearly and ask if clarification is needed.",
    "creative": "You are a creative writing assistant. Help with storytelling and creative content.",
    "analyst": "You are a data analyst. Provide structured analysis and insights.",
    "translator": "You are a professional translator. Provide accurate translations between languages."
}
```

## 🚦 Success Criteria

**Bot is ready when:**
- [ ] `/do` command successfully calls OpenAI API and returns responses
- [ ] Role enhancement system works with predefined and custom roles
- [ ] Conversation history is properly stored and retrievable
- [ ] Error handling gracefully manages API failures and rate limits
- [ ] Bot deploys alongside Hello Bot without conflicts
- [ ] All tests pass (`uv run pytest tests/ -v`)
- [ ] Resource usage stays within 150MB RAM limit
- [ ] Documentation is complete and accurate

## 🚀 Quick Start Commands

```bash
# 1. Clone and Setup
git clone hello-bot hello-ai-bot
cd hello-ai-bot

# 2. Configure Environment
cp .env.example .env
# Edit .env: add BOT_TOKEN, OPENAI_API_KEY, update PROJECT_NAME

# 3. Install Dependencies
uv add openai tiktoken

# 4. Update Configuration
# Edit app/config.py: change default project_name
# Edit docker-compose.yml: update container names

# 5. Start Development
docker compose -f docker-compose.dev.yml up -d

# 6. Test Bot
# Send "/do Hello AI" to your bot
# Should get OpenAI-generated response

# 7. Deploy to Production
git push origin main
```

## 📊 Architecture Overview

```
Telegram User
     │
     ▼
┌─────────────────┐
│ Hello AI Bot    │
│ (aiogram)       │
└─────────────────┘
     │
     ▼
┌─────────────────┐
│ Role Enhancement│
│ System          │
└─────────────────┘
     │
     ▼
┌─────────────────┐
│ OpenAI API      │
│ (GPT-3.5/4)     │
└─────────────────┘
     │
     ▼
┌─────────────────┐
│ Conversation    │
│ Storage         │
└─────────────────┘
```

## 🧬 Bot Genealogy

Add this to your new bot's README.md:

```markdown
## Bot Genealogy
- **Parent Template**: Hello Bot Template (HB-001)
- **Bot ID**: HB-002
- **Created**: [Current Date]
- **Purpose**: OpenAI API proxy bot with role enhancement
- **GitHub**: [Your Repository URL]
- **Technology**: Python + aiogram + OpenAI API + PostgreSQL
```

## 🎯 AI Collaboration Context

When working with AI assistants on this bot, provide this context:

```
This is Hello AI Bot (HB-002) built from Hello Bot template:
- Telegram bot that forwards messages to OpenAI API
- Enhanced with role-based prompting system (6 predefined roles)
- Stores conversation history in PostgreSQL
- Simple architecture under 400 lines total
- Direct OpenAI API integration in handlers
- User role customization and history tracking
- Token counting and rate limiting
- Deployed alongside Hello Bot with shared PostgreSQL

Current goal: Create efficient AI proxy bot with role enhancement system
Architecture: Keep it simple, direct API calls, minimal abstractions
```

## 🔄 Future Evolution Ideas

**Potential HB-003 features:**
- Multi-language support
- Voice message processing
- Image generation with DALL-E
- Document analysis capabilities
- Integration with other AI APIs
- Advanced conversation threading
- User subscription management

---

**Start building your AI bot now! Follow this roadmap and create the second generation of Hello Bot.**