"""
用户数据模型
"""
from sqlalchemy import Column, String, DateTime, Boolean
from sqlalchemy.sql import func
from app.db.database import Base


class User(Base):
    """用户表"""

    __tablename__ = "users"

    id = Column(String(32), primary_key=True)
    username = Column(String(50), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    phone = Column(String(20), nullable=True)
    email = Column(String(100), nullable=True)
    avatar_url = Column(String(500), nullable=True)

    # 账户状态
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)

    # 时间戳
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    def __repr__(self):
        return f"<User {self.username}>"
