"""
苏绣 AI 后端 - FastAPI 应用入口
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.config import settings
from app.api.v1 import auth, user, design, order, factory, upload
from app.db.database import init_db


@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用生命周期管理"""
    # 启动时执行
    print(f"[Startup] {settings.APP_NAME} v{settings.APP_VERSION}")
    await init_db()
    print("[Startup] 数据库初始化完成")
    yield
    # 关闭时执行
    print("[Shutdown] 应用关闭")


# 创建 FastAPI 应用
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="苏绣 AI 应用后端 API - 提供 AI 设计生成、订单管理、工厂对接等服务",
    lifespan=lifespan
)

# CORS 中间件
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# 健康检查
@app.get("/health")
async def health_check():
    return {"status": "ok", "version": settings.APP_VERSION}


# 注册路由
app.include_router(auth.router, prefix="/api/v1/auth", tags=["认证"])
app.include_router(user.router, prefix="/api/v1/user", tags=["用户"])
app.include_router(design.router, prefix="/api/v1/design", tags=["设计"])
app.include_router(order.router, prefix="/api/v1/order", tags=["订单"])
app.include_router(factory.router, prefix="/api/v1/factory", tags=["工厂"])
app.include_router(upload.router, prefix="/api/v1/upload", tags=["上传"])


# 根路径
@app.get("/")
async def root():
    return {
        "name": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "docs": "/docs"
    }
