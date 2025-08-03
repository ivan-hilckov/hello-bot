"""
Bot message handlers
"""

from app.handlers.common import register_common_handlers
from app.handlers.start import register_start_handlers

__all__ = ["register_start_handlers", "register_common_handlers"]
