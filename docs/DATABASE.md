# Database Documentation

Database schema and models for the simplified Hello Bot architecture.

## Database Schema

```mermaid
erDiagram
    USERS {
        int id PK "Internal user ID"
        bigint telegram_id UK "Telegram user ID"
        varchar(255) username "Telegram username"
        varchar(255) first_name "Telegram first name"
        varchar(255) last_name "Telegram last name"
        boolean is_active "Whether user is active"
        varchar(10) language_code "User language code"
        timestamp created_at "Creation timestamp"
        timestamp updated_at "Last update timestamp"
    }
```

## Technology Stack

- **Database**: PostgreSQL 15 (Shared Container in Production)
- **ORM**: SQLAlchemy 2.0 (async)
- **Driver**: asyncpg
- **Schema Management**: Direct SQLAlchemy table creation
- **Architecture**: Single file structure (`app/database.py`)
- **Production**: Shared PostgreSQL instance with isolated databases per bot

## Simplified Database Structure

All database-related code is consolidated in `app/database.py`:

```python
# app/database.py
from sqlalchemy import BigInteger, String, func
from sqlalchemy.ext.asyncio import AsyncAttrs, AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column

# Base classes
class Base(AsyncAttrs, DeclarativeBase):
    """Base class for all database models."""
    __abstract__ = True

class TimestampMixin:
    """Mixin to add created_at and updated_at timestamps."""
    created_at: Mapped[datetime] = mapped_column(default=func.now(), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        default=func.now(), server_default=func.now(), onupdate=func.now()
    )

# User model
class User(Base, TimestampMixin):
    """Telegram user model."""
    __tablename__ = "users"

    # Fields
    id: Mapped[int] = mapped_column(primary_key=True)
    telegram_id: Mapped[int] = mapped_column(BigInteger, unique=True, index=True)
    username: Mapped[str | None] = mapped_column(String(255), nullable=True)
    first_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    last_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    is_active: Mapped[bool] = mapped_column(default=True)
    language_code: Mapped[str | None] = mapped_column(String(10), nullable=True)

# Session management
engine = create_async_engine(settings.database_url)
AsyncSessionLocal = async_sessionmaker(bind=engine, class_=AsyncSession)
```

## Shared PostgreSQL Configuration (v2.1.0+)

### Production Architecture

In production, multiple bots share a single PostgreSQL instance for optimal resource usage:

```mermaid
graph LR
    subgraph "Shared PostgreSQL Container"
        DB[(PostgreSQL 15<br/>512MB)]
    end
    
    subgraph "Isolated Databases"
        DB1[hello-bot_db]
        DB2[chatbot_db]
        DB3[mybot_db]
    end
    
    subgraph "Bot Applications"
        BOT1[Hello Bot<br/>128MB]
        BOT2[Chat Bot<br/>128MB]
        BOT3[My Bot<br/>128MB]
    end
    
    DB --> DB1
    DB --> DB2
    DB --> DB3
    
    BOT1 -.-> DB1
    BOT2 -.-> DB2
    BOT3 -.-> DB3
```

### Database Connection Configuration

Each bot connects to its isolated database within the shared PostgreSQL instance:

```python
# Connection string format for shared PostgreSQL
DATABASE_URL = "postgresql+asyncpg://{PROJECT_NAME}_user:{DB_PASSWORD}@postgres-shared:5432/{PROJECT_NAME}_db"

# Example for hello-bot
DATABASE_URL = "postgresql+asyncpg://hello-bot_user:secure_password@postgres-shared:5432/hello-bot_db"
```

### Resource Optimization

| Deployment | Individual PostgreSQL | Shared PostgreSQL | Memory Savings |
|------------|----------------------|------------------|----------------|
| **3 Bots** | 768MB (256MB × 3) | 512MB | **256MB (33%)** |
| **5 Bots** | 1.28GB (256MB × 5) | 512MB | **768MB (60%)** |
| **10 Bots** | 2.56GB (256MB × 10) | 512MB | **2.05GB (80%)** |

