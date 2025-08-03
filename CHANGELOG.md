# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v1.1.0] - 2025-01-03

### Added

- **GitHub Template Support**: Complete transformation into GitHub template repository
  - `.github/template.yml` - GitHub template configuration
  - `scripts/setup-template.sh` - Interactive project initialization script
  - `TEMPLATE_README.md` - Template-specific README with usage instructions
  - `docs/TEMPLATE_USAGE.md` - Comprehensive template usage guide
  - `TEMPLATE_SETUP.md` - Instructions for template maintainers

- **Template Features**:
  - Automatic project name replacement throughout all files
  - Interactive setup with validation and confirmation
  - Database and container name customization
  - GitHub Actions workflow adaptation
  - Documentation generation for new projects
  - Template file cleanup after initialization

- **Enhanced Template Architecture**:
  - Universal bot greeting messages (removes Hello Bot specific text)
  - Configurable project metadata in pyproject.toml
  - Docker compose and container naming templates
  - Version synchronization across all components

### Changed

- **Version Consistency**: Updated all components to version 1.1.0
  - `app/__init__.py`, `app/main.py`, `app/webhook.py`
  - `Dockerfile`, `docs/API.md`, `docs/DEPLOYMENT.md`
  - Synchronized version reporting in health checks and logs

- **Template Preparation**: Made repository ready for "Use this template" functionality
  - Removed Hello Bot specific branding from core components
  - Created reusable configuration patterns
  - Established clear customization points for new projects

### Fixed

- **Template Compatibility**: Ensured all placeholder values can be safely replaced
- **Setup Script Permissions**: Made setup script executable by default

## [v0.3.0] - 2025-01-03

### Added

- **Documentation Restructure**: Complete documentation reorganization for better clarity

  - New `docs/ARCHITECTURE.md` with technical details and dependencies
  - New `docs/DATABASE.md` with schema diagrams and model documentation
  - New `docs/API.md` with bot commands and handler documentation
  - Mermaid diagrams for database schema and application flow
  - Clear separation of development vs production documentation

- **Enhanced Documentation with Modern Best Practices**:

  - **aiogram 3.0+ Router Pattern**: Added Router concept and modular handler organization
  - **Advanced Dependency Injection**: Enhanced DI patterns with type hints and custom providers
  - **AsyncSession Concurrency**: Critical safety guidelines for session-per-task pattern
  - **Modern Filters**: Custom filter classes and composable filter expressions
  - **Alembic Async Patterns**: Modern env.py configuration for async applications
  - **Post-Write Hooks**: Code quality automation with ruff integration
  - **Connection Pool Optimization**: Production-ready database settings for 2GB VPS

- **AI Development Guide**: New `CLAUDE.md` with comprehensive guide for working with Claude AI assistant
  - **Effective Prompting**: Best practices for AI-assisted development
  - **Project-Specific Guidelines**: Context-aware development patterns
  - **Common Scenarios**: Ready-to-use prompts for typical development tasks
  - **Emergency Procedures**: Quick diagnostic and troubleshooting guidance
  - **Integration Tips**: Seamless workflow with Cursor IDE and development tools

### Changed

- **README.md**: Simplified to focus on quick start and essential information
- **Documentation Structure**: Moved all detailed docs to `docs/` folder
- **docs/DEVELOPMENT.md**: Streamlined local development setup guide
- **docs/DEPLOYMENT.md**: Simplified production deployment guide

### Removed

- **Redundant Documentation Files**:
  - `docs/QUICK_START.md` (content moved to README.md)
  - `docs/README.md` (unnecessary index file)
  - `DOCKER_BUILD_FIX.md` (content preserved in changelog)
  - `DEPLOYMENT_OPTIMIZATION.md` (content preserved in changelog)
  - `DEPLOYMENT_IMPROVEMENTS.md` (content preserved in changelog)

### Fixed

- **GitHub Actions Deployment**: Fixed `appleboy/scp-action` version from non-existent `v0.1.8` to correct `v1.0.0`
- **Docker Compose Migration**: Added `migration` profile to `postgres` service to resolve dependency issues during database migrations
- **Database Migration Handling**: Implemented smart migration logic to handle existing database tables gracefully

### Changed

- **Deployment Script Optimization**: Significantly simplified `scripts/deploy_production.sh`
  - Reduced migration logic from ~70 lines of complex code to ~30 lines of simple logic
  - Simplified parallel preparation from ~50 lines to ~10 lines
  - Removed redundant `prepare_environment()` function
  - Improved error handling for database migrations with "try → fallback → show error" approach
- **Migration Strategy**: Replaced complex database state checking with simple Alembic stamp approach for existing tables

### Removed

- Complex Python database queries in deployment script
- Redundant environment preparation functions
- Temporary status files for parallel task tracking
- ~100 lines of unnecessary complex code

### Technical Details

- **Files Modified**:
  - `.github/workflows/deploy.yml` - Fixed action version
  - `docker-compose.yml` - Added migration profile to postgres service
  - `scripts/deploy_production.sh` - Simplified and optimized deployment logic

### Performance Improvements

- Faster deployment script execution due to simplified logic
- Better error recovery for database migration scenarios
- Reduced maintenance overhead with cleaner, more readable code

### Migration Notes

- Deployment now automatically handles cases where database tables already exist
- No manual intervention required for existing database states
- Backward compatible with clean database installations

---

## [v0.2.0] - 2024-12-22

### Added

- **Docker Build Optimization**: Fixed `uv.lock` not found error
  - Added `uv.lock` to repository for reproducible builds
  - Enhanced Dockerfile to work with/without lock file
  - Optimized Docker layer caching strategy

### Changed

- **Deployment Time Optimization**: Reduced deployment time from 8-10 minutes to 2-3 minutes
  - **GitHub Actions**: Enhanced Docker caching (registry + GHA + buildcache)
  - **Dockerfile**: Optimized layer structure and cache mounts
  - **Docker Compose**: Fast health checks (5s intervals vs 30s)
  - **Deployment Script**: Parallel operations and fast health checks
  - **Build Context**: Minimal `.dockerignore` for faster builds

### Performance Improvements

- **70% deployment time reduction** through parallel operations
- **Enhanced Docker caching** reduces build time by 2-3 minutes
- **Fast health checks** reduce startup verification by 1-2 minutes
- **Separate migration service** prevents deployment bottlenecks
- **Resource optimization** for 2GB RAM VPS deployment

### Technical Details

- **Files Modified**:
  - `.github/workflows/deploy.yml` - Enhanced caching strategy
  - `Dockerfile` - Optimized structure and cache mounts
  - `docker-compose.yml` - Separate migration service and fast health checks
  - `scripts/deploy_production.sh` - Parallel operations and timing
  - `.dockerignore` - Minimal build context

---

## [v0.1.0] - Initial Release

### Added

- **Core Bot Functionality**:

  - Basic Hello Bot implementation with PostgreSQL database
  - `/start` command with personalized greetings
  - User management and database storage

- **Production Infrastructure**:

  - Docker-based deployment with GitHub Actions
  - Alembic database migrations
  - Production-ready configuration for VPS deployment
  - Health checks and graceful shutdown

- **Technology Stack**:
  - Python 3.12+ with aiogram 3.0+
  - SQLAlchemy 2.0 async + PostgreSQL 15
  - FastAPI webhook server for production
  - Pydantic settings management
