# Add New Feature to Hello Bot Project

Use this prompt template to systematically add new features to your Hello Bot-based Telegram bot while maintaining architectural simplicity.

## Template Usage

Copy the template below and customize the placeholders:

---

# Add Feature: [FEATURE_NAME] to Hello Bot Project

## Feature Specification

### Basic Information
- **Feature Name**: [e.g., "Weather Lookup", "Task Management", "User Preferences"]
- **User Story**: As a user, I want [GOAL] so that [BENEFIT]
- **Priority**: [Critical/High/Medium/Low]

### Commands/Interactions
- **New Commands**: [List new bot commands, e.g., `/weather <city>`, `/tasks`, `/settings`]
- **Command Flow**: [Describe user interaction flow]
- **Expected Responses**: [What bot should respond with]

### Data Requirements
- **New Database Tables**: [List any new models needed]
- **External APIs**: [Any third-party services to integrate]
- **User Data**: [What user data needs to be stored/retrieved]

## Current Project Context

### Architecture
- Simplified Hello Bot template (~320 lines total)
- Direct database operations (no service layer)
- Files: `app/config.py`, `app/database.py`, `app/handlers.py`, `app/middleware.py`, `app/main.py`
- SQLAlchemy 2.0 async + PostgreSQL
- aiogram 3.0+ for Telegram API

### Existing Functionality
[LIST CURRENT BOT FEATURES AND COMMANDS]

### Relevant Current Code
```python
# Paste relevant existing code that this feature will interact with
# For example, existing handlers, models, or configuration
```

## Implementation Request

Please provide a complete implementation plan and code for this feature:

### 1. Database Changes
If new models are needed:
- Define new SQLAlchemy models in `app/database.py`
- Specify relationships with existing User model
- Include proper type hints and constraints

### 2. Handler Implementation
Create new handler functions in `app/handlers.py`:
- Follow existing pattern with `@router.message()` decorators
- Use dependency injection for database session
- Include proper error handling and logging
- Use appropriate message formatting (HTML/Markdown)

### 3. Configuration Updates
If needed, add new settings to `app/config.py`:
- New environment variables
- API keys or external service configuration
- Feature flags or defaults

### 4. Schema Updates
For database changes, models are automatically created on startup:
- Update models in `app/database.py`
- Restart the application
- Tables will be created/updated automatically

### 5. Tests
Create tests in `tests/test_handlers.py`:
- Test new command handlers
- Test database operations
- Test error scenarios
- Follow existing async test patterns

## Requirements and Constraints

### Must Follow:
- ✅ Hello Bot simplified architecture principles
- ✅ Direct database operations in handlers
- ✅ Async/await patterns throughout
- ✅ Proper type hints on all functions
- ✅ Standard Python logging for events
- ✅ Session management via middleware
- ✅ Keep total project under 400 lines

### Must Avoid:
- ❌ Service layer abstractions
- ❌ Complex business logic classes
- ❌ Caching layers or performance optimizations
- ❌ Enterprise patterns (DI containers, etc.)
- ❌ Breaking existing functionality

### Code Style:
- Use existing code patterns and naming conventions
- Include docstrings for new functions
- Handle errors gracefully with user-friendly messages
- Log important events for debugging

## Expected Response Format

### 1. Implementation Plan
- [ ] Database model changes
- [ ] Handler additions/modifications  
- [ ] Configuration updates
- [ ] Test additions
- [ ] Documentation updates

### 2. Code Changes

**File: `app/database.py`**
```python
# New model definitions or modifications
```

**File: `app/handlers.py`**  
```python
# New handler functions
```

**File: `app/config.py`** (if needed)
```python
# New configuration options
```

**File: `tests/test_handlers.py`**
```python
# New test cases
```

### 3. Setup Instructions
- Environment variables to add to `.env`
- External dependencies to install
- Database migration commands
- Testing verification steps

### 4. Usage Examples
Show how users will interact with the new feature:
```
User: /newcommand parameter
Bot: [Expected response]
```

---

## Common Feature Examples

### Weather Lookup Feature
```
Feature: Get weather for any city
Commands: /weather <city>, /forecast <city>
Database: UserLocation table for favorites
External API: OpenWeatherMap
```

### Task Management Feature  
```
Feature: Simple task list management
Commands: /add_task, /list_tasks, /complete_task
Database: Task table with user relationship
No external APIs needed
```

### User Preferences Feature
```
Feature: Store user preferences and settings
Commands: /settings, /set_language, /set_timezone  
Database: Extend User model with preference fields
No external APIs needed
```

## Integration Testing

After implementation, verify:
1. All existing tests still pass
2. New feature works end-to-end
3. Database operations are successful
4. Error handling works properly
5. Bot responds appropriately to edge cases

Remember: Keep it simple, functional, and maintainable. The Hello Bot template prioritizes clarity and directness over complex abstractions.