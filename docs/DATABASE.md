# Database Documentation

Database schema, models, and data management for Hello Bot.

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

- **Database**: PostgreSQL 15 Alpine
- **ORM**: SQLAlchemy 2.0 (async)
- **Driver**: asyncpg
- **Migrations**: Alembic
- **Connection Pool**: 3-5 connections (optimized for 2GB RAM)

## Models

### User Model

**File**: `app/database/models/user.py`

**Purpose**: Stores Telegram user information and interaction history

**Fields**:

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

**Model Implementation**:

```python
class User(Base, TimestampMixin):
    """Telegram user model."""

    __tablename__ = "users"

    # Primary key
    id: Mapped[int] = mapped_column(primary_key=True)

    # Telegram user information
    telegram_id: Mapped[int] = mapped_column(
        BigInteger, unique=True, index=True
    )
    username: Mapped[str | None] = mapped_column(String(255), nullable=True)
    first_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    last_name: Mapped[str | None] = mapped_column(String(255), nullable=True)

    # User state
    is_active: Mapped[bool] = mapped_column(default=True)
    language_code: Mapped[str | None] = mapped_column(String(10), nullable=True)

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

### Base Model & Mixins

**File**: `app/database/base.py`

**Base Class**:

```python
class Base(AsyncAttrs, DeclarativeBase):
    """Base class for all database models."""
    __abstract__ = True
```

**TimestampMixin**:

```python
class TimestampMixin:
    """Mixin to add created_at and updated_at timestamps."""

    created_at: Mapped[datetime] = mapped_column(
        default=func.now(), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        default=func.now(), server_default=func.now(), onupdate=func.now()
    )
```

## Database Operations

### User Management

**Get or Create User**:

```python
async def get_or_create_user(session: AsyncSession, telegram_user: types.User) -> User:
    """Get existing user or create new one."""
    # Try to find existing user
    stmt = select(User).where(User.telegram_id == telegram_user.id)
    result = await session.execute(stmt)
    user = result.scalar_one_or_none()

    if user:
        # Update existing user info
        user.username = telegram_user.username
        user.first_name = telegram_user.first_name
        user.last_name = telegram_user.last_name
        user.language_code = telegram_user.language_code
        await session.commit()
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
        await session.commit()
        await session.refresh(user)

    return user
