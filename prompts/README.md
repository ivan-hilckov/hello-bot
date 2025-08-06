# AI Collaboration Prompts

This directory contains prompt templates for effective AI collaboration on Hello Bot template projects.

## Usage Guide

These prompts are designed to work with AI assistants like Claude, Cursor, and ChatGPT to accelerate development and maintain code quality.

### Quick Start

1. **Creating New Bot**: Use `START.md` - the primary template for bootstrapping new bots
2. **File Analysis**: Use `analyze_file.md` for code review and optimization suggestions  
3. **Adding Features**: Use `add_feature.md` for systematic feature development
4. **Code Cleanup**: Use `simplify_code.md` for refactoring and optimization

### Best Practices

#### For Effective AI Collaboration:

1. **Be Specific**: Copy exact prompt text and customize with your specific requirements
2. **Provide Context**: Include relevant file paths, error messages, or requirements
3. **Iterate**: Use prompts multiple times as your bot evolves
4. **Track Changes**: Document what you've added/modified for future reference

#### Custom Prompt Creation:

To create custom prompts for specific files or features:

```markdown
# Analyze [FILENAME]

## Context
- File: `app/[FILENAME]`
- Purpose: [DESCRIBE PURPOSE]
- Current Issue: [DESCRIBE ISSUE]

## Task
[SPECIFIC ANALYSIS REQUEST]

## Requirements
- Follow Hello Bot simplified architecture
- Maintain ~320 line total codebase
- Use direct database operations (no service layer)
- Include type hints and proper error handling

## Output Format
1. **Issues Found**: List specific problems
2. **Recommendations**: Actionable improvements
3. **Code Examples**: Show exact changes needed
```

### Prompt Templates

| Template | Purpose | When to Use |
|----------|---------|-------------|
| `START.md` | Create new bot from template | Starting new project |
| `analyze_file.md` | Review specific file | Code review, bug hunting |
| `add_feature.md` | Add new functionality | Feature development |
| `simplify_code.md` | Optimize and clean code | Refactoring, performance |

### Bot Genealogy Tracking

When creating new bots, maintain genealogy:

- **HB-001**: First bot created from Hello Bot template
- **HB-002**: Second bot (may be evolved from HB-001)
- **HB-003**: Third bot, etc.

Document in your new bot's README:
```markdown
## Bot Genealogy
- **Parent**: Hello Bot Template
- **Bot ID**: HB-001
- **Created**: 2024-01-01
- **Purpose**: [Your bot's purpose]
```

### Advanced Usage

#### Multi-Step Development:

1. Use `START.md` to bootstrap
2. Use `add_feature.md` for each major feature
3. Use `analyze_file.md` to review and optimize
4. Use `simplify_code.md` for final cleanup

#### Template Customization:

Feel free to modify these templates for your specific use case:
- Add domain-specific requirements
- Include your coding standards
- Customize for your AI assistant preferences

## Integration with Hello Bot Architecture

All prompts are designed around Hello Bot's simplified architecture:

- **Single-file modules**: All related code in one file
- **Direct operations**: No service layer abstractions
- **Simple patterns**: Async/await, type hints, standard logging
- **Resource constraints**: ~320 total lines, 2GB VPS deployment

This ensures AI suggestions align with the template's philosophy of simplicity and maintainability.