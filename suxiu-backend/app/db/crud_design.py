"""
设计 CRUD 操作
"""
import uuid
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from app.models.design import Design


async def create_design(
    db: AsyncSession,
    user_id: str,
    prompt: str,
    style: str = "traditional",
    size: str = "1280*1280",
    reference_image_urls: list = None,
    color_preferences: list = None,
) -> Design:
    """创建设计记录"""
    design = Design(
        id=str(uuid.uuid4()),
        user_id=user_id,
        prompt=prompt,
        style=style,
        size=size,
        reference_image_urls=reference_image_urls or [],
        color_preferences=color_preferences or [],
        status="pending",
        progress=0,
    )
    db.add(design)
    await db.flush()
    await db.refresh(design)
    return design


async def get_design_by_id(
    db: AsyncSession,
    design_id: str,
    user_id: str = None  # 可选，用于权限检查
) -> Optional[Design]:
    """根据 ID 获取设计"""
    query = select(Design).where(Design.id == design_id)
    if user_id:
        query = query.where(Design.user_id == user_id)
    result = await db.execute(query)
    return result.scalar_one_or_none()


async def update_design(
    db: AsyncSession,
    design: Design,
    **kwargs
) -> Design:
    """更新设计"""
    for key, value in kwargs.items():
        if hasattr(design, key):
            setattr(design, key, value)
    await db.flush()
    await db.refresh(design)
    return design


async def get_user_designs(
    db: AsyncSession,
    user_id: str,
    offset: int = 0,
    limit: int = 20,
    status: str = None,
) -> tuple[List[Design], int]:
    """获取用户的设计列表"""
    query = select(Design).where(Design.user_id == user_id)
    if status:
        query = query.where(Design.status == status)

    # 获取总数
    count_query = select(Design.id).where(Design.user_id == user_id)
    if status:
        count_query = count_query.where(Design.status == status)
    total = len(await db.execute(count_query))

    # 获取数据
    query = query.order_by(desc(Design.created_at)).offset(offset).limit(limit)
    result = await db.execute(query)
    designs = result.scalars().all()
    return list(designs), total


async def delete_design(
    db: AsyncSession,
    design: Design
):
    """删除设计"""
    await db.delete(design)
    await db.flush()
