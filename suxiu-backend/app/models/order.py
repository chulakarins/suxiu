"""
订单数据模型
"""
from sqlalchemy import Column, String, DateTime, JSON, ForeignKey, Index, Text
from sqlalchemy.sql import func
from app.db.database import Base


class Order(Base):
    """订单表"""

    __tablename__ = "orders"

    id = Column(String(32), primary_key=True)
    user_id = Column(String(32), ForeignKey("users.id"), nullable=False, index=True)
    design_id = Column(String(32), ForeignKey("designs.id"), nullable=False)

    # 工厂信息
    factory_id = Column(String(32), nullable=True)
    factory_name = Column(String(100), nullable=True)

    # 订单状态
    status = Column(String(30), default="pending_payment")
    # pending_payment, confirmed, in_production, quality_check, shipped, delivered, completed, cancelled

    # 价格信息
    pricing = Column(JSON, nullable=True)
    """
    {
        "design_fee": 50.00,
        "material_cost": 200.00,
        "labor_cost": 500.00,
        "shipping_cost": 20.00,
        "total": 770.00,
        "currency": "CNY"
    }
    """

    # 物流信息
    shipping_info = Column(JSON, nullable=True)
    """
    {
        "name": "张三",
        "phone": "13800138000",
        "province": "江苏省",
        "city": "苏州市",
        "district": "姑苏区",
        "address": "XX 路 XX 号",
        "express_company": "顺丰速运",
        "tracking_number": "SF1234567890"
    }
    """

    # 状态历史
    status_history = Column(JSON, default=list)
    """
    [
        {"status": "pending_payment", "time": "2026-04-02T10:00:00Z", "note": ""},
        {"status": "confirmed", "time": "2026-04-02T11:00:00Z", "note": "支付成功"}
    ]
    """

    # 时间戳
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # 索引
    __table_args__ = (
        Index('idx_order_user', 'user_id', 'created_at'),
        Index('idx_order_status', 'status'),
    )

    def __repr__(self):
        return f"<Order {self.id} user={self.user_id} status={self.status}>"
