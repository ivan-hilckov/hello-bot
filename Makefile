.PHONY: install run format check clean help

# Install dependencies
install:
	uv sync

# Run the simple bot
run:
	uv run python simple_bot.py

# Format code
format:
	uv run ruff format .

# Check code
check:
	uv run ruff check . --fix

# Clean cache files
clean:
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -name "*.pyc" -delete
	find . -name "*.pyo" -delete

# Help
help:
	@echo "Available targets:"
	@echo "  install - Install dependencies with uv"
	@echo "  run     - Run the simple bot"
	@echo "  format  - Format code with ruff"
	@echo "  check   - Check code with ruff"
	@echo "  clean   - Clean cache files"
	@echo "  help    - Show this help"
