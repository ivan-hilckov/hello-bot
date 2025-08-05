# Bot API Documentation

Commands, handlers, and API interactions for the simplified Hello Bot.

## Bot Commands

| Command  | Description               | Response                         | Database Action             |
| -------- | ------------------------- | -------------------------------- | --------------------------- |
| `/start` | Get personalized greeting | `Hello! Welcome to the bot, <username>` | Creates/updates user record |
| _other_  | Any other message         | `Send /start to get a greeting!` | None                        |

## Simplified Architecture

All handlers are located in a single file: `app/handlers.py`

### Handler Structure

```python
from aiogram import F, Router, types
from aiogram.filters import Command
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

router = Router()

@router.message(Command("start"))
async def start_handler(message: types.Message, session: AsyncSession) -> None:
    # Direct database operations without service layer
    pass

@router.message(F.text)
async def default_handler(message: types.Message) -> None:
    # Simple response handler
    pass
```

## Command Details

### `/start` Command

**Handler**: `app/handlers.py:start_handler()`

**Purpose**:
- Welcome new users to the bot
- Create or update user record in database using direct SQLAlchemy operations
- Provide personalized greeting

**Flow**:

```mermaid
sequenceDiagram
    participant U as User
    participant B as Bot
    participant H as Handler
    participant D as Database

    U->>B: /start command
    B->>H: start_handler(message, session)
    H->>D: SELECT user WHERE telegram_id
    D-->>H: User or None

    alt User exists
        H->>D: UPDATE user SET username, first_name...
    else New user
        H->>D: INSERT INTO users (telegram_id, username...)
    end

    H->>D: COMMIT transaction
    H->>U: "Hello! Welcome to the bot, <display_name>"
```

**Code Implementation**:

```python
@router.message(Command("start"))
async def start_handler(message: types.Message, session: AsyncSession) -> None:
    """Handle /start command."""
    if not message.from_user:
        await message.answer("Hello! Welcome to the bot, <b>Unknown</b>", parse_mode=ParseMode.HTML)
        return

    telegram_user = message.from_user

    # Direct database query - no service layer
    stmt = select(User).where(User.telegram_id == telegram_user.id)
    result = await session.execute(stmt)
    user = result.scalar_one_or_none()

    if user:
        # Update existing user
        user.username = telegram_user.username
        user.first_name = telegram_user.first_name
        user.last_name = telegram_user.last_name
        user.language_code = telegram_user.language_code
        logger.info(f"Updated user: {user.display_name}")
    else:
        # Create new user
        user = User(
            telegram_id=telegram_user.id,
            username=telegram_user.username,
            first_name=telegram_user.first_name,
            last_name=telegram_user.last_name,
            language_code=telegram_user.language_code,
        )
        session.add(user)
        logger.info(f"Created new user: {user.display_name}")

    # Commit changes
    await session.commit()

    # Send greeting
    greeting = f"Hello! Welcome to the bot, <b>{user.display_name}</b>"
    await message.answer(greeting, parse_mode=ParseMode.HTML)
```

**Key Features**:
- ✅ Direct SQLAlchemy operations
- ✅ Simple error handling with middleware
- ✅ Standard Python logging
- ✅ Automatic session management

**Response Format**:

```
HTML format message:
"Hello! Welcome to the bot, <b>username</b>"

Where display_name is:
1. username (if available)
2. first_name + last_name (if username not available)
3. "User{telegram_id}" (fallback)
```

**Database Operations**:

```sql
-- Check if user exists
SELECT * FROM users WHERE telegram_id = $1;

-- Update existing user
UPDATE users
SET username = $1, first_name = $2, last_name = $3, language_code = $4, updated_at = NOW()
WHERE telegram_id = $5;

-- Create new user
INSERT INTO users (telegram_id, username, first_name, last_name, language_code, is_active, created_at, updated_at)
VALUES ($1, $2, $3, $4, $5, true, NOW(), NOW());
```

### Default Handler

**Handler**: `app/handlers.py:default_handler()`

**Purpose**:
- Handle all text messages that don't match specific commands
- Provide guidance to users

**Code Implementation**:

```python
@router.message(F.text)
async def default_handler(message: types.Message) -> None:
    """Handle all other text messages."""
    await message.answer("Send /start to get a greeting!")

    if message.from_user:
        logger.info(
            f"Received message from {message.from_user.username or message.from_user.first_name}"
        )
```

**Response**:
```
"Send /start to get a greeting!"
```

## Middleware Integration

### Database Middleware

**File**: `app/middleware.py`

**Purpose**: Inject database session into all handlers

```python
class DatabaseMiddleware(BaseMiddleware):
    """Middleware to inject database session into handlers."""

    async def __call__(self, handler, event, data):
        """Inject database session into handler data."""
        async with AsyncSessionLocal() as session:
            try:
                data["session"] = session
                result = await handler(event, data)
                await session.commit()
                return result
            except Exception:
                await session.rollback()
                raise
```

