# Roadmap to Goal - Hello Bot Template

## Analysis of Current State vs GOAL.md

### ✅ What is Already Achieved:

1. **Database with User table** ✅
   - SQLAlchemy 2.0 with async support
   - User model with basic fields (telegram_id, username, first_name, last_name, language_code)
   - Alembic migrations configured

2. **Flexible VPS deployment** ✅
   - Docker Compose configuration for production
   - GitHub Actions for automated deployment
   - Shared PostgreSQL architecture for resource optimization

3. **Separate database container** ✅
   - Shared PostgreSQL container
   - Isolated databases for each bot
   - VPS resource optimization

4. **Simple architecture** ✅
   - ~320 lines of code in app/
   - Direct database operations (no service layer)
   - Simple handlers

5. **Flexible stack** ✅
   - Python 3.12+, aiogram 3.0+, SQLAlchemy 2.0
   - Docker containerization
   - Type hints everywhere

6. **Linters configured** ✅
   - Ruff for code formatting and checking
   - VS Code settings

7. **Documentation** ✅
   - Complete documentation in docs/ folder
   - README with quick start
   - CLAUDE.md for AI context

8. **AI context files** ✅
   - CLAUDE.md with detailed instructions
   - .cursorignore configured

### ❌ What Needs Work:

1. **Tests are broken** ❌
   - Imports broken (app.database.base doesn't exist)
   - Tests reference old architecture with service layer
   - No integration in CI/CD pipeline

2. **Missing prompts folder** ❌
   - No START.md for creating new bots based on template
   - No standard prompts for working with project
   - No instructions for code analysis to find simplifications

3. **Hello Bot hardcode** ⚠️
   - Partially fixed: using ${PROJECT_NAME} in docker-compose
   - Hardcode remains in greeting texts in handlers.py
   - No clear description of what needs to be changed in START.md

4. **Technology documentation** ❌
   - No summary file with all technologies and their descriptions
   - Difficult for developers to understand the entire stack without studying code

---

## Step-by-Step Plan to Achieve Goal

### Stage 1: Fix Tests and Integrate into CI/CD

**Tasks:**
1. **Fix test imports**
   - Update conftest.py for current architecture
   - Remove references to app.database.base and services
   - Adapt tests for direct database operations

2. **Create simple working tests**
   - Test user creation
   - Test /start command handling
   - Test database connection

3. **Integrate tests into GitHub Actions**
   - Add test stage to .github/workflows/deploy.yml
   - Tests must pass before deployment

**Result:** Green tests integrated into CI/CD pipeline

### Stage 2: Create prompts folder with key templates

**Tasks:**
1. **Create prompts/ structure**
   ```
   prompts/
   ├── README.md          # Instructions for using prompts
   ├── START.md           # Main prompt for creating new bot
   ├── code_analysis.md   # Template for code analysis
   └── optimization.md    # Template for finding simplifications
   ```

2. **START.md - key file**
   - LLM prompt with instructions for creating new bot
   - Clear description of what needs to be changed (name, description, goals)
   - Bot numbering instructions for catalog
   - List of files with Hello Bot hardcode

3. **README.md in prompts/**
   - Instructions on how to use prompts
   - How to create custom prompt for file analysis
   - Best practices for working with AI

**Result:** Ready prompt system for creating new bots

### Stage 3: Remove hardcode and create configurable template

**Tasks:**
1. **Inventory hardcode**
   - Find all mentions of "Hello", "hello-bot", "Hello Bot"
   - Determine what should be configurable

2. **Move to configuration**
   - Greeting texts in handlers.py
   - Project name in various files
   - Descriptions in documentation

3. **Update START.md**
   - Exact list of files to change
   - Instructions for replacing names and descriptions

**Result:** Fully configurable template without hardcode

### Stage 4: Create technology documentation

**Tasks:**
1. **Create docs/TECHNOLOGIES.md**
   - List of all used technologies
   - Brief description of each purpose
   - Links to official documentation
   - Links to GitHub repositories

2. **File structure:**
   ```markdown
   # Technologies Stack
   
   ## Core Technologies
   - **Python 3.12+** - Programming language
   - **aiogram 3.0+** - Telegram Bot API framework
   - **SQLAlchemy 2.0** - Database ORM
   
   ## Infrastructure
   - **Docker** - Containerization
   - **PostgreSQL 15** - Database
   - **GitHub Actions** - CI/CD
   
   ## Development Tools
   - **Ruff** - Code formatting and linting
   - **Alembic** - Database migrations
   - **pytest** - Testing framework
   ```

3. **Update main documentation**
   - Add link to TECHNOLOGIES.md in README
   - Update descriptions in other docs files

**Result:** Clear documentation of entire technical stack

### Stage 5: Final verification and template fixation

**Tasks:**
1. **Create test_template.md**
   - Checklist for template readiness verification
   - Instructions for testing new bot creation

2. **Conduct full testing**
   - Create repository clone following START.md instructions
   - Ensure everything works on VPS
   - Test new bot deployment alongside Hello Bot

3. **Prepare for publication**
   - Final review of all documentation
   - Check GitHub Actions workflows
   - Test on clean environment

**Result:** Ready-to-use Hello Bot template

---

## Success Criteria

### Functional Criteria:
- ✅ **Tests green**: all tests pass in CI/CD
- ✅ **START.md works**: can create new bot following instructions
- ✅ **No hardcode**: template is fully configurable
- ✅ **Complete documentation**: developer can work without studying code

### Technical Criteria:
- ✅ **Deploy works**: new bot deploys to VPS alongside Hello Bot
- ✅ **Resources optimized**: uses shared PostgreSQL
- ✅ **AI ready**: Claude/Cursor understands project through CLAUDE.md

### Business Criteria:
- ✅ **Template ready**: can create repositories via "Use this template"
- ✅ **Scaling ready**: can create bot catalog
- ✅ **Evolution ready**: each bot can become basis for next one

---

## Execution Priorities

### 🔥 Critical (blocks goal):
1. **Fix tests** - without them can't be confident in stability
2. **Create START.md** - key file for creating new bots
3. **Remove hardcode** - without this template isn't universal

### 🚀 Important (improves UX):
4. **Technology documentation** - helps developers
5. **Analysis prompts** - speeds up AI work

### 📋 Useful (completes picture):
6. **Final testing** - quality guarantee
7. **Test template checklist** - operational readiness

---

## Time Estimation

**Total estimate:** 1-2 days of active work

**By stages:**
- Stage 1 (tests): 4-6 hours
- Stage 2 (prompts): 3-4 hours  
- Stage 3 (hardcode): 2-3 hours
- Stage 4 (documentation): 2-3 hours
- Stage 5 (finalization): 2-4 hours

**Critical path:** tests → START.md → hardcode → final verification

---

## Next Steps

1. **Immediately:** Fix tests and run them
2. **Today:** Create prompts/ structure and START.md
3. **Tomorrow:** Remove hardcode and create TECHNOLOGIES.md
4. **Final:** Full testing of new bot creation

After completing the plan, Hello Bot will become a full-fledged template for creating Telegram bots with evolution and scaling capabilities according to the concept from GOAL.md.