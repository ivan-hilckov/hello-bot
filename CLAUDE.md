# Working with Claude on Hello Bot

Guide for effective collaboration with Claude AI assistant on Hello Bot development.

## Quick Start

Claude understands the Hello Bot project architecture and follows specific development patterns. Here's how to get the best results:

### 🎯 Effective Prompts

**✅ Good prompts:**

```
"Add a /help command that lists all available commands"
"Fix the database connection pool for production deployment"
"Implement user analytics with async patterns"
"Review the security of user data handling"
```

**❌ Avoid:**

```
"Make the bot better"
"Fix everything"
"Add features"
```

## Project-Specific Guidelines

### 🏗️ Architecture Understanding

Claude knows about:

- **Dual Mode**: Development (polling) vs Production (webhook)
- **aiogram 3.0+**: Router patterns, dependency injection, filters
- **SQLAlchemy 2.0**: Async patterns, concurrency safety
- **2GB VPS Optimization**: Memory limits, connection pooling
- **CI/CD Pipeline**: GitHub Actions, automated deployment

### 📋 Code Standards

Claude will automatically apply:

- **Type hints** for all functions and variables
- **Async/await** patterns for I/O operations
- **Modern SQLAlchemy 2.0** syntax
- **Router pattern** for new handlers (aiogram 3.0+)
- **Session-per-task** for database operations
- **Resource optimization** for VPS deployment

## Common Development Scenarios

### 🔧 Adding New Features

**1. New Bot Command**

```
"Add a /settings command where users can update their language preference"
```

Claude will:

- Create handler with Router pattern
- Add proper database operations
- Include type hints and error handling
- Update documentation
- Consider migration if needed

**2. Database Changes**

```
"Add a user settings table with language and timezone fields"
```

Claude will:

- Create SQLAlchemy model with proper relationships
- Generate Alembic migration
- Update existing handlers if needed
- Ensure async patterns and indexing

**3. Performance Optimization**

```
"Optimize the bot for handling 1000+ concurrent users"
```

Claude will:

- Review connection pool settings
- Check AsyncSession concurrency patterns
- Suggest caching strategies
- Recommend resource allocation changes

### 🐛 Debugging & Troubleshooting

**Error Analysis**

```
"The bot gets IllegalStateChangeError during high load"
```

Claude will:

- Identify AsyncSession sharing issues
- Suggest session-per-task fixes
- Review middleware implementation
- Provide monitoring solutions

**Performance Issues**

```
"Database queries are slow in production"
```

Claude will:

- Analyze connection pool configuration
- Suggest query optimizations
- Review indexing strategy
- Check for N+1 query patterns

### 🚀 Deployment & DevOps

**CI/CD Issues**

```
"GitHub Actions deployment fails with timeout"
```

Claude will:

- Review workflow configuration
- Check Docker caching strategies
- Analyze health check settings
- Suggest optimization for 2GB VPS

## Advanced Usage

### 🔍 Code Review

Ask Claude to review code:

```
"Review this handler for security and performance issues"
"Check if this database model follows best practices"
"Analyze this middleware for potential race conditions"
```

### 📚 Learning & Documentation

**Understanding concepts:**

```
"Explain the Router pattern in aiogram 3.0+"
"How does AsyncSession concurrency work?"
"What are the benefits of dependency injection?"
```

**Documentation updates:**

```
"Update the API documentation for the new /analytics command"
"Add deployment notes for the new caching feature"
```

### 🧪 Testing

```
"Create unit tests for the user management functions"
"Add integration tests for the /start command flow"
"Write tests for the database middleware"
```

## Context & Memory

### 📖 What Claude Remembers

Claude has access to:

- **Project structure** and file organization
- **Technology stack** and dependencies
- **Architecture patterns** and best practices
- **Deployment configuration** and constraints
- **Recent changes** and development history

### 🔄 Session Continuity

For complex tasks spanning multiple interactions:

- Reference previous discussions: _"Continue with the analytics feature we discussed"_
- Build on previous work: _"Now add the database model for the user settings"_
- Ask for summaries: _"Summarize what we've implemented so far"_

## Best Practices

### ✅ Do

- **Be specific** about requirements and constraints
- **Mention performance** considerations for 2GB VPS
- **Ask for explanations** of complex patterns
- **Request documentation** updates with code changes
- **Consider security** implications of new features

### ❌ Don't

- **Mix multiple unrelated tasks** in one request
- **Ask to modify .env files** (Claude will ask you to do it)
- **Request breaking changes** without discussion
- **Ignore memory constraints** of the VPS deployment

## Emergency Scenarios

### 🚨 Production Issues

**Bot Down:**

```
"The production bot is not responding, help me debug"
```

**Database Issues:**

```
"PostgreSQL connections are maxed out, need immediate fix"
```

**Deployment Failures:**

```
"GitHub Actions deployment failed, need to rollback"
```

Claude will:

- Provide immediate diagnostic steps
- Suggest quick fixes and workarounds
- Help with rollback procedures
- Identify root cause analysis

### 🔧 Quick Fixes

**Performance degradation:**

```
"Bot response time increased, need quick optimization"
```

**Memory issues:**

```
"VPS running out of memory, need immediate tuning"
```

## Integration with Development Tools

### 🛠️ With Cursor

Claude works seamlessly with Cursor IDE:

- Understands project context from `.cursorrules`
- Follows coding standards automatically
- Integrates with file navigation and editing
- Provides real-time suggestions

### 📊 With GitHub

- Reviews pull requests
- Suggests commit messages
- Helps with issue triaging
- Assists with release planning

### 🐳 With Docker

- Optimizes Dockerfile configurations
- Debugs container issues
- Suggests resource allocation
- Helps with multi-stage builds

## Continuous Learning

### 📈 Staying Updated

Claude can help you:

- Learn new aiogram 3.0+ features
- Understand SQLAlchemy 2.0 patterns
- Follow async/await best practices
- Adopt modern Python patterns

### 🎓 Knowledge Transfer

Ask Claude to:

- Explain design decisions
- Document complex implementations
- Create learning materials
- Prepare onboarding guides

---

## 💡 Pro Tips

1. **Context is King**: Always provide relevant context about what you're working on
2. **Incremental Changes**: Break large tasks into smaller, manageable pieces
3. **Test Early**: Ask for testing strategies alongside implementation
4. **Document as You Go**: Request documentation updates with every feature
5. **Performance First**: Always consider 2GB VPS constraints in discussions

**Remember**: Claude is designed to work with Hello Bot's specific architecture and constraints. The more context you provide, the better the assistance you'll receive!
