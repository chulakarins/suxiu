"""
锦绣智造后端应用
"""
from app.main import app
from app.config import settings

__version__ = settings.APP_VERSION
__all__ = ["app", "settings"]
