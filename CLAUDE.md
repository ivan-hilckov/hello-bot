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
- **aiogram 3.0+**: Modern Router patterns, dependency injection, advanced filters
- **Service Layer**: Business logic separation with UserService, BaseService
- **SQLAlchemy 2.0**: Async patterns, concurrency safety, optimized indexes
- **Redis Caching**: Multi-layer caching with memory fallback
- **2GB VPS Optimization**: Memory limits, connection pooling, resource monitoring
- **CI/CD Pipeline**: GitHub Actions, 4-5 minute deployment, Docker caching
- **Testing Infrastructure**: 12 comprehensive tests with pytest
- **Monitoring**: Prometheus metrics, structured logging, enhanced health checks

### 📋 Code Standards

Claude will automatically apply:

- **Type hints** for all functions and variables
- **Async/await** patterns for I/O operations
- **Modern SQLAlchemy 2.0** syntax with async sessions
- **Router pattern** for new handlers (aiogram 3.0+)
- **Service Layer pattern** with dependency injection
- **Session-per-task** for database operations (critical for concurrency)
- **Resource optimization** for VPS deployment
- **Redis caching** with fallback strategies
- **Structured logging** with JSON format for production
- **Comprehensive testing** with pytest and async support

## Common Development Scenarios

### 🔧 Adding New Features

**1. New Bot Command**

```
"Add a /settings command where users can update their language preference"
```

Claude will:

- Create handler with modern Router pattern and dependency injection
- Add proper database operations using Service Layer
- Include Redis caching for performance optimization
- Include comprehensive type hints and error handling
- Add corresponding tests to the test suite
- Update documentation and API references
- Consider migration if needed with Alembic

**2. Database Changes**

```
"Add a user settings table with language and timezone fields"
```

Claude will:

- Create SQLAlchemy model with proper relationships and composite indexes
- Generate Alembic migration with performance optimizations
- Update existing handlers and Service Layer methods if needed
- Ensure async patterns and proper indexing strategy
- Update Redis cache keys and invalidation logic
- Add corresponding database tests

**3. Performance Optimization**

```
"Optimize the bot for handling 1000+ concurrent users"
```

Claude will:

- Review connection pool settings and database indexes
- Check AsyncSession concurrency patterns (session-per-task)
- Optimize Redis caching strategies with TTL tuning
- Analyze Prometheus metrics for bottlenecks
- Recommend resource allocation changes for 2GB VPS
- Suggest structured logging improvements
- Review Docker resource limits and health check intervals

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

### 🏗️ Modern Architecture Patterns

**Service Layer with Dependency Injection**

```
"Implement a notification service with Redis caching"
"Add analytics service with Prometheus metrics"
"Create admin service with role-based access"
```

Claude will:

- Use the established Service Layer pattern (`app/services/`)
- Implement BaseService with common functionality
- Add dependency injection using type hints
- Include Redis caching with fallback strategies
- Add Prometheus metrics collection
- Follow session-per-task database patterns
- Include comprehensive error handling and logging

**Modern Router Pattern**

```
"Add an admin panel with multiple commands"
"Create a support ticket system with callbacks"
```

Claude will:

- Create dedicated Router for feature grouping
- Use advanced filters with `F` object combinations
- Implement callback query handlers
- Add middleware for authentication/authorization
- Include proper state management

**Template Usage**

```
"Help me customize this template for an e-commerce bot"
"Adapt the template for customer support use case"
```

Claude will:

- Guide you through the template customization process
- Update project names and descriptions consistently
- Modify handlers for your specific use case
- Add domain-specific database models
- Update environment variables and deployment settings
- Ensure all documentation reflects your customizations

## Advanced Usage

### 🔍 Code Review

Ask Claude to review code:

```
"Review this handler for security and performance issues"
"Check if this database model follows best practices"
"Analyze this middleware for potential race conditions"
"Review the Service Layer implementation for best practices"
"Check Redis caching strategy and TTL settings"
"Analyze Prometheus metrics collection"
```

Claude will:

- Review against modern aiogram 3.0+ patterns
- Check Service Layer and dependency injection usage
- Verify session-per-task database patterns
- Analyze caching strategies and performance
- Review structured logging implementation
- Check test coverage and quality
- Verify deployment optimization and resource usage

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
"Run the test suite and check coverage"
"Add tests for Redis caching functionality"
```

Claude will:

- Use the existing comprehensive test suite (12 tests available)
- Create tests using pytest with async support
- Mock Telegram objects for handler testing
- Test Service Layer with dependency injection
- Test FastAPI webhook endpoints with test client
- Use SQLite in-memory database for fast isolated tests
- Run tests with coverage reporting: `uv run pytest --cov=app`
- Ensure tests pass before any deployment

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
"Redis cache hit rate is low, need to optimize caching"
"Database queries are slow, analyze indexes"
```

**Memory issues:**

```
"VPS running out of memory, need immediate tuning"
"Docker containers consuming too much RAM"
"PostgreSQL memory usage is high"
```

**Service Issues:**

```
"Redis is down, bot using memory fallback"
"Health checks failing intermittently"
"Prometheus metrics showing high error rate"
```

**Testing Issues:**

```
"Tests are failing after database changes"
"Need to add tests for new Service Layer functionality"
"Mock objects not working with new Router pattern"
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

- Learn new aiogram 3.0+ features and Router patterns
- Understand SQLAlchemy 2.0 async patterns and optimizations
- Master Service Layer architecture and dependency injection
- Follow async/await best practices and session-per-task patterns
- Implement Redis caching strategies and performance optimization
- Use Prometheus metrics and structured logging effectively
- Write comprehensive tests with pytest and async support
- Optimize deployments for 2GB VPS constraints

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
3. **Test Early**: Ask for testing strategies alongside implementation - 12 tests are available
4. **Service Layer First**: Use the established Service Layer pattern for all business logic
5. **Cache Wisely**: Leverage Redis caching with memory fallback for performance
6. **Monitor Everything**: Use Prometheus metrics and structured logging for observability
7. **Session Safety**: Always follow session-per-task pattern for database operations
8. **Template Ready**: This project works as a GitHub template for new bots
9. **Performance First**: Always consider 2GB VPS constraints and resource optimization
10. **Deploy Fast**: Optimized 4-5 minute deployments with Docker caching

**Remember**: Claude is designed to work with Hello Bot's modern architecture including Service Layer, Redis caching, Prometheus metrics, and comprehensive testing. The more context you provide about your specific use case, the better the assistance you'll receive!
