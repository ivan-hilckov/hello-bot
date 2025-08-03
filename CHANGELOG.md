# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - 2025-01-03

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

## Previous Releases

### [Initial Release]

- Basic Hello Bot implementation with PostgreSQL database
- Docker-based deployment with GitHub Actions
- Alembic database migrations
- Production-ready configuration for VPS deployment
