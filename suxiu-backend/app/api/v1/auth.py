"""
认证 API 路由 - 用户注册、登录、刷新 Token
"""
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import timedelta

from app.db.database import get_db
from app.utils.auth import get_current_user
from app.db.crud_user import create_user, get_user_by_username, get_user_by_id
from app.schemas.user import (
    UserRegisterRequest,
    UserLoginRequest,
    RefreshTokenRequest,
    TokenResponse,
    UserInfo,
    UserResponse,
)
from app.schemas.response import success_response, error_response, ErrorCode
from app.utils.auth import (
    verify_password,
    create_access_token,
    create_refresh_token,
    verify_token,
)

router = APIRouter()


@router.post("/register")
async def register(request: UserRegisterRequest, db: AsyncSession = Depends(get_db)):
    """
    用户注册

    - username: 用户名 (3-20 字符)
    - password: 密码 (8-32 字符)
    - phone: 手机号 (可选)
    - email: 邮箱 (可选)
    """
    # 检查用户名是否已存在
    existing_user = await get_user_by_username(db, request.username)
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="用户名已存在"
        )

    # 创建用户
    user = await create_user(
        db,
        username=request.username,
        password=request.password,
        phone=request.phone,
        email=request.email,
    )

    # 生成 Token
    access_token = create_access_token(
        data={"sub": user.id},
        expires_delta=timedelta(minutes=1440)
    )
    refresh_token = create_refresh_token(data={"sub": user.id})

    return success_response(
        data={
            "user_id": user.id,
            "username": user.username,
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer",
            "expires_in": 86400,
        }
    )


@router.post("/login")
async def login(request: UserLoginRequest, db: AsyncSession = Depends(get_db)):
    """
    用户登录

    - username: 用户名
    - password: 密码
    """
    # 查询用户
    user = await get_user_by_username(db, request.username)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="用户名或密码错误"
        )

    # 验证密码
    if not verify_password(request.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="用户名或密码错误"
        )

    # 检查账户状态
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="账户已被禁用"
        )

    # 生成 Token
    access_token = create_access_token(
        data={"sub": user.id},
        expires_delta=timedelta(minutes=1440)
    )
    refresh_token = create_refresh_token(data={"sub": user.id})

    return success_response(
        data={
            "user_id": user.id,
            "username": user.username,
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer",
            "expires_in": 86400,
        }
    )


@router.post("/refresh")
async def refresh_token(request: RefreshTokenRequest):
    """
    刷新访问令牌

    使用刷新令牌获取新的访问令牌
    """
    # 验证刷新令牌
    user_id = verify_token(request.refresh_token, token_type="refresh")
    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="刷新令牌无效或已过期"
        )

    # 生成新的访问令牌
    access_token = create_access_token(
        data={"sub": user_id},
        expires_delta=timedelta(minutes=1440)
    )

    return success_response(
        data={
            "access_token": access_token,
            "token_type": "bearer",
            "expires_in": 86400,
        }
    )


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