### Connection Pool Settings

Optimized for shared PostgreSQL usage:

```python
# app/database.py - Optimized for shared instance
engine = create_async_engine(
    settings.database_url,
    echo=settings.debug,
    future=True,
    pool_size=2,        # Reduced per bot (shared instance)
    max_overflow=3,     # Controlled overflow
    pool_timeout=30,
    pool_recycle=3600,
)
```

## User Model

### Fields

| Field           | Type           | Constraints                 | Description                     |
| --------------- | -------------- | --------------------------- | ------------------------------- |
| `id`            | `int`          | Primary Key, Auto-increment | Internal database ID            |
| `telegram_id`   | `bigint`       | Unique, Indexed             | Telegram user ID from API       |
| `username`      | `varchar(255)` | Nullable                    | Telegram username (@username)   |
| `first_name`    | `varchar(255)` | Nullable                    | User's first name from Telegram |
| `last_name`     | `varchar(255)` | Nullable                    | User's last name from Telegram  |
| `is_active`     | `boolean`      | Default: true               | Whether user is active          |
| `language_code` | `varchar(10)`  | Nullable                    | User's language preference      |
| `created_at`    | `timestamp`    | Auto-generated              | Record creation time            |
| `updated_at`    | `timestamp`    | Auto-updated                | Last modification time          |

### Model Properties

```python
@property
def display_name(self) -> str:
    """Get the best display name for the user."""
    return self.username or self.full_name or f"User{self.telegram_id}"

@property
def full_name(self) -> str:
    """Get full name from first_name and last_name."""
    parts = [self.first_name, self.last_name]
    return " ".join(part for part in parts if part)
```

## Database Operations

### Direct SQLAlchemy Operations

All database operations are performed directly in handlers without service layer:

```python
# Get user
stmt = select(User).where(User.telegram_id == telegram_user.id)
result = await session.execute(stmt)
user = result.scalar_one_or_none()

# Create user
if not user:
    user = User(
        telegram_id=telegram_user.id,
        username=telegram_user.username,
        first_name=telegram_user.first_name,
        last_name=telegram_user.last_name,
        language_code=telegram_user.language_code,
    )
    session.add(user)

# Update user
user.username = telegram_user.username
user.first_name = telegram_user.first_name

# Commit changes
await session.commit()
```

### Session Management

Simple session-per-request pattern via middleware:

