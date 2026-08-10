"""
应用配置管理
"""
import os
from typing import Optional
from pydantic_settings import BaseSettings
from pydantic import Field


class Settings(BaseSettings):
    """应用配置"""

    # 应用基础配置
    APP_NAME: str = "锦绣智造后端"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False

    # JWT 配置
    JWT_SECRET_KEY: str = Field(
        default="your-secret-key-change-in-production",
        description="JWT 密钥，生产环境必须修改"
    )
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440  # 24 小时
    JWT_REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    # 数据库配置
    DATABASE_URL: str = Field(
        default="postgresql://user:password@localhost:5432/suxiu_ai"
    )
    DATABASE_POOL_SIZE: int = 10
    DATABASE_MAX_OVERFLOW: int = 20

    # Redis 配置
    REDIS_HOST: str = "localhost"
    REDIS_PORT: int = 6379
    REDIS_DB: int = 0
    REDIS_PASSWORD: Optional[str] = None

    # 阿里云配置
    ALIYUN_REGION: str = "cn-hangzhou"
    ALIYUN_ACCESS_KEY_ID: str = ""
    ALIYUN_ACCESS_KEY_SECRET: str = ""

    # DashScope (通义万相) API Key
    DASHSCOPE_API_KEY: str = ""

    # OSS 配置
    OSS_BUCKET: str = "suxiu-ai-designs"
    OSS_ENDPOINT: str = "oss-cn-hangzhou.aliyuncs.com"
    OSS_STS_TOKEN_EXPIRE: int = 3600

    # AI 生成配置
    AI_POLL_INTERVAL: int = 5  # 秒
    AI_MAX_POLL_ATTEMPTS: int = 60
    AI_DEFAULT_SIZE: str = "1280*1280"

    # CORS 配置 (允许的 frontend 域名)
    CORS_ORIGINS: list = Field(
        default=["http://localhost:3000", "http://localhost:8080"]
    )

    class Config:
        env_file = ".env"
        case_sensitive = True


# 全局配置实例
settings = Settings()
