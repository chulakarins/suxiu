"""
订单 CRUD 操作
"""
import uuid
from datetime import datetime
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from app.models.order import Order


async def create_order(
    db: AsyncSession,
    user_id: str,
    design_id: str,
    shipping_info: dict,
    pricing: dict,
    product_type: str = "framed",
) -> Order:
    """创建订单"""
    order = Order(
        id=str(uuid.uuid4()),
        user_id=user_id,
        design_id=design_id,
        status="pending_payment",
        shipping_info=shipping_info,
        pricing=pricing,
        product_type=product_type,
        status_history=[
            {
                "status": "pending_payment",
                "time": datetime.utcnow().isoformat() + "Z",
                "note": "订单创建"
            }
        ]
    )
    db.add(order)
    await db.flush()
    await db.refresh(order)
    return order


async def get_order_by_id(
    db: AsyncSession,
    order_id: str,
    user_id: str = None
) -> Optional[Order]:
    """根据 ID 获取订单"""
    query = select(Order).where(Order.id == order_id)
    if user_id:
        query = query.where(Order.user_id == user_id)
    result = await db.execute(query)
    return result.scalar_one_or_none()


async def update_order_status(
    db: AsyncSession,
    order: Order,
    new_status: str,
    note: str = ""
) -> Order:
    """更新订单状态"""
    order.status = new_status

    # 添加状态历史记录
    history_entry = {
        "status": new_status,
        "time": datetime.utcnow().isoformat() + "Z",
        "note": note
    }
    if order.status_history is None:
        order.status_history = []
    order.status_history.append(history_entry)

    await db.flush()
    await db.refresh(order)
    return order


async def update_order(
    db: AsyncSession,
    order: Order,
    **kwargs
) -> Order:
    """更新订单"""
    for key, value in kwargs.items():
        if hasattr(order, key):
            setattr(order, key, value)
    await db.flush()
    await db.refresh(order)
    return order


async def get_user_orders(
    db: AsyncSession,
    user_id: str,
    offset: int = 0,
    limit: int = 20,
    status: str = None,
) -> tuple[List[Order], int]:
    """获取用户订单列表"""
    query = select(Order).where(Order.user_id == user_id)
    if status:
        query = query.where(Order.status == status)

    # 获取总数
    from sqlalchemy import func
    count_query = select(func.count(Order.id)).where(Order.user_id == user_id)
    if status:
        count_query = count_query.where(Order.status == status)
    total_result = await db.execute(count_query)
    total = total_result.scalar() or 0

    # 获取数据
    query = query.order_by(desc(Order.created_at)).offset(offset).limit(limit)
    result = await db.execute(query)
    orders = result.scalars().all()
    return list(orders), total


async def cancel_order(
    db: AsyncSession,
    order: Order,
    reason: str
) -> Order:
    """取消订单"""
    return await update_order_status(
        db, order,
        new_status="cancelled",
        note=f"用户取消：{reason}"
    )