```python
class DatabaseMiddleware(BaseMiddleware):
    async def __call__(self, handler, event, data):
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

## Schema Management

### Direct Table Creation

The Hello Bot template uses **direct SQLAlchemy table creation** instead of migrations for simplicity:

```python
# app/database.py
async def create_tables() -> None:
    """Create all tables."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
```

This function is called automatically in `app/main.py` during startup:

```python
# app/main.py
async def main() -> None:
    """Main application function."""
    # Create database tables
    await create_tables()
    logger.info("Database initialized")
```

### Schema Changes

When you modify models:

1. **Update the model** in `app/database.py`
2. **Restart the application** - tables will be automatically updated
3. **For production**, ensure backward compatibility or handle schema changes manually

### Benefits of Direct Creation

- **Simplicity**: No migration files to manage
- **Template-friendly**: Easy to understand and modify
- **Fast development**: Immediate schema changes
- **Resource-efficient**: No migration overhead

### Manual Schema Changes

For complex schema changes in production:

```python
# Add new column manually if needed
# ALTER TABLE users ADD COLUMN new_field VARCHAR(255);
```

## Performance Considerations

### Indexes

Essential indexes for the simplified architecture:

1. **Primary Key**: `id` (automatic)
2. **Unique Index**: `telegram_id` (for fast user lookup)

```sql
-- Automatically created indexes
CREATE UNIQUE INDEX ix_users_telegram_id ON users (telegram_id);
CREATE INDEX ix_users_id ON users (id);
```

### Connection Pool

Simple connection pool configuration:

```python
engine = create_async_engine(
    settings.database_url,
    echo=settings.debug,  # SQL logging in debug mode
    future=True,
    pool_size=3,          # Small pool for simple bot
    max_overflow=2,       # Limited overflow
)
```

### Query Patterns

Efficient query patterns for the simplified architecture:

```python
# Single user lookup (most common)
user = await session.get(User, {"telegram_id": telegram_id})

# User existence check
exists = await session.scalar(
    select(User.id).where(User.telegram_id == telegram_id)
)

# Count users
count = await session.scalar(select(func.count(User.id)))

# Recent users
recent = await session.scalars(
    select(User)
    .where(User.created_at > datetime.now() - timedelta(days=7))
    .order_by(User.created_at.desc())
    .limit(10)
)
```

## Development Database

### Local Setup

```bash
# PostgreSQL via Docker Compose
docker compose up -d postgres

# Check database status
docker compose exec postgres pg_isready -U hello_user -d hello_bot

# Connect to database
docker compose exec postgres psql -U hello_user -d hello_bot
```

### Sample Queries

```sql
-- View all users
SELECT telegram_id, username, first_name, created_at
FROM users
ORDER BY created_at DESC;

-- Count total users
SELECT COUNT(*) as total_users FROM users;

-- Users created today
SELECT COUNT(*) as today_users
FROM users
WHERE created_at > CURRENT_DATE;

-- Active users with usernames
SELECT COUNT(*) as active_with_username
FROM users
WHERE is_active = true AND username IS NOT NULL;
```

## Backup and Maintenance

### Database Backup

```bash
# Create backup
docker compose exec postgres pg_dump -U hello_user hello_bot > backup.sql

# Restore backup
docker compose exec -i postgres psql -U hello_user hello_bot < backup.sql
```

### Database Maintenance

```sql
-- Check table sizes
SELECT
    tablename,
    pg_size_pretty(pg_total_relation_size(tablename::regclass)) as size
FROM pg_tables
WHERE schemaname = 'public';

-- Check index usage
SELECT
    indexname,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE relname = 'users';

-- Analyze table statistics
ANALYZE users;
```

## Testing Database

### Test Configuration

```python
# conftest.py - SQLite in-memory for tests
import pytest
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession

@pytest.fixture
async def test_session():
    engine = create_async_engine("sqlite+aiosqlite:///:memory:")

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with AsyncSession(engine) as session:
        yield session

    await engine.dispose()
```

### Test Examples

```python
@pytest.mark.asyncio
async def test_user_creation(test_session):
    # Create user
    user = User(
        telegram_id=123456789,
        username="testuser",
        first_name="Test"
    )
    test_session.add(user)
    await test_session.commit()

    # Verify user created
    found_user = await test_session.get(User, user.id)
    assert found_user.telegram_id == 123456789
    assert found_user.display_name == "testuser"

@pytest.mark.asyncio
async def test_user_properties(test_session):
    # Test display_name property
    user = User(telegram_id=123, first_name="John", last_name="Doe")
    assert user.full_name == "John Doe"
    assert user.display_name == "John Doe"

    # Test with username
    user.username = "johndoe"
    assert user.display_name == "johndoe"
```

## Simplified vs Enterprise

### What Was Removed

| Enterprise Feature | Lines | Why Removed |
|-------------------|-------|-------------|
| Complex indexing strategies | ~50 | Simple bot doesn't need optimization |
| Connection pool tuning | ~30 | Default settings sufficient |
| Service layer abstractions | ~200 | Direct operations simpler |
| Caching integration | ~100 | Database queries fast enough |
| Advanced query optimization | ~80 | Premature optimization |

### Current Simplifications

- **Single file structure** - All database code in `database.py`
- **Direct operations** - No service layer abstraction
- **Basic indexing** - Only essential indexes
- **Standard connection pool** - Default SQLAlchemy settings
- **Simple session management** - Session-per-request pattern

This simplified approach is perfect for:
- Learning database operations
- Prototyping new features
- Small to medium bots (<1000 daily users)
- Resource-constrained environments

The architecture can be scaled up when needed by adding service layers, caching, and optimization patterns.
