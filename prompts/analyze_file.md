# Analyze File for Optimization

Use this prompt template to get AI assistance for reviewing and optimizing specific files in your Hello Bot project.

## Template Usage

Copy the template below and customize the placeholders:

---

# Analyze `[FILE_PATH]` for Hello Bot Project

## Context
- **File**: `[FILE_PATH]` (e.g., `app/handlers.py`)
- **Project**: Telegram bot based on Hello Bot template
- **Architecture**: Simplified (~320 lines total), direct database operations
- **Current Issue**: [DESCRIBE SPECIFIC ISSUE OR JUST "general optimization"]

## Current File Content
```python
[PASTE THE FILE CONTENT HERE]
```

## Analysis Request

Please analyze this file and provide:

### 1. Code Quality Assessment
- Type hints completeness
- Error handling patterns  
- Async/await usage
- Code organization and readability

### 2. Hello Bot Architecture Compliance
- Does it follow simplified architecture principles?
- Are there unnecessary abstractions or complexity?
- Is it consistent with direct database operations pattern?
- Does it maintain the ~320 line total project constraint?

### 3. Optimization Opportunities
- Performance improvements
- Code simplification
- Redundancy elimination
- Better error handling

### 4. Potential Issues
- Logic errors or edge cases
- Security concerns
- Resource usage problems
- Integration issues with other components

## Requirements for Suggestions

Any recommendations should:
- ✅ Maintain Hello Bot's simplified architecture
- ✅ Use direct database operations (no service layer)
- ✅ Include proper type hints
- ✅ Follow async/await patterns
- ✅ Use standard Python logging
- ✅ Keep changes minimal and focused
- ❌ Avoid enterprise patterns (DI, caching, complex abstractions)
- ❌ Don't add unnecessary complexity

## Preferred Response Format

### Issues Found:
1. **[Issue Type]**: [Description]
   - **Impact**: [Low/Medium/High]
   - **Location**: Line X-Y

### Recommendations:
1. **[Improvement Type]**: [Description]
   - **Change**: [Specific code change needed]
   - **Benefit**: [Why this improves the code]

### Code Examples:
```python
# Before (problematic):
[current code]

# After (improved):
[suggested code]
```

### Priority:
- **Critical**: [Changes that fix bugs or security issues]
- **Important**: [Changes that improve maintainability]  
- **Nice-to-have**: [Minor optimizations]

---

## Common File Analysis Examples

### For `app/handlers.py`:
Focus on: command handler structure, database operations, error handling, message formatting

### For `app/database.py`:
Focus on: model definitions, relationships, query optimization, type safety

### For `app/config.py`:
Focus on: settings validation, environment variable handling, security

### For `tests/test_*.py`:
Focus on: test coverage, mock usage, async test patterns, assertion clarity

### For `app/main.py`:
Focus on: startup/shutdown logic, middleware registration, mode switching (polling/webhook)

## Integration with Development Workflow

Use this analysis template:
1. **Before adding new features** - ensure existing code is optimal
2. **During code review** - get AI perspective on your changes  
3. **When debugging** - identify potential root causes
4. **For refactoring** - find opportunities to simplify

Remember: The goal is maintaining Hello Bot's philosophy of simplicity while ensuring code quality and functionality.