"""
用户 CRUD 操作
"""
import uuid
from datetime import datetime
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.user import User
from app.utils.auth import get_password_hash


async def create_user(
    db: AsyncSession,
    username: str,
    password: str,
    phone: str = None,
    email: str = None
) -> User:
    """创建新用户"""
    user = User(
        id=str(uuid.uuid4()),
        username=username,
        password_hash=get_password_hash(password),
        phone=phone,
        email=email,
        is_active=True,
        is_verified=False,
    )
    db.add(user)
    await db.flush()
    await db.refresh(user)
    return user


async def get_user_by_username(
    db: AsyncSession,
    username: str
) -> Optional[User]:
    """根据用户名查询用户"""
    result = await db.execute(
        select(User).where(User.username == username)
    )
    return result.scalar_one_or_none()


async def get_user_by_id(
    db: AsyncSession,
    user_id: str
) -> Optional[User]:
    """根据 ID 查询用户"""
    result = await db.execute(
        select(User).where(User.id == user_id)
    )
    return result.scalar_one_or_none()


async def update_user(
    db: AsyncSession,
    user: User,
    **kwargs
) -> User:
    """更新用户信息"""
    for key, value in kwargs.items():
        if hasattr(user, key) and value is not None:
            setattr(user, key, value)
    await db.flush()
    await db.refresh(user)
    return user
