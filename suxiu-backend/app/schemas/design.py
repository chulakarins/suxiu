"""
Pydantic Schema - 设计相关
"""
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


# ============ 请求 Schema ============

class DesignGenerateRequest(BaseModel):
    """设计生成请求"""
    prompt: str = Field(..., min_length=1, max_length=1000, description="提示词")
    style: str = Field(default="traditional", description="风格：traditional/modern/minimalist")
    size: str = Field(default="1280*1280", description="尺寸")
    reference_image_urls: List[str] = Field(default=[], description="参考图片 URL")
    color_preferences: List[str] = Field(default=[], description="颜色偏好")


class DesignRefineRequest(BaseModel):
    """设计优化请求"""
    design_id: str
    refinement_prompt: str = Field(..., description="优化要求")


class DesignVariationsRequest(BaseModel):
    """生成变体请求"""
    design_id: str
    count: int = Field(default=3, ge=1, le=5, description="变体数量 (1-5)")


# ============ 响应 Schema ============

class TaskStatusResponse(BaseModel):
    """任务状态"""
    task_id: str
    status: str  # pending/running/succeeded/failed
    progress: int
    result: Optional[dict] = None
    message: Optional[str] = None
    estimated_time: Optional[int] = None


class DesignSpecs(BaseModel):
    """制作规格"""
    dimensions: Optional[dict] = None  # {width, height, unit}
    stitch_types: Optional[List[str]] = None  # 针法类型
    thread_colors: Optional[List[dict]] = None  # 线材颜色
    estimated_time: Optional[int] = None  # 预估工时 (小时)
    difficulty: Optional[str] = None  # easy/medium/hard


class DesignInfo(BaseModel):
    """设计信息"""
    design_id: str
    user_id: str
    prompt: str
    style: str
    size: str
    image_url: Optional[str] = None
    thumbnail_url: Optional[str] = None
    specs: Optional[DesignSpecs] = None
    status: str
    progress: int
    created_at: datetime
    updated_at: Optional[datetime] = None


class DesignListResponse(BaseModel):
    """设计列表响应"""
    total: int
    designs: List[DesignInfo]


class DesignGenerateResponse(BaseModel):
    """设计生成响应"""
    code: int = 0
    message: str = "success"
    data: Optional[TaskStatusResponse] = None
