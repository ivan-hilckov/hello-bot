-- Database initialization script for Hello Bot
-- This script runs automatically when PostgreSQL container starts

-- Ensure UTF8 encoding
ALTER DATABASE hello_bot SET timezone TO 'UTC';

-- Create extension for UUID generation (if needed in future)
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Log initialization
\echo 'Hello Bot database initialized successfully!'
