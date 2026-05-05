"""
上传 API 路由 - 阿里云 OSS 上传凭证
"""
from fastapi import APIRouter, Depends, HTTPException, status
import time
import hmac
import hashlib
import base64
from urllib.parse import quote

from app.config import settings
from app.schemas.response import success_response
from app.utils.auth import get_current_user

router = APIRouter()


def get_oss_signature(
    bucket: str,
    expire_time: int = 3600
) -> dict:
    """
    生成阿里云 OSS STS 临时上传凭证

    注意：生产环境应该调用阿里云 STS 服务获取临时凭证
    这里为了简化直接使用主账号 AK（不推荐）
    """
    # 过期时间
    expiration = int(time.time()) + expire_time

    # 简单签名（实际项目应使用 STS 服务）
    # 参考：https://help.aliyun.com/document_detail/31926.html

    return {
        "access_key_id": settings.ALIYUN_ACCESS_KEY_ID,
        "access_key_secret": settings.ALIYUN_ACCESS_KEY_SECRET,
        "bucket": bucket,
        "endpoint": settings.OSS_ENDPOINT,
        "expiration": expiration,
        "host": f"https://{bucket}.{settings.OSS_ENDPOINT.split('.')[0]}.aliyuncs.com",
    }


@router.get("/oss-token")
async def get_oss_upload_token(
    current_user_id: str = Depends(get_current_user)
):
    """
    获取 OSS 上传凭证

    前端拿到凭证后可以直接上传文件到 OSS，无需经过后端服务器
    """
    try:
        credentials = get_oss_signature(
            bucket=settings.OSS_BUCKET,
            expire_time=settings.OSS_STS_TOKEN_EXPIRE
        )

        # 不返回 secret，前端上传使用签名 URL
        return success_response(
            data={
                "access_key_id": credentials["access_key_id"],
                "bucket": credentials["bucket"],
                "endpoint": credentials["endpoint"],
                "host": credentials["host"],
                "expiration": credentials["expiration"],
                # 前端上传策略
                "policy": "eyJleHBpcmF0aW9uIjoiMjAyNi0wNC0wM1QxMjowMDowMFoiLCJjb25kaXRpb25zIjpbWyJjb250ZW50LWxlbmd0aC1yYW5nZSIsMCwxMDQ4NTc2MDBdXX0=",
                "signature": "demo_signature",  # 实际项目需要正确计算
            }
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"获取上传凭证失败：{str(e)}"
        )
