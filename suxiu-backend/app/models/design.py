"""
设计数据模型
"""
from sqlalchemy import Column, String, DateTime, Text, JSON, Integer, ForeignKey, Index
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.db.database import Base


class Design(Base):
    """设计表"""

    __tablename__ = "designs"

    id = Column(String(32), primary_key=True)
    user_id = Column(String(32), ForeignKey("users.id"), nullable=False, index=True)

    # 输入信息
    prompt = Column(Text, nullable=False)  # 用户提示词
    style = Column(String(20), default="traditional")  # 风格：traditional/modern/minimalist
    size = Column(String(20), default="1280*1280")  # 尺寸
    reference_image_urls = Column(JSON, default=list)  # 参考图片 URL 列表
    color_preferences = Column(JSON, default=list)  # 颜色偏好

    # 生成结果
    image_url = Column(Text, nullable=True)  # 生成的图片 URL
    thumbnail_url = Column(Text, nullable=True)  # 缩略图 URL

    # 制作规格
    specs = Column(JSON, nullable=True)  # 包含尺寸、针法、线材等

    # 任务状态
    task_id = Column(String(64), nullable=True)  # AI 任务 ID
    status = Column(String(20), default="pending")  # pending/running/succeeded/failed
    progress = Column(Integer, default=0)  # 进度 0-100

    # 时间戳
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # 索引
    __table_args__ = (
        Index('idx_design_user_status', 'user_id', 'status'),
    )

    def __repr__(self):
        return f"<Design {self.id} prompt={self.prompt[:20]}...>"
