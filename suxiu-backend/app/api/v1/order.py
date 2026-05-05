"""
订单 API 路由
"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional

from app.db.database import get_db
from app.db.crud_order import (
    create_order,
    get_order_by_id,
    update_order_status,
    update_order,
    cancel_order,
    get_user_orders,
)
from app.db.crud_design import get_design_by_id
from app.schemas.order import (
    OrderCreateRequest,
    OrderCancelRequest,
    OrderPricing,
    StatusHistory,
)
from app.schemas.response import success_response, ErrorCode
from app.utils.auth import get_current_user

router = APIRouter()


# 模拟定价逻辑
def calculate_pricing(design, product_type: str) -> dict:
    """计算订单价格"""
    # 实际项目应该根据设计复杂度、尺寸、工厂报价等计算
    base_pricing = {
        "framed": {
            "design_fee": 50.00,
            "material_cost": 200.00,
            "labor_cost": 500.00,
            "shipping_cost": 20.00,
        },
        "unframed": {
            "design_fee": 50.00,
            "material_cost": 150.00,
            "labor_cost": 350.00,
            "shipping_cost": 15.00,
        }
    }

    pricing = base_pricing.get(product_type, base_pricing["framed"])
    pricing["total"] = sum(pricing.values())
    pricing["currency"] = "CNY"

    return pricing


@router.post("/create")
async def create_order_endpoint(
    request: OrderCreateRequest,
    current_user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    创建订单

    1. 验证设计是否存在
    2. 计算价格
    3. 创建订单记录
    4. 返回支付信息
    """
    # 验证设计
    design = await get_design_by_id(db, request.design_id, user_id=current_user_id)
    if not design:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="设计不存在或未找到"
        )

    # 验证设计状态
    if design.status != "succeeded":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="设计尚未完成，无法创建订单"
        )

    # 计算价格
    pricing = calculate_pricing(design, request.product_type)

    # 构建收货地址
    shipping_info = request.shipping_address.model_dump()

    # 创建订单
    order = await create_order(
        db=db,
        user_id=current_user_id,
        design_id=request.design_id,
        shipping_info=shipping_info,
        pricing=pricing,
        product_type=request.product_type,
    )

    # 模拟生成支付 URL（实际项目应调用支付 API）
    payment_url = f"https://pay.example.com/pay?order_id={order.id}"

    return success_response(
        data={
            "order_id": order.id,
            "status": order.status,
            "pricing": pricing,
            "payment_url": payment_url,
            "expires_in": 1800  # 支付有效期 30 分钟
        }
    )


@router.get("/{order_id}")
async def get_order(
    order_id: str,
    current_user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    获取订单详情
    """
    order = await get_order_by_id(db, order_id, user_id=current_user_id)
    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="订单不存在"
        )

    # 获取设计图片
    design = await get_design_by_id(db, order.design_id)
    design_image = design.image_url if design else None

    # 构建状态信息
    status_info = {
        "current": order.status,
        "history": order.status_history or []
    }

    # 构建时间线
    timeline = {}
    if order.status_history:
        first_status = order.status_history[0]
        timeline["created_at"] = first_status.get("time")
        # 预计完成时间（简单估算）
        timeline["estimated_completion"] = "2026-04-10T18:00:00Z"
        timeline["estimated_delivery"] = "2026-04-13T18:00:00Z"

    return success_response(
        data={
            "order_id": order.id,
            "user_id": order.user_id,
            "design_id": order.design_id,
            "design_image": design_image,
            "factory_id": order.factory_id,
            "factory_name": order.factory_name,
            "status": status_info,
            "pricing": order.pricing,
            "shipping_info": order.shipping_info,
            "timeline": timeline,
            "created_at": order.created_at.isoformat() if order.created_at else None,
            "updated_at": order.updated_at.isoformat() if order.updated_at else None,
        }
    )


@router.get("/s")
async def list_orders(
    offset: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=50),
    status: Optional[str] = Query(None),
    current_user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    获取订单列表
    """
    orders, total = await get_user_orders(
        db=db,
        user_id=current_user_id,
        offset=offset,
        limit=limit,
        status=status,
    )

    order_list = []
    for o in orders:
        order_list.append({
            "order_id": o.id,
            "design_id": o.design_id,
            "status": o.status,
            "pricing": o.pricing,
            "factory_name": o.factory_name,
            "created_at": o.created_at.isoformat() if o.created_at else None,
        })

    return success_response(
        data={
            "total": total,
            "orders": order_list
        }
    )


@router.post("/{order_id}/cancel")
async def cancel_order_endpoint(
    order_id: str,
    request: OrderCancelRequest,
    current_user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    取消订单
    """
    order = await get_order_by_id(db, order_id, user_id=current_user_id)
    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="订单不存在"
        )

    # 检查是否可以取消
    if order.status not in ["pending_payment", "confirmed"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="当前状态无法取消订单"
        )

    await cancel_order(db, order, request.reason)

    return success_response(message="订单已取消")


@router.get("/{order_id}/track")
async def track_order(
    order_id: str,
    current_user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    跟踪订单状态
    """
    order = await get_order_by_id(db, order_id, user_id=current_user_id)
    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="订单不存在"
        )

    # 构建跟踪信息
    tracking = {
        "order_id": order.id,
        "current_status": order.status,
        "history": order.status_history or []
    }

    # 如果有物流信息
    if order.shipping_info and order.shipping_info.get("tracking_number"):
        tracking["tracking"] = {
            "express_company": order.shipping_info.get("express_company"),
            "tracking_number": order.shipping_info.get("tracking_number"),
            "logs": []  # 实际项目应从物流 API 获取
        }

    return success_response(data=tracking)
