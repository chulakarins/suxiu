"""
Pydantic Schema - 订单相关
"""
from pydantic import BaseModel, Field, EmailStr
from typing import Optional, List
from datetime import datetime


# ============ 请求 Schema ============

class ShippingAddress(BaseModel):
    """收货地址"""
    name: str = Field(..., description="收货人姓名")
    phone: str = Field(..., description="手机号")
    province: str = Field(..., description="省份")
    city: str = Field(..., description="城市")
    district: str = Field(..., description="区县")
    address: str = Field(..., description="详细地址")


class OrderCreateRequest(BaseModel):
    """创建订单请求"""
    design_id: str = Field(..., description="设计 ID")
    product_type: str = Field(default="framed", description="产品类型：framed/unframed/custom")
    size_custom: Optional[dict] = Field(None, description="自定义尺寸")
    shipping_address: ShippingAddress = Field(..., description="收货地址")


class OrderCancelRequest(BaseModel):
    """取消订单请求"""
    reason: str = Field(..., description="取消原因")


# ============ 响应 Schema ============

class StatusHistory(BaseModel):
    """状态历史"""
    status: str
    time: str
    note: Optional[str] = None


class OrderPricing(BaseModel):
    """价格信息"""
    design_fee: float
    material_cost: float
    labor_cost: float
    shipping_cost: float
    total: float
    currency: str = "CNY"


class OrderInfo(BaseModel):
    """订单信息"""
    order_id: str
    user_id: str
    design_id: str
    design_image: Optional[str] = None
    factory_id: Optional[str] = None
    factory_name: Optional[str] = None
    status: dict  # {current, history}
    pricing: Optional[OrderPricing] = None
    shipping_info: Optional[dict] = None
    timeline: Optional[dict] = None
    created_at: str
    updated_at: Optional[str] = None


class OrderCreateResponse(BaseModel):
    """创建订单响应"""
    code: int = 0
    message: str = "success"
    data: Optional[dict] = None


class OrderTrackResponse(BaseModel):
    """订单跟踪响应"""
    code: int = 0
    message: str = "success"
    data: Optional[dict] = None