```

## Connection Management

### Session Factory

**File**: `app/database/session.py`

**Engine Configuration**:

```python
engine = create_async_engine(
    settings.database_url,
    pool_size=settings.db_pool_size,        # Default: 5 (dev), 3 (prod)
    max_overflow=settings.db_max_overflow,  # Default: 10 (dev), 5 (prod)
    echo=settings.debug,                    # SQL logging in debug mode
    future=True,
)
```

**Session Management**:

```python
AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
    autocommit=False,
)

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Dependency function for database sessions."""
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
```

### Middleware Integration

**Database Middleware** (`app/middlewares/database.py`):

```python
class DatabaseMiddleware(BaseMiddleware):
    """Middleware to inject database session into handlers."""

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

## Migrations

### Alembic Configuration

**File**: `alembic.ini`

- Database URL from environment
- Migration directory: `alembic/versions/`
- Auto-generation support

**Environment Setup** (`alembic/env.py`):

```python
# Import models for auto-generation
from app.database.base import Base
from app.database.models import *  # Import all models

target_metadata = Base.metadata
```

### Migration Commands

```bash
# Create new migration
alembic revision --autogenerate -m "description"

# Apply migrations
alembic upgrade head

# Check current version
alembic current

# View migration history
alembic history

# Check if migration needed (useful in CI/CD)
alembic check
```

### Async Migration Configuration

**Modern Alembic env.py for Async Applications:**

```python
# alembic/env.py
import asyncio
from sqlalchemy.ext.asyncio import async_engine_from_config
from sqlalchemy.pool import NullPool

def do_run_migrations(connection):
    context.configure(
        connection=connection,
        target_metadata=target_metadata,
        render_as_batch=True,  # For SQLite compatibility
    )

    with context.begin_transaction():
        context.run_migrations()

async def run_async_migrations():
    """Run migrations in async mode."""
    connectable = async_engine_from_config(
        config.get_section(config.config_ini_section),
        prefix="sqlalchemy.",
        poolclass=NullPool,
    )

    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)

    await connectable.dispose()

def run_migrations_online():
    """Run migrations in 'online' mode."""
    asyncio.run(run_async_migrations())
```

### Post-Write Hooks for Code Quality

**alembic.ini configuration:**

```ini
[post_write_hooks]
# Format with ruff (faster than black)
hooks = ruff_format

ruff_format.type = console_scripts
ruff_format.entrypoint = ruff
ruff_format.options = format REVISION_SCRIPT_FILENAME
```

## Concurrency & Performance

### AsyncSession Best Practices

**Critical: Session-per-Task Pattern**

```python
# ❌ DANGEROUS: Sharing session across tasks
async def bad_concurrent_processing():
    async with AsyncSessionLocal() as shared_session:
        tasks = [
            process_data(shared_session, data)  # IllegalStateChangeError risk
            for data in data_list
        ]
        await asyncio.gather(*tasks)

# ✅ CORRECT: Session per task
async def safe_concurrent_processing():
    async def process_with_own_session(data):
        async with AsyncSessionLocal() as session:
            return await process_data(session, data)

    tasks = [process_with_own_session(data) for data in data_list]
    return await asyncio.gather(*tasks)
```

**Connection Pool Optimization**

```python
# Production settings for 2GB RAM VPS
engine = create_async_engine(
    database_url,
    pool_size=3,           # Conservative for limited RAM
    max_overflow=5,        # Total max: 8 connections
    pool_timeout=30,       # Connection timeout
    pool_recycle=3600,     # Recycle connections hourly
)
```

### Initial Migration

**File**: `alembic/versions/20241222_1700_001_create_users_table.py`

Creates the initial `users` table with all fields and constraints.

## Performance Optimization

### Connection Pooling

**Development**:

```python
pool_size=5          # 5 connections
max_overflow=10      # Up to 15 total connections
```

**Production (2GB RAM)**:

```python
pool_size=3          # 3 connections
max_overflow=5       # Up to 8 total connections
```

### Database Container Limits

```yaml
postgres:
  deploy:
    resources:
      limits:
        memory: 512M # Half of VPS memory
      reservations:
        memory: 256M # Minimum guaranteed
```

### Query Optimization

**Indexed Fields**:

- `telegram_id` (unique index for fast lookups)
- `created_at` (automatic timestamp index)

**Efficient Queries**:

```python
# Use indexed telegram_id for lookups
stmt = select(User).where(User.telegram_id == telegram_user.id)

# Avoid N+1 queries (not applicable with single table)
# Use select() instead of Query API for better performance
```

## Database Administration

### Connection Testing

```bash
# Test connection from container
docker compose exec postgres pg_isready -U hello_user -d hello_bot

# Connect to database
docker compose exec postgres psql -U hello_user -d hello_bot
```

### Common Queries

```sql
-- View all users
SELECT telegram_id, username, first_name, created_at FROM users;

-- User count
SELECT COUNT(*) FROM users;

-- Recent users (last 24 hours)
SELECT * FROM users WHERE created_at > NOW() - INTERVAL '24 hours';

-- Active users
SELECT * FROM users WHERE is_active = true;
```

### Backup & Restore

```bash
# Create backup
docker compose exec postgres pg_dump -U hello_user hello_bot > backup_$(date +%Y%m%d).sql

# Restore backup
docker compose exec -T postgres psql -U hello_user hello_bot < backup_20241222.sql
```

### Maintenance

```sql
-- Update table statistics
ANALYZE users;

-- Clean up (vacuum)
VACUUM ANALYZE users;

-- Check table size
SELECT pg_size_pretty(pg_total_relation_size('users'));
```

## Environment Configuration

### Database URL Format

```env
DATABASE_URL=postgresql+asyncpg://username:password@host:port/database
```

### Development Configuration

```env
DATABASE_URL=postgresql+asyncpg://hello_user:local_password_123@localhost:5432/hello_bot
DB_POOL_SIZE=5
DB_MAX_OVERFLOW=10
```

### Production Configuration

```env
DATABASE_URL=postgresql+asyncpg://hello_user:${DB_PASSWORD}@postgres:5432/hello_bot
DB_POOL_SIZE=3
DB_MAX_OVERFLOW=5
```

## Troubleshooting

### Common Issues

**Connection Errors**:

```bash
# Check PostgreSQL status
docker compose ps postgres
docker compose logs postgres

# Test connection
docker compose exec postgres pg_isready -U hello_user -d hello_bot
```

**Migration Errors**:

```bash
# Check current migration status
alembic current

# View migration history
alembic history

# Reset to specific revision (if needed)
alembic downgrade base
alembic upgrade head
```

**Performance Issues**:

```sql
-- Check active connections
SELECT count(*) FROM pg_stat_activity WHERE state = 'active';

-- View slow queries (if enabled)
SELECT query, mean_time, calls FROM pg_stat_statements ORDER BY mean_time DESC;
```

### Database Reset

```bash
# Stop and remove database volume (DESTRUCTIVE)
docker compose down -v

# Start fresh
docker compose up -d postgres

# Wait for PostgreSQL to start, then apply migrations
docker compose up -d bot
```
