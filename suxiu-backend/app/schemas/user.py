"""
Pydantic Schema - 用户相关
"""
from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime


# ============ 请求 Schema ============

class UserRegisterRequest(BaseModel):
    """用户注册请求"""
    username: str = Field(..., min_length=3, max_length=20, description="用户名 (3-20 字符)")
    password: str = Field(..., min_length=8, max_length=32, description="密码 (8-32 字符)")
    phone: Optional[str] = Field(None, description="手机号")
    email: Optional[EmailStr] = Field(None, description="邮箱")


class UserLoginRequest(BaseModel):
    """用户登录请求"""
    username: str = Field(..., description="用户名")
    password: str = Field(..., description="密码")


class RefreshTokenRequest(BaseModel):
    """刷新 Token 请求"""
    refresh_token: str = Field(..., description="刷新令牌")


class ProfileUpdateRequest(BaseModel):
    """个人信息更新请求"""
    phone: Optional[str] = None
    email: Optional[EmailStr] = None
    avatar_url: Optional[str] = None


# ============ 响应 Schema ============

class TokenResponse(BaseModel):
    """Token 响应"""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int  # 过期时间 (秒)


class UserInfo(BaseModel):
    """用户信息"""
    user_id: str
    username: str
    phone: Optional[str] = None
    email: Optional[str] = None
    avatar_url: Optional[str] = None
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


class UserResponse(BaseModel):
    """用户响应"""
    code: int = 0
    message: str = "success"
    data: Optional[UserInfo] = None
