# 🛠️ Converting to GitHub Template

This document explains how to set up this repository as a GitHub template and what changes need to be made.

## 📋 Checklist for Template Preparation

### ✅ Completed Template Files

- [x] `.github/template.yml` - GitHub template configuration
- [x] `scripts/setup-template.sh` - Interactive setup script
- [x] `TEMPLATE_README.md` - Template-specific README
- [x] `docs/TEMPLATE_USAGE.md` - Detailed usage guide
- [x] `TEMPLATE_SETUP.md` - This file

### 🔄 Required Changes (Manual)

To complete the template setup, these changes need to be made:

#### 1. Update README.md

Replace the current README with template-friendly content:

```bash
# Backup current README
mv README.md README_HELLO_BOT.md

# Use template README
mv TEMPLATE_README.md README.md
```

#### 2. Update Handler Messages

**File**: `app/handlers/start.py`
**Line 60**: Change specific message to generic:

```python
# Current (specific to Hello Bot)
greeting = f"Hello world test deploy 🪏🪏🪏, <b>{user.display_name}</b>"

# Template version (generic)
greeting = f"Hello! Welcome to the bot, <b>{user.display_name}</b>"
```

#### 3. Update Project Metadata

**File**: `pyproject.toml`
**Lines 6-8**: Make more generic:

```toml
# Current
name = "hello-bot"
version = "0.3.0"
description = "Minimal Telegram bot for deployment testing"

# Template version
name = "telegram-bot-template"
version = "1.0.0"
description = "Production-ready Telegram bot template with PostgreSQL and Docker"
```

#### 4. Update GitHub Actions

**File**: `.github/workflows/deploy.yml`
**Lines 1, 19**: Make generic:

```yaml
# Current
name: Deploy Hello Bot to VPS
IMAGE_NAME: ${{ secrets.DOCKERHUB_USERNAME }}/hello-bot

# Template version
name: Deploy Telegram Bot to VPS
IMAGE_NAME: ${{ secrets.DOCKERHUB_USERNAME }}/telegram-bot-template
```

#### 5. Make Scripts Executable

```bash
chmod +x scripts/setup-template.sh
chmod +x scripts/deploy_production.sh
```

### 🏷️ GitHub Repository Settings

After making code changes, configure GitHub repository:

#### 1. Enable Template Repository

1. Go to **Settings** → **General**
2. Scroll to **Template repository**
3. Check ✅ **Template repository**
4. Save changes

#### 2. Configure Repository Settings

- **Description**: `🤖 Production-ready Telegram bot template with PostgreSQL, Docker & CI/CD`
- **Topics**: `telegram`, `bot`, `python`, `template`, `docker`, `postgresql`, `fastapi`, `aiogram`
- **Enable**: Issues, Security, Sponsorships
- **Disable**: Wikis, Projects, Packages (unless needed)

#### 3. Create Template Releases

```bash
# Tag the template version
git tag -a v1.0.0 -m "Initial template release"
git push origin v1.0.0
```

### 📝 Optional Improvements

#### Add Template Specific Folders

```bash
# Create example folders for common use cases
mkdir -p examples/business-bot
mkdir -p examples/ai-assistant
mkdir -p examples/notification-bot

# Add example configurations
echo "# Business Bot Example" > examples/business-bot/README.md
echo "# AI Assistant Example" > examples/ai-assistant/README.md
echo "# Notification Bot Example" > examples/notification-bot/README.md
```

#### Add .github/ISSUE_TEMPLATE

```yaml
# .github/ISSUE_TEMPLATE/bug_report.yml
name: Bug Report
description: Report a bug in the template
title: "[BUG] "
labels: ["bug", "template"]
body:
  - type: input
    id: setup-method
    attributes:
      label: Setup Method
      description: How did you set up the template?
      placeholder: "Used setup script / Manual setup"
    validations:
      required: true
```

#### Add .github/PULL_REQUEST_TEMPLATE.md

```markdown
## Template Improvement

### Changes Made

- [ ] Updated documentation
- [ ] Fixed bug in setup script
- [ ] Added new feature
- [ ] Improved configuration

### Testing

- [ ] Tested setup script
- [ ] Verified with new project creation
- [ ] Checked all file replacements work

### Description

Brief description of the changes and why they improve the template.
```

## 🚀 Using the Template

Once configured, users can:

### 1. Create from Template

1. Click **"Use this template"** on GitHub
2. Create new repository
3. Clone locally
4. Run setup script: `./scripts/setup-template.sh`

### 2. Automated Setup

The setup script will:

- ✅ Prompt for project details
- ✅ Replace all placeholder names
- ✅ Update configuration files
- ✅ Generate project-specific README
- ✅ Clean up template files

### 3. Immediate Development

After setup:

- Add `BOT_TOKEN` to `.env`
- Run `docker compose up -d`
- Start customizing bot logic

## 🎯 Template Benefits

### For Users

- **Fast Setup**: 5-minute project initialization
- **Production Ready**: All infrastructure included
- **Best Practices**: Modern architecture patterns
- **Documentation**: Complete setup guides
- **Flexibility**: Easy customization points

### For Maintainers

- **Reusable**: Template prevents code duplication
- **Standardized**: Consistent project structure
- **Scalable**: Easy to add new features
- **Community**: Users can contribute improvements

## 🔧 Maintenance

To maintain the template:

### Regular Updates

1. **Dependencies**: Keep packages up to date
2. **Documentation**: Update guides and examples
3. **Features**: Add commonly requested functionality
4. **Bug Fixes**: Fix issues reported by users

### Version Management

```bash
# Release new template versions
git tag -a v1.1.0 -m "Added AI assistant features"
git push origin v1.1.0
```

### Community Feedback

- Monitor GitHub issues for template problems
- Review pull requests for improvements
- Update based on user feedback

---

🎉 **Template is ready for production use!**

Users can now create professional Telegram bots in minutes instead of hours.
