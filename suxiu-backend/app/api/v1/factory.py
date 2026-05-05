"""
工厂 API 路由
"""
from fastapi import APIRouter, Depends, HTTPException, status
from typing import Optional

from app.schemas.response import success_response, error_response, ErrorCode
from app.utils.auth import get_current_user

router = APIRouter()

# 模拟工厂数据
FACTORIES = [
    {
        "id": "factory_001",
        "name": "苏州刺绣厂",
        "location": {"province": "江苏省", "city": "苏州市"},
        "capabilities": ["traditional", "modern"],
        "quality_rating": 4.8,
        "is_active": True,
    },
    {
        "id": "factory_002",
        "name": "吴江丝绸工艺厂",
        "location": {"province": "江苏省", "city": "苏州市"},
        "capabilities": ["traditional", "minimalist"],
        "quality_rating": 4.6,
        "is_active": True,
    },
    {
        "id": "factory_003",
        "name": "镇湖刺绣工作室",
        "location": {"province": "江苏省", "city": "苏州市"},
        "capabilities": ["traditional", "modern", "minimalist"],
        "quality_rating": 4.9,
        "is_active": True,
    },
]


@router.get("/list")
async def list_factories(
    style: Optional[str] = None,
    current_user_id: str = Depends(get_current_user)
):
    """
    获取工厂列表

    - style: 可选，按工艺风格筛选
    """
    factories = FACTORIES

    # 按风格筛选
    if style:
        factories = [f for f in factories if style in f.get("capabilities", [])]

    # 只返回活跃工厂
    factories = [f for f in factories if f.get("is_active")]

    return success_response(
        data={
            "total": len(factories),
            "factories": factories
        }
    )


@router.get("/{factory_id}")
async def get_factory(
    factory_id: str,
    current_user_id: str = Depends(get_current_user)
):
    """
    获取工厂详情
    """
    factory = next((f for f in FACTORIES if f["id"] == factory_id), None)
    if not factory:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="工厂不存在"
        )

    return success_response(data=factory)


@router.post("/{factory_id}/rating")
async def rate_factory(
    factory_id: str,
    rating: dict,
    current_user_id: str = Depends(get_current_user)
):
    """
    评价工厂

    rating: {
        "score": 5,  // 1-5 分
        "comment": "很好",
        "order_id": "ord_xxx"
    }
    """
    # 实际项目应保存到数据库
    return success_response(message="评价已提交")
