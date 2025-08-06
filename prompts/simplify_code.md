# Simplify and Optimize Hello Bot Code

Use this prompt template to get AI assistance for code simplification, refactoring, and optimization while maintaining Hello Bot's philosophy of simplicity.

## Template Usage

Copy the template below and customize the placeholders:

---

# Simplify Code in Hello Bot Project

## Current Situation

### Project Context
- **Project**: Telegram bot based on Hello Bot template
- **Architecture**: Simplified (~320 lines total), direct database operations
- **Current Line Count**: [ACTUAL LINE COUNT] lines
- **Target**: Keep under 400 lines while adding functionality

### Code to Simplify
**Files for Review**: [e.g., `app/handlers.py`, `app/database.py`, or "entire project"]

```python
# Paste the code that needs simplification
# Include entire files or specific functions that feel complex
```

### Current Issues
- [ ] Code feels overly complex
- [ ] Duplicate logic across functions
- [ ] Verbose error handling
- [ ] Unclear variable names
- [ ] Complex nested logic
- [ ] Too many imports
- [ ] [OTHER SPECIFIC ISSUES]

## Simplification Goals

### Primary Objectives
1. **Reduce Complexity**: Eliminate unnecessary abstractions
2. **Improve Readability**: Make code self-documenting
3. **Remove Duplication**: Consolidate repeated logic
4. **Optimize Performance**: Simple optimizations without complexity
5. **Maintain Functionality**: Keep all features working

### Architecture Principles to Maintain
- ✅ Direct database operations (no service layer)
- ✅ Single-file modules (related code together)
- ✅ Simple async/await patterns
- ✅ Standard Python logging
- ✅ Minimal abstractions
- ✅ Clear function purposes

## Analysis Request

Please analyze the code and provide:

### 1. Complexity Assessment
- Which parts are unnecessarily complex?
- What abstractions can be removed?
- Where is logic duplicated?
- Which functions are doing too much?

### 2. Simplification Opportunities
- **Function Consolidation**: Can multiple functions be combined?
- **Logic Streamlining**: Can complex conditionals be simplified?
- **Import Optimization**: Are all imports necessary?
- **Variable Clarity**: Can names be more descriptive?

### 3. Refactoring Suggestions
- Code structure improvements
- Pattern simplifications
- Error handling streamlining
- Database query optimizations

### 4. Hello Bot Compliance
- Does the code follow simplified architecture?
- Are there any enterprise patterns to remove?
- Is the code maintaining the ~320 line philosophy?

## Simplification Requirements

### Must Preserve:
- ✅ All existing functionality
- ✅ Type hints and documentation
- ✅ Error handling (simplified where possible)
- ✅ Database integrity and transactions
- ✅ Test compatibility

### Simplification Targets:
- ❌ Remove unnecessary classes or abstractions
- ❌ Consolidate similar functions
- ❌ Simplify complex conditional logic
- ❌ Remove dead or unused code
- ❌ Streamline imports and dependencies

## Preferred Response Format

### Simplification Plan:
1. **Major Changes**: [List significant refactoring opportunities]
2. **Minor Optimizations**: [List small improvements]
3. **Code Removal**: [What can be deleted safely]
4. **Consolidation**: [Functions/logic to combine]

### Before/After Examples:

#### Example 1: [Description]
```python
# Before (complex):
[current complex code]

# After (simplified):
[simplified version]
```

#### Example 2: [Description]
```python
# Before (verbose):
[current verbose code]  

# After (concise):
[concise version]
```

### Updated File Structure:
```python
# Complete simplified file content
# Include all changes in context
```

### Impact Summary:
- **Lines Removed**: [number]
- **Functions Consolidated**: [number]  
- **Complexity Reduced**: [description]
- **Performance Impact**: [any performance changes]

---

## Common Simplification Patterns

### Handler Simplification
```python
# Instead of complex error handling:
try:
    # complex logic
except SpecificException:
    # specific handling
except AnotherException:
    # more handling
except Exception:
    # general handling

# Use simple pattern:
try:
    # logic
except Exception as e:
    logger.error(f"Handler error: {e}")
    await message.answer("Something went wrong. Please try again.")
```

### Database Query Simplification
```python
# Instead of complex query building:
def build_complex_query(filters):
    query = select(User)
    if filters.get('active'):
        query = query.where(User.is_active == True)
    # more conditions...
    return query

# Use direct, simple queries:
stmt = select(User).where(User.is_active == True)
result = await session.execute(stmt)
```

### Import Optimization
```python
# Instead of many specific imports:
from sqlalchemy import select, update, delete, func, and_, or_
from aiogram.types import Message, CallbackQuery, InlineKeyboardMarkup
from typing import List, Dict, Optional, Union

# Use consolidated imports:
from sqlalchemy import select, func
from aiogram import types
from typing import Optional
```

## Testing After Simplification

Verify simplification success:
1. **All tests pass**: `uv run pytest tests/ -v`
2. **Functionality intact**: Test all bot commands
3. **Performance maintained**: No significant slowdown
4. **Code clarity**: Easier to understand and modify
5. **Line count reduced**: Closer to 320-line ideal

## When to Stop Simplifying

Stop when:
- Code is clear and readable
- No obvious duplication remains
- Functions have single responsibilities
- Architecture principles are maintained
- All tests pass consistently

Remember: The goal is clarity and maintainability, not just fewer lines. Good simplification makes the code easier to understand and modify while preserving all functionality.