**Session Management**:
- ✅ One session per request
- ✅ Automatic commit on success
- ✅ Automatic rollback on error
- ✅ Clean resource cleanup

## Error Handling

### Simple Error Handling

No complex error handling - relies on middleware for session management:

```python
# Session errors handled by middleware
async def start_handler(message: types.Message, session: AsyncSession) -> None:
    # If any exception occurs:
    # 1. Middleware catches it
    # 2. Session is rolled back
    # 3. Exception is re-raised
    # 4. Bot continues functioning
```

### User Error Scenarios

| Scenario | Handler Response | Database Action |
|----------|------------------|-----------------|
| Missing user info | `"Hello! Welcome to the bot, Unknown"` | None |
| Database error | Standard aiogram error handling | Rollback via middleware |
| Invalid message | Default handler response | None |

## API Performance

### Response Times

| Operation | Target Time | Database Queries |
|-----------|-------------|------------------|
| `/start` command (new user) | <300ms | 1 SELECT + 1 INSERT |
| `/start` command (existing user) | <200ms | 1 SELECT + 1 UPDATE |
| Default handler | <100ms | 0 queries |

### Database Query Patterns

```python
# Most efficient patterns for simple architecture

# Single user lookup (primary pattern)
stmt = select(User).where(User.telegram_id == telegram_id)
user = (await session.execute(stmt)).scalar_one_or_none()

# User creation (atomic operation)
user = User(telegram_id=telegram_id, username=username)
session.add(user)
await session.commit()

# User update (minimal fields)
user.username = new_username
await session.commit()
```

## Testing API

### Handler Testing

```python
@pytest.mark.asyncio
async def test_start_handler_new_user(test_session):
    """Test /start command creates new user."""
    # Create mock message
    message = create_mock_message("/start", user_id=123456789)

    # Call handler
    await start_handler(message, test_session)

    # Verify user created
    stmt = select(User).where(User.telegram_id == 123456789)
    user = (await test_session.execute(stmt)).scalar_one_or_none()

    assert user is not None
    assert user.telegram_id == 123456789

@pytest.mark.asyncio
async def test_start_handler_existing_user(test_session):
    """Test /start command updates existing user."""
    # Create existing user
    user = User(telegram_id=123456789, username="oldname")
    test_session.add(user)
    await test_session.commit()

    # Mock message with updated info
    message = create_mock_message("/start", user_id=123456789, username="newname")

    # Call handler
    await start_handler(message, test_session)

    # Verify user updated
    await test_session.refresh(user)
    assert user.username == "newname"

@pytest.mark.asyncio
async def test_default_handler():
    """Test default handler response."""
    message = create_mock_message("Hello")

    # Call handler (no session needed)
    await default_handler(message)

    # Verify response sent
    assert message.answer.called
    assert "Send /start" in message.answer.call_args[0][0]
```

### Mock Objects

```python
def create_mock_message(text: str, user_id: int = 123456789, username: str = "testuser"):
    """Create mock Telegram message for testing."""
    message = Mock()
    message.text = text
    message.from_user = Mock()
    message.from_user.id = user_id
    message.from_user.username = username
    message.from_user.first_name = "Test"
    message.from_user.last_name = "User"
    message.answer = AsyncMock()
    return message
```

## Webhook API (Production)

### Simple Webhook Endpoint

**File**: `app/main.py`

For production deployment with webhook mode:

```python
if settings.webhook_url:
    # Simple FastAPI app
    app = FastAPI()

    @app.post("/webhook")
    async def webhook(update: dict[str, Any]):
        """Simple webhook endpoint."""
        telegram_update = Update(**update)
        await dp.feed_update(bot, telegram_update)
        return {"ok": True}

    # Set webhook
    await bot.set_webhook(url=settings.webhook_url)
```

**Endpoint Details**:
- **URL**: `POST /webhook`
- **Input**: Telegram Update JSON
- **Output**: `{"ok": True}`
- **Processing**: Direct to aiogram dispatcher

## Simplified vs Enterprise

### What Was Removed

| Enterprise Feature | Purpose | Why Removed |
|-------------------|---------|-------------|
| Service Layer abstraction | Business logic separation | Direct operations simpler |
| Dependency injection | Complex object management | Direct instantiation fine |
| Caching layer | Performance optimization | Database fast enough |
| Metrics collection | Performance monitoring | Overkill for simple bot |
| Complex error handling | Enterprise-grade reliability | Basic handling sufficient |

### Current Approach Benefits

- ✅ **Simplicity**: All logic in handlers
- ✅ **Performance**: Direct database operations
- ✅ **Maintainability**: Single file structure
- ✅ **Testing**: Straightforward unit tests
- ✅ **Learning**: Clear code flow

This simplified API design is perfect for:
- Learning Telegram bot development
- Prototyping new features
- Small to medium bots
- Resource-constrained environments

The architecture can be scaled up when needed by adding service layers, caching, and enterprise patterns.
