#!/usr/bin/env python3
"""
Development runner with hot reloading for Hello Bot.
Automatically restarts the bot when code changes are detected.
"""

import asyncio
import logging
import subprocess
import sys
from pathlib import Path

from watchfiles import awatch

# Setup logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - DEV - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

# Configuration
WATCH_PATHS = ["app/"]  # Directories to watch for changes
IGNORE_PATTERNS = ["*.pyc", "__pycache__", "*.log", ".git", "*.tmp"]


class BotRunner:
    """Manages bot process with hot reloading."""

    def __init__(self):
        self.process = None
        self.restart_count = 0

    async def start_bot(self):
        """Start the bot process."""
        if self.process:
            await self.stop_bot()

        logger.info("Starting bot...")
        self.process = await asyncio.create_subprocess_exec(
            sys.executable,
            "-m",
            "app.main",
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.STDOUT,
        )

        # Start output monitoring task
        asyncio.create_task(self._monitor_output())

        self.restart_count += 1
        logger.info(f"Bot started (restart #{self.restart_count})")

    async def stop_bot(self):
        """Stop the bot process."""
        if self.process:
            logger.info("Stopping bot...")
            self.process.terminate()
            try:
                await asyncio.wait_for(self.process.wait(), timeout=5.0)
            except asyncio.TimeoutError:
                logger.warning("Bot didn't stop gracefully, killing...")
                self.process.kill()
            self.process = None

    async def _monitor_output(self):
        """Monitor bot output and log it."""
        if not self.process or not self.process.stdout:
            return

        try:
            async for line in self.process.stdout:
                decoded = line.decode().strip()
                if decoded:
                    print(f"BOT: {decoded}")
        except Exception as e:
            logger.error(f"Error monitoring bot output: {e}")

    async def restart_bot(self):
        """Restart the bot process."""
        logger.info("Code changes detected, restarting bot...")
        await self.start_bot()


async def main():
    """Main development runner."""
    logger.info("Starting development mode with hot reloading...")
    logger.info(f"Watching directories: {WATCH_PATHS}")

    runner = BotRunner()

    # Start the bot initially
    await runner.start_bot()

    try:
        # Watch for file changes
        async for changes in awatch(*WATCH_PATHS):
            if changes:
                # Filter out irrelevant changes
                relevant_changes = []
                for change_type, file_path in changes:
                    path = Path(file_path)
                    # Skip ignored patterns
                    if any(pattern in str(path) for pattern in IGNORE_PATTERNS):
                        continue
                    # Only watch Python files and config files
                    if path.suffix in [".py", ".yaml", ".yml", ".env"]:
                        relevant_changes.append((change_type, file_path))

                if relevant_changes:
                    logger.info(f"Detected changes: {[str(p[1]) for p in relevant_changes]}")
                    await runner.restart_bot()

                    # Small delay to avoid rapid restarts
                    await asyncio.sleep(1)

    except KeyboardInterrupt:
        logger.info("Received interrupt, shutting down...")
    except Exception as e:
        logger.error(f"Error in development runner: {e}")
    finally:
        await runner.stop_bot()
        logger.info("Development runner stopped")


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
