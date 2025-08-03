"""
Bot message handlers using modern Router pattern
"""

from app.handlers.common import common_router
from app.handlers.start import start_router

__all__ = ["start_router", "common_router"]
