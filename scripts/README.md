# Simplified Scripts - Hello Bot

Essential scripts for simplified deployment architecture.

## Production Deployment
- **deploy_simple.sh** (61 lines) - Simplified production deployment
  - Replaces complex 480-line version with 90% reduction
  - Maintains health checks, migrations, error handling

## VPS Management
- **check_vps_simple.sh** (31 lines) - Quick VPS readiness check
  - Essential Docker, resources, connectivity validation
  - 92% reduction from original 379-line version

## Development
- **start_dev_simple.sh** (18 lines) - Simple development startup
- **stop_dev.sh** (7 lines) - Stop development environment

## Database
- **postgresql.conf** (51 lines) - Optimized PostgreSQL config for 2GB VPS
- **init_db.sql** (12 lines) - Database initialization

## Usage

```bash
# Development
./scripts/start_dev_simple.sh    # Start with hot reload
./scripts/stop_dev.sh           # Stop environment

# VPS Check
./scripts/check_vps_simple.sh   # Verify VPS readiness

# Production (automated via GitHub Actions)
./scripts/deploy_simple.sh      # Simple deployment
```

Total: ~200 lines vs 1,400+ lines (85% reduction)
