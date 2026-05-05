"""
用户 API 路由 - 获取/更新用户信息
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.database import get_db
from app.db.crud_user import get_user_by_id, update_user
from app.schemas.user import UserInfo, UserResponse
from app.schemas.response import success_response
from app.utils.auth import get_current_user

router = APIRouter()


@router.get("/me")
async def get_current_user_info(
    current_user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    获取当前用户信息
    """
    user = await get_user_by_id(db, current_user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="用户不存在"
        )

    return success_response(
        data={
            "user_id": user.id,
            "username": user.username,
            "phone": user.phone,
            "email": user.email,
            "avatar_url": user.avatar_url,
            "is_active": user.is_active,
            "created_at": user.created_at.isoformat() if user.created_at else None,
        }
    )


@router.put("/me")
async def update_current_user(
    request: UserInfo,
    current_user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    更新当前用户信息
    """
    user = await get_user_by_id(db, current_user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="用户不存在"
        )

    update_data = request.dict(exclude_unset=True)
    await update_user(db, user, **update_data)

    return success_response(
        data={
            "user_id": user.id,
            "username": user.username,
            "phone": user.phone,
            "email": user.email,
            "avatar_url": user.avatar_url,
        }
    )
